defmodule AlbertAirlineWeb.GoldenPathTest do
  @moduledoc """
  One continuous walk through the whole booking loop — search, open a
  flight, select a seat, check out, land on the confirmation page, and see
  the booking in account history — as a single user would experience it.
  Each step already has focused unit/LiveView coverage elsewhere; this
  proves the pieces actually fit together end to end.
  """

  use AlbertAirlineWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import AlbertAirline.AccountsFixtures
  import AlbertAirline.FlightsFixtures

  test "search -> select seat -> checkout -> confirmation -> account history", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)

    albert = airline_fixture(%{name: "Albert Airline"})
    lhr = airport_fixture(%{iata_code: "LHR"})
    ygn = airport_fixture(%{iata_code: "YGN"})

    flight =
      flight_fixture(%{
        flight_number: "AB-777",
        airline_id: albert.id,
        departure_airport_id: lhr.id,
        arrival_airport_id: ygn.id,
        departure_time: DateTime.add(DateTime.utc_now(), 10, :day),
        arrival_time: DateTime.add(DateTime.utc_now(), 10, :day) |> DateTime.add(8, :hour),
        stops: 0
      })

    seat = seat_fixture(%{flight_id: flight.id, label: "1A"})

    # 1. search finds it
    {:ok, search_lv, search_html} = live(conn, ~p"/search")
    assert search_html =~ "$#{flight.base_price}"

    search_html =
      search_lv
      |> form("form#search-form", %{
        "departure_airport_id" => lhr.id,
        "arrival_airport_id" => ygn.id
      })
      |> render_change()

    assert search_html =~ "LHR"
    assert search_html =~ "$#{flight.base_price}"

    # 2. open the flight and select the seat
    {:ok, flight_lv, _html} = live(conn, ~p"/flights/#{flight.id}")
    html = flight_lv |> element("button[phx-value-id='#{seat.id}']") |> render_click()
    assert html =~ "Total fee (1 seat) : $#{flight.base_price}"

    # 3. book -> redirected to the (stubbed) Stripe checkout URL
    assert {:error, {:redirect, %{to: checkout_url}}} =
             flight_lv |> element("button", "Book the flight") |> render_click()

    assert checkout_url =~ "https://stripe.test/checkout/"
    session_id = checkout_url |> String.split("/") |> List.last()

    # 4. land back on the confirmation page, as Stripe's success_url would send us
    {:ok, _confirm_lv, confirm_html} = live(conn, ~p"/bookings/confirm?session_id=#{session_id}")
    assert confirm_html =~ "Booking Confirmed"
    assert confirm_html =~ "AB-777"
    assert confirm_html =~ seat.label

    # 5. the seat is now unavailable to a completely different visitor
    other_conn = build_conn()
    {:ok, _other_lv, other_html} = live(other_conn, ~p"/flights/#{flight.id}")
    assert other_html =~ "disabled"

    # 6. and the booking shows up in the buyer's own history
    {:ok, account_lv, account_html} = live(conn, ~p"/account")
    assert account_html =~ "AB-777"
    assert account_html =~ seat.label

    # 7. clicking through to the persistent booking-detail page also works
    # (a live_redirect, since it's a <.link navigate=...>, not a phx-click)
    assert {:ok, _detail_lv, detail_html} =
             account_lv
             |> element("a", "Track flight status")
             |> render_click()
             |> follow_redirect(conn)

    assert detail_html =~ "AB-777"
  end
end
