defmodule AlbertAirlineWeb.BookingLive.ConfirmationTest do
  use AlbertAirlineWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import AlbertAirline.FlightsFixtures
  import AlbertAirline.AccountsFixtures

  alias AlbertAirline.Bookings

  setup do
    flight = flight_fixture()
    seat = seat_fixture(%{flight_id: flight.id, label: "1A"})
    user = user_fixture()

    %{flight: flight, seat: seat, user: user}
  end

  test "shows itinerary and confirmation code after a successful payment", %{
    conn: conn,
    flight: flight,
    seat: seat,
    user: user
  } do
    {:ok, %{id: session_id}} =
      Bookings.start_checkout(
        user,
        flight,
        [seat.id],
        "https://example.com/ok",
        "https://example.com/cancel"
      )

    {:ok, _lv, html} = live(conn, ~p"/bookings/confirm?session_id=#{session_id}")

    assert html =~ "Booking Confirmed"
    assert html =~ flight.flight_number
    assert html =~ seat.label
  end

  test "shows an apology and does not create a booking after a seat conflict", %{
    conn: conn,
    flight: flight,
    seat: seat,
    user: user
  } do
    {:ok, %{id: winner_session}} =
      Bookings.start_checkout(
        user,
        flight,
        [seat.id],
        "https://example.com/ok",
        "https://example.com/cancel"
      )

    {:ok, %{id: loser_session}} =
      Bookings.start_checkout(
        user_fixture(),
        flight,
        [seat.id],
        "https://example.com/ok",
        "https://example.com/cancel"
      )

    assert {:ok, _} = Bookings.confirm_from_stripe_session(winner_session)

    {:ok, _lv, html} = live(conn, ~p"/bookings/confirm?session_id=#{loser_session}")

    assert html =~ "sorry"
    assert html =~ "refunded"
  end

  test "shows an unknown-session message for a bogus session id", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/bookings/confirm?session_id=cs_test_does_not_exist")

    assert html =~ "Something went wrong"
  end
end
