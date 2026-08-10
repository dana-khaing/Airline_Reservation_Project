defmodule AlbertAirlineWeb.FlightLive.Search do
  use AlbertAirlineWeb, :live_view

  alias AlbertAirline.Flights
  alias AlbertAirlineWeb.FlightLive.Helpers

  @stop_categories [
    {"direct", "Direct"},
    {"one_stop", "1 Stop"},
    {"two_plus", "2 and more Stops"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    airports = Flights.list_airports()

    {:ok,
     socket
     |> assign(:page_title, "Flight Search")
     |> assign(:airports, airports)
     |> assign(:airlines, Flights.list_airlines())
     |> assign(:stop_categories, @stop_categories)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    criteria = %{
      departure_airport_id: params["departure_airport_id"],
      arrival_airport_id: params["arrival_airport_id"],
      date: params["date"],
      seats: params["seats"],
      stops: List.wrap(params["stops"]),
      airline_ids: List.wrap(params["airline_ids"])
    }

    flights = Flights.search_flights(criteria)

    {:noreply,
     socket
     |> assign(:criteria, criteria)
     |> assign(:flights, flights)
     |> assign(:seat_counts, seat_counts_by_flight(flights))}
  end

  @impl true
  def handle_event("filter", params, socket) do
    query =
      %{
        "departure_airport_id" => params["departure_airport_id"],
        "arrival_airport_id" => params["arrival_airport_id"],
        "date" => params["date"],
        "seats" => params["seats"],
        "stops" => Map.get(params, "stops", []),
        "airline_ids" => Map.get(params, "airline_ids", [])
      }
      |> Enum.reject(fn {_k, v} -> v in [nil, ""] end)
      |> Enum.into(%{})

    {:noreply, push_patch(socket, to: ~p"/search?#{query}")}
  end

  defp seat_counts_by_flight(flights) do
    Map.new(flights, fn flight -> {flight.id, Flights.available_seat_count(flight.id)} end)
  end

  defp airport_options(airports) do
    Enum.map(airports, fn a -> {"#{a.iata_code} — #{a.name}", a.id} end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-5xl">
        <h2 class="mb-4 text-2xl font-bold">Flight Search</h2>
        <div class="albert-card mb-6">
          <form id="search-form" phx-change="filter">
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5 lg:items-end">
              <.input
                type="select"
                name="departure_airport_id"
                label="Flying From"
                prompt="Departure Terminal"
                value={@criteria.departure_airport_id}
                options={airport_options(@airports)}
              />
              <.input
                type="select"
                name="arrival_airport_id"
                label="Flying To"
                prompt="Arrival Terminal"
                value={@criteria.arrival_airport_id}
                options={airport_options(@airports)}
              />
              <.input
                type="date"
                name="date"
                label="Departure Date"
                value={@criteria.date}
              />
              <.input
                type="number"
                name="seats"
                label="Number of seats"
                min="1"
                max="10"
                placeholder="1"
                value={@criteria.seats}
              />
              <button
                type="submit"
                class="btn rounded-lg bg-[#2563eb] px-6 py-2 font-semibold text-white"
              >
                Search Your Flight
              </button>
            </div>

            <div class="mt-6 grid grid-cols-1 gap-6 sm:grid-cols-2">
              <div>
                <h4 class="font-semibold">Transits</h4>
                <div class="mt-2 flex flex-col gap-1">
                  <label :for={{value, label} <- @stop_categories} class="flex items-center gap-2">
                    <input
                      type="checkbox"
                      name="stops[]"
                      value={value}
                      checked={value in @criteria.stops}
                    /> {label}
                  </label>
                </div>
              </div>

              <div>
                <h4 class="font-semibold">Airlines</h4>
                <div class="mt-2 flex flex-col gap-1">
                  <label :for={airline <- @airlines} class="flex items-center gap-2">
                    <input
                      type="checkbox"
                      name="airline_ids[]"
                      value={airline.id}
                      checked={to_string(airline.id) in @criteria.airline_ids}
                    /> {airline.name}
                  </label>
                </div>
              </div>
            </div>
          </form>
        </div>

        <div :if={@flights == []} class="albert-card text-center">
          No flights match your search. Try different filters.
        </div>

        <div class="flex flex-col gap-4">
          <.link
            :for={flight <- @flights}
            navigate={~p"/flights/#{flight.id}"}
            class="albert-card flex flex-col gap-2 hover:opacity-90 sm:flex-row sm:items-center sm:justify-between"
          >
            <div>
              <div class="font-semibold">
                {Calendar.strftime(flight.departure_time, "%H:%M")} ({flight.departure_airport.iata_code}) - {Calendar.strftime(
                  flight.arrival_time,
                  "%H:%M"
                )} ({flight.arrival_airport.iata_code})
              </div>
              <div class="text-sm text-black/70">
                {Helpers.stops_label(flight.stops)} · {flight.airline.name} · {@seat_counts[flight.id]} seats left
              </div>
            </div>
            <div class="text-lg font-bold">${flight.base_price}</div>
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
