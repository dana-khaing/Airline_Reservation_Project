defmodule AlbertAirlineWeb.AdminLive.AirportIndex do
  use AlbertAirlineWeb, :live_view

  alias AlbertAirline.Flights

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Airports")
     |> assign(:airports, Flights.list_airports())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    airport = Flights.get_airport!(id)

    socket =
      case Flights.delete_airport(airport) do
        {:ok, _} ->
          assign(socket, :airports, Flights.list_airports())

        {:error, _changeset} ->
          put_flash(socket, :error, "Can't delete an airport that has flights.")
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-3xl">
        <div class="flex items-center justify-between">
          <h2 class="text-2xl font-bold">Airports</h2>
          <.link
            navigate={~p"/admin/airports/new"}
            class="rounded-lg bg-[#2a9df1] px-4 py-2 font-semibold text-white"
          >
            New Airport
          </.link>
        </div>

        <table class="mt-6 w-full albert-card text-left">
          <thead>
            <tr class="border-b border-black/20">
              <th class="pb-2">IATA</th>
              <th class="pb-2">Name</th>
              <th class="pb-2">City</th>
              <th class="pb-2">Country</th>
              <th class="pb-2"></th>
            </tr>
          </thead>
          <tbody>
            <tr :for={airport <- @airports} class="border-b border-black/10">
              <td class="py-2">{airport.iata_code}</td>
              <td class="py-2">{airport.name}</td>
              <td class="py-2">{airport.city}</td>
              <td class="py-2">{airport.country}</td>
              <td class="py-2 text-right">
                <.link
                  navigate={~p"/admin/airports/#{airport.id}/edit"}
                  class="text-[#2a9df1] hover:underline"
                >
                  Edit
                </.link>
                <button
                  type="button"
                  phx-click="delete"
                  phx-value-id={airport.id}
                  data-confirm="Delete this airport?"
                  class="ml-3 text-red-600 hover:underline"
                >
                  Delete
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </Layouts.app>
    """
  end
end
