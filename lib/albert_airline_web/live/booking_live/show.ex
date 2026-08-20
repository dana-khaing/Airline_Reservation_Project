defmodule AlbertAirlineWeb.BookingLive.Show do
  use AlbertAirlineWeb, :live_view

  alias AlbertAirline.Bookings
  alias AlbertAirline.FlightStatus
  alias AlbertAirlineWeb.FlightStatusComponents

  @refresh_interval :timer.seconds(60)

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    booking = Bookings.get_booking_for_user!(id, socket.assigns.current_scope.user.id)

    if connected?(socket) and upcoming?(booking), do: schedule_refresh()

    {:ok,
     socket
     |> assign(:page_title, "Booking #{booking.confirmation_code}")
     |> assign(:booking, booking)
     |> assign_async(:flight_status, fn ->
       {:ok, %{flight_status: FlightStatus.get_status(booking.flight)}}
     end)}
  end

  @impl true
  def handle_info(:refresh_flight_status, socket) do
    schedule_refresh()
    booking = socket.assigns.booking

    {:noreply,
     assign_async(socket, :flight_status, fn ->
       {:ok, %{flight_status: FlightStatus.get_status(booking.flight)}}
     end)}
  end

  # See the identical comment in BookingLive.Confirmation.handle_info/2 —
  # same landmine, same fix: a stray :refresh_flight_status arriving after
  # this process has been reused by another LiveView must not crash it.
  @impl true
  def handle_info(_message, socket), do: {:noreply, socket}

  defp schedule_refresh, do: Process.send_after(self(), :refresh_flight_status, @refresh_interval)

  defp upcoming?(booking),
    do:
      booking.status == "confirmed" and
        DateTime.compare(booking.flight.departure_time, DateTime.utc_now()) == :gt

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-2xl">
        <div class="card">
          <h2 class="text-2xl font-bold">
            {@booking.flight.departure_airport.iata_code} → {@booking.flight.arrival_airport.iata_code}
          </h2>
          <p class="mt-2 text-sm text-(--text-muted)">
            {@booking.flight.airline.name} · Flight {@booking.flight.flight_number} · Seat {@booking.seat.label}
          </p>
          <p class="mt-1 text-sm text-(--text-muted)">
            {Calendar.strftime(@booking.flight.departure_time, "%B %d, %Y %H:%M")}
          </p>
          <p class="mt-1 text-sm text-(--text-muted)">
            Confirmation: <span class="font-mono">{@booking.confirmation_code}</span>
          </p>
        </div>

        <FlightStatusComponents.flight_status status={@flight_status} class="mt-4" />
      </div>
    </Layouts.app>
    """
  end
end
