defmodule AlbertAirlineWeb.FlightLive.ShowTest do
  use AlbertAirlineWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import AlbertAirline.FlightsFixtures

  alias AlbertAirline.Flights

  setup do
    flight = flight_fixture()
    seat = seat_fixture(%{flight_id: flight.id, label: "1A", status: "available"})
    booked_seat = seat_fixture(%{flight_id: flight.id, label: "1B", status: "booked"})

    %{flight: flight, seat: seat, booked_seat: booked_seat}
  end

  test "renders flight details and the seat grid", %{conn: conn, flight: flight, seat: seat} do
    {:ok, _lv, html} = live(conn, ~p"/flights/#{flight.id}")

    assert html =~ flight.flight_number
    assert html =~ seat.label
  end

  test "clicking an available seat selects it and updates the running total", %{
    conn: conn,
    flight: flight,
    seat: seat
  } do
    {:ok, lv, _html} = live(conn, ~p"/flights/#{flight.id}")

    html = lv |> element("button[phx-value-id='#{seat.id}']") |> render_click()

    assert html =~ "Total fee (1 seat) : $#{flight.base_price}"

    # clicking again deselects it
    html = lv |> element("button[phx-value-id='#{seat.id}']") |> render_click()
    assert html =~ "Total fee (0 seats) : $0"
  end

  test "an already-booked seat renders disabled and is not clickable", %{
    conn: conn,
    flight: flight,
    booked_seat: booked_seat
  } do
    {:ok, lv, html} = live(conn, ~p"/flights/#{flight.id}")

    assert button_tag(html, booked_seat.id) =~ "disabled"

    assert_raise ArgumentError, ~r/disabled/, fn ->
      lv |> element("button[phx-value-id='#{booked_seat.id}']") |> render_click()
    end
  end

  test "a seat claimed in one session goes unavailable live in another, with no page reload", %{
    conn: conn,
    flight: flight,
    seat: seat
  } do
    {:ok, viewer_a, _html} = live(conn, ~p"/flights/#{flight.id}")
    {:ok, viewer_b, _html} = live(conn, ~p"/flights/#{flight.id}")

    # viewer_a selects the seat locally
    html_a = viewer_a |> element("button[phx-value-id='#{seat.id}']") |> render_click()
    assert html_a =~ "Total fee (1 seat)"

    # simulate the booking feature claiming the seat (its own transaction will
    # call the same broadcasting update_seat/2 this context function uses)
    {:ok, _updated} = Flights.update_seat(seat, %{status: "booked"})

    # viewer_b, who never selected it, sees it become unselectable live
    html_b = render(viewer_b)
    assert button_tag(html_b, seat.id) =~ "disabled"

    # viewer_a, who had it selected, gets bumped out of their own selection
    html_a_after = render(viewer_a)
    assert html_a_after =~ "Total fee (0 seats)"
    assert html_a_after =~ "just taken and removed from your selection"
  end

  defp button_tag(html, seat_id) do
    [tag] = Regex.run(~r/<button[^>]*phx-value-id="#{seat_id}"[^>]*>/, html)
    tag
  end
end
