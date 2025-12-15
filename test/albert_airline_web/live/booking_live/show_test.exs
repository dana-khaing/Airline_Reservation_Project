defmodule AlbertAirlineWeb.BookingLive.ShowTest do
  use AlbertAirlineWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import AlbertAirline.AccountsFixtures
  import AlbertAirline.BookingsFixtures

  test "an owner can view their booking, with the flight-status panel resolving async", %{
    conn: conn
  } do
    user = user_fixture()
    conn = log_in_user(conn, user)
    booking = booking_fixture(%{user_id: user.id})

    {:ok, lv, _html} = live(conn, ~p"/bookings/#{booking.id}")

    html = render_async(lv)
    assert html =~ booking.confirmation_code
    # This fixture's flight number won't match the stub adapter's one
    # canned "live" flight, so the panel should show the graceful fallback.
    assert html =~ "Live tracking unavailable for this flight"
  end

  test "a booking id belonging to a different user 404s", %{conn: conn} do
    owner = user_fixture()
    other_user = user_fixture()
    booking = booking_fixture(%{user_id: owner.id})

    conn = log_in_user(conn, other_user)

    assert_error_sent 404, fn ->
      live(conn, ~p"/bookings/#{booking.id}")
    end
  end

  test "a logged-out visitor is redirected to log in", %{conn: conn} do
    booking = booking_fixture()

    assert {:error, {:redirect, %{to: "/users/log-in"}}} =
             live(conn, ~p"/bookings/#{booking.id}")
  end
end
