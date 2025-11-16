defmodule AlbertAirlineWeb.AdminLive.FlightManagementTest do
  use AlbertAirlineWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import AlbertAirline.AccountsFixtures
  import AlbertAirline.FlightsFixtures

  alias AlbertAirline.Flights

  setup %{conn: conn} do
    %{conn: log_in_user(conn, admin_user_fixture())}
  end

  test "creating a flight through the UI generates a full seat grid and makes it searchable", %{
    conn: conn
  } do
    airline = airline_fixture()
    lhr = airport_fixture(%{iata_code: "LHR"})
    ygn = airport_fixture(%{iata_code: "YGN"})

    {:ok, lv, _html} = live(conn, ~p"/admin/flights/new")

    {:ok, _lv, html} =
      lv
      |> form("#flight-form", %{
        "flight" => %{
          "flight_number" => "AB-999",
          "airline_id" => airline.id,
          "departure_airport_id" => lhr.id,
          "arrival_airport_id" => ygn.id,
          "departure_time" => "2026-12-01T10:00:00",
          "arrival_time" => "2026-12-01T18:00:00",
          "aircraft" => "Boeing 787",
          "base_price" => "500.00",
          "stops" => "0"
        }
      })
      |> render_submit()
      |> follow_redirect(conn, ~p"/admin/flights")

    assert html =~ "AB-999"

    flight = Flights.get_flight!(Flights.list_flights() |> List.last() |> Map.fetch!(:id))
    assert flight.flight_number == "AB-999"
    assert length(Flights.list_seats_for_flight(flight.id)) == 100

    # this is the plan's stated validation: the new flight is immediately
    # findable by a completely unrelated, unauthenticated searcher
    results = Flights.search_flights(%{departure_airport_id: lhr.id, arrival_airport_id: ygn.id})
    assert Enum.any?(results, &(&1.id == flight.id))
  end

  test "editing a flight does not touch its existing seats", %{conn: conn} do
    flight = flight_fixture(%{flight_number: "OLD-1"})
    seat = seat_fixture(%{flight_id: flight.id, status: "booked"})

    {:ok, lv, _html} = live(conn, ~p"/admin/flights/#{flight.id}/edit")

    {:ok, _lv, html} =
      lv
      |> form("#flight-form", %{"flight" => %{"flight_number" => "NEW-1"}})
      |> render_submit()
      |> follow_redirect(conn, ~p"/admin/flights")

    assert html =~ "NEW-1"
    assert Flights.get_seat!(seat.id).status == "booked"
  end

  test "deleting a flight that has no bookings removes it", %{conn: conn} do
    flight = flight_fixture()
    {:ok, lv, _html} = live(conn, ~p"/admin/flights")

    lv |> element("button[phx-value-id='#{flight.id}']") |> render_click()

    assert_raise Ecto.NoResultsError, fn -> Flights.get_flight!(flight.id) end
  end
end
