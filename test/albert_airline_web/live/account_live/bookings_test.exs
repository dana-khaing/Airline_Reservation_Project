defmodule AlbertAirlineWeb.AccountLive.BookingsTest do
  use AlbertAirlineWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import AlbertAirline.AccountsFixtures
  import AlbertAirline.FlightsFixtures
  import AlbertAirline.BookingsFixtures

  alias AlbertAirline.Flights

  test "redirects to login when logged out", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, ~p"/account")
  end

  test "lists a user's own bookings split into upcoming and past/cancelled", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)

    upcoming_flight = future_flight_fixture(7)
    upcoming_seat = seat_fixture(%{flight_id: upcoming_flight.id, label: "1A"})

    upcoming_booking =
      booking_fixture(%{
        user_id: user.id,
        flight_id: upcoming_flight.id,
        seat_id: upcoming_seat.id,
        status: "confirmed"
      })

    past_flight = past_flight_fixture(7)
    past_seat = seat_fixture(%{flight_id: past_flight.id, label: "2B"})

    past_booking =
      booking_fixture(%{
        user_id: user.id,
        flight_id: past_flight.id,
        seat_id: past_seat.id,
        status: "confirmed"
      })

    # someone else's booking must never show up here
    booking_fixture()

    {:ok, _lv, html} = live(conn, ~p"/account")

    assert html =~ upcoming_booking.confirmation_code
    assert html =~ past_booking.confirmation_code

    upcoming_index = :binary.match(html, upcoming_booking.confirmation_code) |> elem(0)
    past_index = :binary.match(html, past_booking.confirmation_code) |> elem(0)
    upcoming_heading = :binary.match(html, "Upcoming") |> elem(0)
    past_heading = :binary.match(html, "Past &amp; Cancelled") |> elem(0)

    assert upcoming_heading < upcoming_index
    assert past_heading < past_index
  end

  test "cancelling an upcoming booking frees the seat, live, without a reload", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)

    flight = future_flight_fixture(7)
    seat = seat_fixture(%{flight_id: flight.id, label: "1A", status: "booked"})

    booking =
      booking_fixture(%{
        user_id: user.id,
        flight_id: flight.id,
        seat_id: seat.id,
        status: "confirmed"
      })

    # a second viewer watching this flight's seat map
    seat_conn = build_conn()
    {:ok, seat_lv, _html} = live(seat_conn, ~p"/flights/#{flight.id}")

    {:ok, lv, _html} = live(conn, ~p"/account")

    html = lv |> element("button[phx-value-id='#{booking.id}']") |> render_click()

    assert html =~ "cancelled"
    assert html =~ "Cancelled"
    assert Flights.get_seat!(seat.id).status == "available"

    # the seat map viewer sees it live, no page reload
    seat_html = render(seat_lv)
    refute seat_html =~ ~r/phx-value-id="#{seat.id}"[^>]*disabled/
  end

  test "cannot cancel someone else's booking", %{conn: conn} do
    owner = user_fixture()
    intruder = user_fixture()

    flight = future_flight_fixture(7)
    seat = seat_fixture(%{flight_id: flight.id, status: "booked"})
    booking = booking_fixture(%{user_id: owner.id, flight_id: flight.id, seat_id: seat.id})

    conn = log_in_user(conn, intruder)
    {:ok, lv, html} = live(conn, ~p"/account")

    # the intruder's own account page has no such booking to click on
    refute html =~ booking.confirmation_code
    refute has_element?(lv, "button[phx-value-id='#{booking.id}']")
  end

  defp future_flight_fixture(days_from_now) do
    departure = DateTime.add(DateTime.utc_now(), days_from_now, :day)
    flight_fixture(%{departure_time: departure, arrival_time: DateTime.add(departure, 8, :hour)})
  end

  defp past_flight_fixture(days_ago) do
    departure = DateTime.add(DateTime.utc_now(), -days_ago, :day)
    flight_fixture(%{departure_time: departure, arrival_time: DateTime.add(departure, 8, :hour)})
  end
end
