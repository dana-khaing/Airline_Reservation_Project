defmodule AlbertAirlineWeb.AdminLive.AirportAndAirlineManagementTest do
  use AlbertAirlineWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import AlbertAirline.AccountsFixtures
  import AlbertAirline.FlightsFixtures

  alias AlbertAirline.Flights

  setup %{conn: conn} do
    %{conn: log_in_user(conn, admin_user_fixture())}
  end

  test "creating an airport through the UI persists it", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/admin/airports/new")

    {:ok, _lv, html} =
      lv
      |> form("#airport-form", %{
        "airport" => %{
          "iata_code" => "XYZ",
          "name" => "Test Airport",
          "city" => "Testville",
          "country" => "Testland"
        }
      })
      |> render_submit()
      |> follow_redirect(conn, ~p"/admin/airports")

    assert html =~ "XYZ"
    assert Enum.any?(Flights.list_airports(), &(&1.iata_code == "XYZ"))
  end

  test "editing an airport through the UI persists the changes", %{conn: conn} do
    airport = airport_fixture(%{name: "Old Name"})

    {:ok, lv, html} = live(conn, ~p"/admin/airports/#{airport.id}/edit")
    assert html =~ "Edit Airport"

    {:ok, _lv, html} =
      lv
      |> form("#airport-form", %{"airport" => %{"name" => "New Name"}})
      |> render_submit()
      |> follow_redirect(conn, ~p"/admin/airports")

    assert html =~ "New Name"
    assert Flights.get_airport!(airport.id).name == "New Name"
  end

  test "an airport with flights cannot be deleted", %{conn: conn} do
    airport = airport_fixture()
    flight_fixture(%{departure_airport_id: airport.id})

    {:ok, lv, _html} = live(conn, ~p"/admin/airports")
    html = lv |> element("button[phx-value-id='#{airport.id}']") |> render_click()

    assert html =~ "Can&#39;t delete"
    assert Flights.get_airport!(airport.id)
  end

  test "creating an airline through the UI persists it", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/admin/airlines/new")

    {:ok, _lv, html} =
      lv
      |> form("#airline-form", %{"airline" => %{"code" => "ZZ", "name" => "Zephyr Air"}})
      |> render_submit()
      |> follow_redirect(conn, ~p"/admin/airlines")

    assert html =~ "Zephyr Air"
    assert Enum.any?(Flights.list_airlines(), &(&1.code == "ZZ"))
  end

  test "editing an airline through the UI persists the changes", %{conn: conn} do
    airline = airline_fixture(%{name: "Old Airline"})

    {:ok, lv, html} = live(conn, ~p"/admin/airlines/#{airline.id}/edit")
    assert html =~ "Edit Airline"

    {:ok, _lv, html} =
      lv
      |> form("#airline-form", %{"airline" => %{"name" => "New Airline"}})
      |> render_submit()
      |> follow_redirect(conn, ~p"/admin/airlines")

    assert html =~ "New Airline"
    assert Flights.get_airline!(airline.id).name == "New Airline"
  end

  test "an airline with flights cannot be deleted", %{conn: conn} do
    airline = airline_fixture()
    flight_fixture(%{airline_id: airline.id})

    {:ok, lv, _html} = live(conn, ~p"/admin/airlines")
    html = lv |> element("button[phx-value-id='#{airline.id}']") |> render_click()

    assert html =~ "Can&#39;t delete"
    assert Flights.get_airline!(airline.id)
  end
end
