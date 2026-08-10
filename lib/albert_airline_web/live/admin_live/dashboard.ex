defmodule AlbertAirlineWeb.AdminLive.Dashboard do
  use AlbertAirlineWeb, :live_view

  alias AlbertAirline.Flights

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Admin")
     |> assign(:airport_count, Flights.count_airports())
     |> assign(:airline_count, Flights.count_airlines())
     |> assign(:flight_count, Flights.count_flights())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-3xl">
        <h2 class="text-2xl font-bold">Admin</h2>
        <div class="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-3">
          <.link navigate={~p"/admin/airports"} class="albert-card block text-center hover:opacity-90">
            <div class="text-3xl font-bold">{@airport_count}</div>
            <div class="mt-1">Airports</div>
          </.link>
          <.link navigate={~p"/admin/airlines"} class="albert-card block text-center hover:opacity-90">
            <div class="text-3xl font-bold">{@airline_count}</div>
            <div class="mt-1">Airlines</div>
          </.link>
          <.link navigate={~p"/admin/flights"} class="albert-card block text-center hover:opacity-90">
            <div class="text-3xl font-bold">{@flight_count}</div>
            <div class="mt-1">Flights</div>
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
