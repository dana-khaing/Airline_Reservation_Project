defmodule AlbertAirlineWeb.FlightLive.Show do
  use AlbertAirlineWeb, :live_view

  alias AlbertAirline.Flights

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    flight =
      Flights.get_flight!(id)
      |> AlbertAirline.Repo.preload([:airline, :departure_airport, :arrival_airport])

    {:ok,
     socket
     |> assign(
       :page_title,
       "#{flight.departure_airport.iata_code} to #{flight.arrival_airport.iata_code}"
     )
     |> assign(:flight, flight)
     |> assign(:available_seats, Flights.available_seat_count(flight.id))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="albert-card mx-auto max-w-3xl">
        <h2 class="text-2xl font-bold">
          {Calendar.strftime(@flight.departure_time, "%H:%M")} - {Calendar.strftime(
            @flight.arrival_time,
            "%H:%M"
          )} ({stops_label(@flight.stops)})
        </h2>
        <h3 class="mt-2 text-xl">
          {@flight.departure_airport.iata_code} ------&gt; {@flight.arrival_airport.iata_code}
        </h3>

        <p class="mt-4">
          From {@flight.departure_airport.name} ({Calendar.strftime(@flight.departure_time, "%H:%M")})<br />
          Flight Number - {@flight.flight_number}<br />{@flight.airline.name}<br />
          {@flight.aircraft}
        </p>
        <p class="mt-4">
          To {@flight.arrival_airport.name} ({Calendar.strftime(@flight.arrival_time, "%H:%M")})<br />
          Flight Number - {@flight.flight_number}<br />{@flight.airline.name}<br />
          {@flight.aircraft}
        </p>

        <h4 class="mt-6 font-semibold">Seats</h4>
        <p class="mt-1">
          {@available_seats} seats available. Seat selection is coming in the next feature.
        </p>

        <h4 class="mt-6 font-semibold">Total fee</h4>
        <p class="mt-1 text-lg font-bold">${@flight.base_price}</p>
      </div>
    </Layouts.app>
    """
  end

  defp stops_label(0), do: "Direct"
  defp stops_label(1), do: "1 Connection"
  defp stops_label(n), do: "#{n} Connections"
end
