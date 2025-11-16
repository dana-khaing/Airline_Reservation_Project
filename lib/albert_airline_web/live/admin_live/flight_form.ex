defmodule AlbertAirlineWeb.AdminLive.FlightForm do
  use AlbertAirlineWeb, :live_view

  alias AlbertAirline.Flights
  alias AlbertAirline.Flights.Flight

  @impl true
  def mount(params, _session, socket) do
    flight = load_flight(params)

    {:ok,
     socket
     |> assign(:page_title, if(flight.id, do: "Edit Flight", else: "New Flight"))
     |> assign(:flight, flight)
     |> assign(:airports, Flights.list_airports())
     |> assign(:airlines, Flights.list_airlines())
     |> assign_form(Flights.change_flight(flight))}
  end

  defp load_flight(%{"id" => id}), do: Flights.get_flight!(id)
  defp load_flight(_params), do: %Flight{}

  @impl true
  def handle_event("validate", %{"flight" => params}, socket) do
    changeset = Flights.change_flight(socket.assigns.flight, params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  def handle_event("save", %{"flight" => params}, socket) do
    save_flight(socket, socket.assigns.flight.id, params)
  end

  defp save_flight(socket, nil, params) do
    case Flights.create_flight_with_seats(params) do
      {:ok, _flight} ->
        {:noreply,
         socket
         |> put_flash(:info, "Flight created with a full seat grid.")
         |> push_navigate(to: ~p"/admin/flights")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_flight(socket, _id, params) do
    case Flights.update_flight(socket.assigns.flight, params) do
      {:ok, _flight} ->
        {:noreply,
         socket
         |> put_flash(:info, "Flight updated.")
         |> push_navigate(to: ~p"/admin/flights")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset, as: "flight"))
  end

  defp airport_options(airports) do
    Enum.map(airports, fn a -> {"#{a.iata_code} — #{a.name}", a.id} end)
  end

  defp airline_options(airlines) do
    Enum.map(airlines, fn a -> {a.name, a.id} end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="albert-card mx-auto max-w-lg">
        <h2 class="text-2xl font-bold">{@page_title}</h2>
        <p :if={is_nil(@flight.id)} class="mt-1 text-sm text-black/60">
          Creating a flight generates its full 100-seat grid automatically.
        </p>

        <.form
          for={@form}
          id="flight-form"
          phx-change="validate"
          phx-submit="save"
          class="mt-4 flex flex-col gap-3"
        >
          <.input field={@form[:flight_number]} type="text" label="Flight number" />
          <.input
            field={@form[:airline_id]}
            type="select"
            label="Airline"
            prompt="Select airline"
            options={airline_options(@airlines)}
          />
          <.input
            field={@form[:departure_airport_id]}
            type="select"
            label="Departure airport"
            prompt="Select airport"
            options={airport_options(@airports)}
          />
          <.input
            field={@form[:arrival_airport_id]}
            type="select"
            label="Arrival airport"
            prompt="Select airport"
            options={airport_options(@airports)}
          />
          <.input field={@form[:departure_time]} type="datetime-local" label="Departure time" />
          <.input field={@form[:arrival_time]} type="datetime-local" label="Arrival time" />
          <.input field={@form[:aircraft]} type="text" label="Aircraft" />
          <.input field={@form[:base_price]} type="number" label="Base price (per seat)" step="0.01" />
          <.input field={@form[:stops]} type="number" label="Stops" min="0" />

          <button
            type="submit"
            class="mt-2 rounded-lg bg-[#2a9df1] px-4 py-2 font-semibold text-white"
          >
            Save
          </button>
        </.form>
      </div>
    </Layouts.app>
    """
  end
end
