defmodule AlbertAirlineWeb.AdminLive.AirlineForm do
  use AlbertAirlineWeb, :live_view

  alias AlbertAirline.Flights
  alias AlbertAirline.Flights.Airline

  @impl true
  def mount(params, _session, socket) do
    airline = load_airline(params)

    {:ok,
     socket
     |> assign(:page_title, if(airline.id, do: "Edit Airline", else: "New Airline"))
     |> assign(:airline, airline)
     |> assign_form(Flights.change_airline(airline))}
  end

  defp load_airline(%{"id" => id}), do: Flights.get_airline!(id)
  defp load_airline(_params), do: %Airline{}

  @impl true
  def handle_event("validate", %{"airline" => params}, socket) do
    changeset = Flights.change_airline(socket.assigns.airline, params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  def handle_event("save", %{"airline" => params}, socket) do
    save_airline(socket, socket.assigns.airline.id, params)
  end

  defp save_airline(socket, nil, params) do
    case Flights.create_airline(params) do
      {:ok, _airline} ->
        {:noreply,
         socket
         |> put_flash(:info, "Airline created.")
         |> push_navigate(to: ~p"/admin/airlines")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_airline(socket, _id, params) do
    case Flights.update_airline(socket.assigns.airline, params) do
      {:ok, _airline} ->
        {:noreply,
         socket
         |> put_flash(:info, "Airline updated.")
         |> push_navigate(to: ~p"/admin/airlines")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset, as: "airline"))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="albert-card mx-auto max-w-md">
        <h2 class="text-2xl font-bold">{@page_title}</h2>

        <.form
          for={@form}
          id="airline-form"
          phx-change="validate"
          phx-submit="save"
          class="mt-4 flex flex-col gap-3"
        >
          <.input field={@form[:code]} type="text" label="Code" />
          <.input field={@form[:name]} type="text" label="Name" />

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
