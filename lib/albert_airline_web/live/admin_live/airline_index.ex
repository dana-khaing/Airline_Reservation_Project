defmodule AlbertAirlineWeb.AdminLive.AirlineIndex do
  use AlbertAirlineWeb, :live_view

  alias AlbertAirline.Flights

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Airlines")
     |> assign(:airlines, Flights.list_airlines())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    airline = Flights.get_airline!(id)

    socket =
      case Flights.delete_airline(airline) do
        {:ok, _} ->
          assign(socket, :airlines, Flights.list_airlines())

        {:error, _changeset} ->
          put_flash(socket, :error, "Can't delete an airline that has flights.")
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-3xl">
        <div class="flex items-center justify-between">
          <h2 class="text-2xl font-bold">Airlines</h2>
          <.link
            navigate={~p"/admin/airlines/new"}
            class="rounded-lg bg-[#2563eb] px-4 py-2 font-semibold text-white"
          >
            New Airline
          </.link>
        </div>

        <div class="mt-6 albert-card overflow-x-auto">
          <table class="w-full text-left">
            <thead>
              <tr class="border-b border-black/20">
                <th class="pb-2">Code</th>
                <th class="pb-2">Name</th>
                <th class="pb-2"></th>
              </tr>
            </thead>
            <tbody>
              <tr :for={airline <- @airlines} class="border-b border-black/10">
                <td class="py-2">{airline.code}</td>
                <td class="py-2">{airline.name}</td>
                <td class="py-2 text-right">
                  <.link
                    navigate={~p"/admin/airlines/#{airline.id}/edit"}
                    class="text-[#2563eb] hover:underline"
                  >
                    Edit
                  </.link>
                  <button
                    type="button"
                    phx-click="delete"
                    phx-value-id={airline.id}
                    data-confirm="Delete this airline?"
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
