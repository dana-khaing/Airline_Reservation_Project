defmodule AlbertAirlineWeb.AdminLive.FlightIndex do
  use AlbertAirlineWeb, :live_view

  alias AlbertAirline.Flights
  alias AlbertAirline.Repo

  @impl true
  def mount(_params, _session, socket) do
    flights =
      Flights.list_flights() |> Repo.preload([:airline, :departure_airport, :arrival_airport])

    {:ok,
     socket
     |> assign(:page_title, "Flights")
     |> assign(:flights, flights)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    flight = Flights.get_flight!(id)

    socket =
      case Flights.delete_flight(flight) do
        {:ok, _} ->
          flights =
            Flights.list_flights()
            |> Repo.preload([:airline, :departure_airport, :arrival_airport])

          assign(socket, :flights, flights)

        {:error, _changeset} ->
          put_flash(socket, :error, "Can't delete a flight that has bookings.")
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-4xl">
        <div class="flex items-center justify-between">
          <h2 class="text-2xl font-bold">Flights</h2>
          <.link
            navigate={~p"/admin/flights/new"}
            class="rounded-lg bg-[#2563eb] px-4 py-2 font-semibold text-white"
          >
            New Flight
          </.link>
        </div>

        <div class="mt-6 albert-card overflow-x-auto">
          <table class="w-full text-left">
            <thead>
              <tr class="border-b border-black/20">
                <th class="pb-2">Flight</th>
                <th class="pb-2">Route</th>
                <th class="pb-2">Departs</th>
                <th class="pb-2">Airline</th>
                <th class="pb-2">Price</th>
                <th class="pb-2"></th>
              </tr>
            </thead>
            <tbody>
              <tr :for={flight <- @flights} class="border-b border-black/10">
                <td class="py-2">{flight.flight_number}</td>
                <td class="py-2">
                  {flight.departure_airport.iata_code} → {flight.arrival_airport.iata_code}
                </td>
                <td class="py-2">{Calendar.strftime(flight.departure_time, "%Y-%m-%d %H:%M")}</td>
                <td class="py-2">{flight.airline.name}</td>
                <td class="py-2">${flight.base_price}</td>
                <td class="py-2 text-right">
                  <.link
                    navigate={~p"/admin/flights/#{flight.id}/edit"}
                    class="text-[#2563eb] hover:underline"
                  >
                    Edit
                  </.link>
                  <button
                    type="button"
                    phx-click="delete"
                    phx-value-id={flight.id}
                    data-confirm="Delete this flight?"
                    class="ml-3 text-red-600 hover:underline"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
