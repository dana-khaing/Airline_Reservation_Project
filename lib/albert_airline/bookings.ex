defmodule AlbertAirline.Bookings do
  @moduledoc """
  The Bookings context.
  """

  import Ecto.Query, warn: false
  alias AlbertAirline.Flights
  alias AlbertAirline.Payments
  alias AlbertAirline.Repo

  alias AlbertAirline.Bookings.Booking

  @doc """
  Returns the list of bookings.

  ## Examples

      iex> list_bookings()
      [%Booking{}, ...]

  """
  def list_bookings do
    Repo.all(Booking)
  end

  @doc """
  Gets a single booking.

  Raises `Ecto.NoResultsError` if the Booking does not exist.

  ## Examples

      iex> get_booking!(123)
      %Booking{}

      iex> get_booking!(456)
      ** (Ecto.NoResultsError)

  """
  def get_booking!(id), do: Repo.get!(Booking, id)

  @doc """
  Creates a booking.

  ## Examples

      iex> create_booking(%{field: value})
      {:ok, %Booking{}}

      iex> create_booking(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_booking(attrs) do
    %Booking{}
    |> Booking.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a booking.

  ## Examples

      iex> update_booking(booking, %{field: new_value})
      {:ok, %Booking{}}

      iex> update_booking(booking, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_booking(%Booking{} = booking, attrs) do
    booking
    |> Booking.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a booking.

  ## Examples

      iex> delete_booking(booking)
      {:ok, %Booking{}}

      iex> delete_booking(booking)
      {:error, %Ecto.Changeset{}}

  """
  def delete_booking(%Booking{} = booking) do
    Repo.delete(booking)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking booking changes.

  ## Examples

      iex> change_booking(booking)
      %Ecto.Changeset{data: %Booking{}}

  """
  def change_booking(%Booking{} = booking, attrs \\ %{}) do
    Booking.changeset(booking, attrs)
  end

  @doc """
  Returns every booking sharing a confirmation code (one order can cover
  multiple seats, one Booking row per seat).
  """
  def list_bookings_by_confirmation_code(code) do
    Repo.all(from(b in Booking, where: b.confirmation_code == ^code))
  end

  @doc """
  Starts a Stripe checkout for the given seats on a flight. No Booking rows
  are created yet — deliberately, per this project's "atomic check-at-
  booking-time, no pre-hold" design: nothing is reserved just because
  someone opened checkout. Seats are only actually claimed once payment is
  confirmed, in `confirm_from_stripe_session/1`.
  """
  def start_checkout(user, flight, seat_ids, success_url, cancel_url) when seat_ids != [] do
    flight = Repo.preload(flight, [:departure_airport, :arrival_airport])
    confirmation_code = generate_confirmation_code()
    total_amount = Decimal.mult(flight.base_price, Decimal.new(length(seat_ids)))

    Payments.create_checkout_session(%{
      amount: total_amount,
      description:
        "#{flight.flight_number}: #{flight.departure_airport.iata_code} to #{flight.arrival_airport.iata_code} (#{length(seat_ids)} seat(s))",
      success_url: success_url,
      cancel_url: cancel_url,
      metadata: %{
        "confirmation_code" => confirmation_code,
        "flight_id" => to_string(flight.id),
        "user_id" => to_string(user.id),
        "seat_ids" => Enum.join(seat_ids, ",")
      }
    })
  end

  @doc """
  Confirms a completed Stripe checkout: verifies payment, then atomically
  claims every seat in the order (one Booking insert per seat, in a single
  transaction guarded by the partial unique index on bookings.seat_id).

  If any seat was claimed by someone else in the meantime — the real
  concurrency case this design accepts, since there's no pre-hold — the
  whole transaction rolls back and the payment that just succeeded is
  refunded automatically. Idempotent: re-confirming an already-confirmed
  session just returns the existing bookings instead of trying (and
  failing) to insert them again.
  """
  def confirm_from_stripe_session(session_id) do
    with {:ok, session} <- Payments.retrieve_checkout_session(session_id) do
      confirmation_code = session.metadata["confirmation_code"]

      case list_bookings_by_confirmation_code(confirmation_code) do
        [] -> do_confirm(session, confirmation_code)
        existing -> {:ok, existing}
      end
    end
  end

  defp do_confirm(%{payment_status: "paid"} = session, confirmation_code) do
    %{"flight_id" => flight_id_str, "user_id" => user_id_str, "seat_ids" => seat_ids_str} =
      session.metadata

    flight_id = String.to_integer(flight_id_str)
    user_id = String.to_integer(user_id_str)
    seat_ids = seat_ids_str |> String.split(",") |> Enum.map(&String.to_integer/1)

    flight = Flights.get_flight!(flight_id)
    seats = Enum.map(seat_ids, &Flights.get_seat!/1)
    now = DateTime.utc_now(:second)

    multi =
      Enum.reduce(seats, Ecto.Multi.new(), fn seat, multi ->
        multi
        |> Ecto.Multi.insert(
          {:booking, seat.id},
          Booking.changeset(%Booking{}, %{
            seat_id: seat.id,
            flight_id: flight_id,
            user_id: user_id,
            status: "confirmed",
            total_price: flight.base_price,
            confirmation_code: confirmation_code,
            booked_at: now
          })
        )
        |> Ecto.Multi.update({:seat, seat.id}, Flights.change_seat(seat, %{status: "booked"}))
      end)

    case Repo.transaction(multi) do
      {:ok, results} ->
        Enum.each(seat_ids, fn id -> Flights.broadcast_seat_updated(results[{:seat, id}]) end)
        {:ok, Enum.map(seat_ids, &results[{:booking, &1}])}

      {:error, _failed_op, _reason, _changes} ->
        if session.payment_intent, do: Payments.refund(session.payment_intent)
        {:error, :seat_conflict}
    end
  end

  defp do_confirm(_session, _confirmation_code), do: {:error, :payment_not_completed}

  defp generate_confirmation_code do
    :crypto.strong_rand_bytes(6) |> Base.encode32(case: :upper, padding: false)
  end

  @doc """
  Returns a user's bookings (any status), soonest-departing flight first,
  with seat/flight/airline/airport data preloaded for display.
  """
  def list_bookings_for_user(user_id) do
    Repo.all(
      from(b in Booking,
        where: b.user_id == ^user_id,
        join: f in assoc(b, :flight),
        order_by: [asc: f.departure_time],
        preload: [:seat, flight: [:airline, :departure_airport, :arrival_airport]]
      )
    )
  end

  @doc """
  Cancels a booking: marks it cancelled and frees its seat back to
  available, atomically, in one transaction. The seat's PubSub broadcast
  fires only after the transaction commits, same as booking confirmation —
  so anyone watching that flight's seat map sees it open up live.
  """
  def cancel_booking(%Booking{} = booking) do
    booking = Repo.preload(booking, :seat)

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.update(:booking, Booking.changeset(booking, %{status: "cancelled"}))
      |> Ecto.Multi.update(:seat, Flights.change_seat(booking.seat, %{status: "available"}))

    case Repo.transaction(multi) do
      {:ok, %{booking: booking, seat: seat}} ->
        Flights.broadcast_seat_updated(seat)
        {:ok, booking}

      {:error, _failed_op, changeset, _changes} ->
        {:error, changeset}
    end
  end
end
