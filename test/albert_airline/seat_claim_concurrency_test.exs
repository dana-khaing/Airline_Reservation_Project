defmodule AlbertAirline.SeatClaimConcurrencyTest do
  @moduledoc """
  Every other test of the seat-claiming transaction (see
  BookingsCheckoutTest) calls confirm_from_stripe_session/1 sequentially,
  in the same process — that proves the DB constraint rejects a second
  insert, but not that the system is safe when multiple requests actually
  race at the same instant, which is the real-world failure mode this
  stack was chosen to handle.

  This test disables the Ecto sandbox's rollback-only transaction wrapping
  (Sandbox.checkout(..., sandbox: false)) so spawned Tasks get genuine,
  independent database transactions instead of nested savepoints inside
  one shared transaction — otherwise Postgres would just serialize
  everything through a single connection/transaction and there would be
  no real race to observe. Because this leaves committed rows behind
  (it can't roll back), it cleans up explicitly instead of relying on the
  sandbox.
  """

  use ExUnit.Case, async: false

  import Ecto.Query
  import AlbertAirline.FlightsFixtures
  import AlbertAirline.AccountsFixtures

  alias AlbertAirline.{Accounts, Bookings, Flights, Repo}
  alias AlbertAirline.Bookings.Booking

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Repo, sandbox: false)
    :ok
  end

  test "exactly one of many truly concurrent checkouts for the same seat succeeds" do
    flight = flight_fixture()
    seat = seat_fixture(%{flight_id: flight.id})
    concurrency = 8

    {airline_id, dep_id, arr_id} =
      {flight.airline_id, flight.departure_airport_id, flight.arrival_airport_id}

    users = for _ <- 1..concurrency, do: user_fixture()

    # registered up front, before any assertion can fail, so cleanup always
    # runs — this test commits real rows outside the rollback sandbox
    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.checkout(Repo, sandbox: false)
      Repo.delete_all(from(b in Booking, where: b.flight_id == ^flight.id))
      Repo.delete_all(from(s in Flights.Seat, where: s.flight_id == ^flight.id))
      Repo.delete_all(from(f in Flights.Flight, where: f.id == ^flight.id))
      Repo.delete_all(from(a in Flights.Airport, where: a.id in [^dep_id, ^arr_id]))
      Repo.delete_all(from(a in Flights.Airline, where: a.id == ^airline_id))
      Repo.delete_all(from(u in Accounts.User, where: u.id in ^Enum.map(users, & &1.id)))
    end)

    session_ids =
      for user <- users do
        {:ok, %{id: session_id}} =
          Bookings.start_checkout(
            user,
            flight,
            [seat.id],
            "https://example.com/ok",
            "https://example.com/cancel"
          )

        session_id
      end

    results =
      session_ids
      |> Task.async_stream(&Bookings.confirm_from_stripe_session/1,
        max_concurrency: concurrency,
        timeout: 15_000
      )
      |> Enum.map(fn {:ok, result} -> result end)

    successes = Enum.count(results, &match?({:ok, _}, &1))
    conflicts = Enum.count(results, &match?({:error, :seat_conflict}, &1))

    assert successes == 1
    assert conflicts == concurrency - 1

    # the DB, not just the in-memory results, agrees: exactly one row
    bookings_for_seat = Repo.all(from(b in Booking, where: b.seat_id == ^seat.id))
    assert length(bookings_for_seat) == 1
    assert Flights.get_seat!(seat.id).status == "booked"
  end
end
