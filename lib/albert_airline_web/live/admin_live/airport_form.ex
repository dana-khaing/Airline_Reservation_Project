defmodule AlbertAirlineWeb.AdminLive.AirportForm do
  use AlbertAirlineWeb, :live_view

  alias AlbertAirline.Flights
  alias AlbertAirline.Flights.Airport

  @impl true
  def mount(params, _session, socket) do
    airport = load_airport(params)

    {:ok,
     socket
     |> assign(:page_title, if(airport.id, do: "Edit Airport", else: "New Airport"))
     |> assign(:airport, airport)
     |> assign_form(Flights.change_airport(airport))}
  end

  defp load_airport(%{"id" => id}), do: Flights.get_airport!(id)
  defp load_airport(_params), do: %Airport{}

  @impl true
  def handle_event("validate", %{"airport" => params}, socket) do
    changeset = Flights.change_airport(socket.assigns.airport, params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  def handle_event("save", %{"airport" => params}, socket) do
    save_airport(socket, socket.assigns.airport.id, params)
  end

  defp save_airport(socket, nil, params) do
    case Flights.create_airport(params) do
      {:ok, _airport} ->
        {:noreply,
         socket
         |> put_flash(:info, "Airport created.")
         |> push_navigate(to: ~p"/admin/airports")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_airport(socket, _id, params) do
    case Flights.update_airport(socket.assigns.airport, params) do
      {:ok, _airport} ->
        {:noreply,
         socket
         |> put_flash(:info, "Airport updated.")
         |> push_navigate(to: ~p"/admin/airports")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset, as: "airport"))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="albert-card mx-auto max-w-md">
        <h2 class="text-2xl font-bold">{@page_title}</h2>

        <.form
          for={@form}
          id="airport-form"
          phx-change="validate"
          phx-submit="save"
          class="mt-4 flex flex-col gap-3"
        >
          <.input field={@form[:iata_code]} type="text" label="IATA code" />
          <.input field={@form[:name]} type="text" label="Name" />
          <.input field={@form[:city]} type="text" label="City" />
          <.input field={@form[:country]} type="text" label="Country" />

          <button
            type="submit"
            class="mt-2 rounded-lg bg-[#2563eb] px-4 py-2 font-semibold text-white"
          >
            Save
          </button>
        </.form>
      </div>
    </Layouts.app>
    """
  end
end
