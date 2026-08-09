defmodule AlbertAirlineWeb.AccountLive.Bookings do
  use AlbertAirlineWeb, :live_view

  alias AlbertAirline.Bookings

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "My Bookings")
     |> load_bookings()}
  end

  defp load_bookings(socket) do
    user_id = socket.assigns.current_scope.user.id
    bookings = Bookings.list_bookings_for_user(user_id)
    now = DateTime.utc_now()

    {upcoming, past} =
      Enum.split_with(bookings, fn b ->
        b.status == "confirmed" and DateTime.compare(b.flight.departure_time, now) == :gt
      end)

    socket
    |> assign(:upcoming, upcoming)
    |> assign(:past, past)
  end

  @impl true
  def handle_event("cancel", %{"id" => id}, socket) do
    booking = Enum.find(socket.assigns.upcoming, &(&1.id == String.to_integer(id)))

    socket =
      case booking && Bookings.cancel_booking(booking) do
        {:ok, _booking} ->
          socket
          |> put_flash(:info, "Booking cancelled — the seat is available again.")
          |> load_bookings()

        _ ->
          put_flash(socket, :error, "Could not cancel that booking.")
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-3xl">
        <h2 class="text-2xl font-bold">My Bookings</h2>

        <h3 class="mt-6 text-xl font-semibold">Upcoming</h3>
        <p :if={@upcoming == []} class="albert-card mt-2">No upcoming bookings.</p>
        <div class="mt-2 flex flex-col gap-3">
          <.booking_card :for={booking <- @upcoming} booking={booking} cancellable={true} />
        </div>

        <h3 class="mt-8 text-xl font-semibold">Past &amp; Cancelled</h3>
        <p :if={@past == []} class="albert-card mt-2">Nothing here yet.</p>
        <div class="mt-2 flex flex-col gap-3">
          <.booking_card :for={booking <- @past} booking={booking} cancellable={false} />
        </div>
      </div>
    </Layouts.app>
    """
  end

  attr :booking, :map, required: true
  attr :cancellable, :boolean, required: true

  defp booking_card(assigns) do
    ~H"""
    <div class="albert-card flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <div class="font-semibold">
          {@booking.flight.departure_airport.iata_code} → {@booking.flight.arrival_airport.iata_code}
          <span class="ml-2 text-sm font-normal text-black/60">({status_label(@booking.status)})</span>
        </div>
        <div class="text-sm text-black/70">
          {@booking.flight.airline.name} · Flight {@booking.flight.flight_number} · Seat {@booking.seat.label}
        </div>
        <div class="text-sm text-black/70">
          {Calendar.strftime(@booking.flight.departure_time, "%B %d, %Y %H:%M")}
        </div>
        <div class="text-sm text-black/70">
          Confirmation: <span class="font-mono">{@booking.confirmation_code}</span>
        </div>
      </div>
      <button
        :if={@cancellable}
        type="button"
        phx-click="cancel"
        phx-value-id={@booking.id}
        data-confirm="Cancel this booking? The seat will be released."
        class="self-start rounded-lg bg-red-600 px-4 py-2 text-sm font-semibold text-white hover:opacity-90 sm:self-center"
      >
        Cancel
      </button>
    </div>
    """
  end

  defp status_label("confirmed"), do: "Confirmed"
  defp status_label("cancelled"), do: "Cancelled"
end
