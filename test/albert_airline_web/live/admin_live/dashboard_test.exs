defmodule AlbertAirlineWeb.AdminLive.DashboardTest do
  use AlbertAirlineWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import AlbertAirline.AccountsFixtures
  import AlbertAirline.FlightsFixtures

  setup %{conn: conn} do
    %{conn: log_in_user(conn, admin_user_fixture())}
  end

  test "shows the actual counts of airports, airlines, and flights", %{conn: conn} do
    # flight_fixture/1 creates its own airline + 2 airports when none are
    # given, so pin every id explicitly to keep the expected counts exact.
    airline = airline_fixture()
    departure = airport_fixture()
    arrival = airport_fixture()

    flight_fixture(%{
      airline_id: airline.id,
      departure_airport_id: departure.id,
      arrival_airport_id: arrival.id
    })

    {:ok, _lv, html} = live(conn, ~p"/admin")

    assert html =~ ~r/text-3xl font-bold">2<\/div><div[^>]*class="mt-1">Airports/
    assert html =~ ~r/text-3xl font-bold">1<\/div><div[^>]*class="mt-1">Airlines/
    assert html =~ ~r/text-3xl font-bold">1<\/div><div[^>]*class="mt-1">Flights/
  end
end
