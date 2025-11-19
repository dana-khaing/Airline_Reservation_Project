defmodule AlbertAirlineWeb.BookingControllerTest do
  use AlbertAirlineWeb.ConnCase, async: true

  test "GET /bookings/cancelled flashes a message and redirects to search", %{conn: conn} do
    conn = get(conn, ~p"/bookings/cancelled")

    assert redirected_to(conn) == ~p"/search"
    assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Checkout cancelled"
  end
end
