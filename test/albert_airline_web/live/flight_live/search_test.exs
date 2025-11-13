defmodule AlbertAirlineWeb.FlightLive.SearchTest do
  use AlbertAirlineWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import AlbertAirline.FlightsFixtures

  setup do
    albert = airline_fixture(%{name: "Albert Airline", code: "A8"})
    lhr = airport_fixture(%{iata_code: "LHR"})
    ygn = airport_fixture(%{iata_code: "YGN"})

    flight =
      flight_fixture(%{
        airline_id: albert.id,
        departure_airport_id: lhr.id,
        arrival_airport_id: ygn.id,
        departure_time: ~U[2026-09-01 10:00:00Z],
        arrival_time: ~U[2026-09-01 18:00:00Z],
        stops: 0
      })

    unrelated_airport = airport_fixture()

    %{flight: flight, lhr: lhr, ygn: ygn, unrelated_airport: unrelated_airport}
  end

  test "renders every flight with no filters applied", %{conn: conn, lhr: lhr} do
    {:ok, _lv, html} = live(conn, ~p"/search")

    assert html =~ lhr.iata_code
  end

  test "filtering live-updates the results without a page reload", %{
    conn: conn,
    flight: flight,
    unrelated_airport: unrelated_airport
  } do
    {:ok, lv, html} = live(conn, ~p"/search")

    assert html =~ "$#{flight.base_price}"

    html =
      lv
      |> form("form#search-form", %{"departure_airport_id" => unrelated_airport.id})
      |> render_change()

    refute html =~ "$#{flight.base_price}"
  end

  test "shows an empty state when nothing matches", %{
    conn: conn,
    unrelated_airport: unrelated_airport
  } do
    {:ok, lv, _html} = live(conn, ~p"/search")

    html =
      lv
      |> form("form#search-form", %{"departure_airport_id" => unrelated_airport.id})
      |> render_change()

    assert html =~ "No flights match"
  end
end
