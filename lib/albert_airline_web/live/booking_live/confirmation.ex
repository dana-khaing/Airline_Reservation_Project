defmodule AlbertAirlineWeb.BookingLive.Confirmation do
  use AlbertAirlineWeb, :live_view

  alias AlbertAirline.Bookings
  alias AlbertAirline.FlightStatus
  alias AlbertAirline.Repo
  alias AlbertAirlineWeb.FlightStatusComponents

  @refresh_interval :timer.seconds(60)

  @impl true
  def mount(%{"session_id" => session_id}, _session, socket) do
    socket =
      case Bookings.confirm_from_stripe_session(session_id) do
        {:ok, bookings} ->
          bookings =
            Repo.preload(bookings, [
              :seat,
              flight: [:airline, :departure_airport, :arrival_airport]
            ])

          [first | _] = bookings
          if connected?(socket), do: schedule_refresh()

          socket
          |> assign(status: :confirmed, bookings: bookings)
          |> assign_async(:flight_status, fn ->
            {:ok, %{flight_status: FlightStatus.get_status(first.flight)}}
          end)

        {:error, :seat_conflict} ->
          assign(socket, status: :seat_conflict)

        {:error, :payment_not_completed} ->
          assign(socket, status: :payment_incomplete)

        {:error, _other} ->
          assign(socket, status: :error)
      end

    {:ok, assign(socket, :page_title, "Booking Confirmation")}
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, status: :error, page_title: "Booking Confirmation")}
  end

  @impl true
  def handle_info(:refresh_flight_status, socket) do
    schedule_refresh()
    [first | _] = socket.assigns.bookings

    {:noreply,
     assign_async(socket, :flight_status, fn ->
       {:ok, %{flight_status: FlightStatus.get_status(first.flight)}}
     end)}
  end

  defp schedule_refresh, do: Process.send_after(self(), :refresh_flight_status, @refresh_interval)

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="albert-card mx-auto max-w-2xl text-center">
        <.confirmed
          :if={@status == :confirmed}
          bookings={@bookings}
          flight_status={@flight_status}
        />

        <div :if={@status == :seat_conflict}>
          <h2 class="text-2xl font-bold">We're sorry</h2>
          <p class="mt-3">
            One of your selected seats was booked by someone else while you were
            checking out. Your payment has been refunded in full — no charge will
            appear on your card. Please search again and pick another seat.
          </p>
          <.link
            navigate={~p"/search"}
            class="mt-4 inline-block rounded-lg bg-[#2563eb] px-4 py-2 font-semibold text-white"
          >
            Back to search
          </.link>
        </div>

        <div :if={@status == :payment_incomplete}>
          <h2 class="text-2xl font-bold">Payment not completed</h2>
          <p class="mt-3">We couldn't confirm your payment, so no booking was made.</p>
        </div>

        <div :if={@status == :error}>
          <h2 class="text-2xl font-bold">Something went wrong</h2>
          <p class="mt-3">We couldn't find that checkout session.</p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  attr :bookings, :list, required: true
  attr :flight_status, Phoenix.LiveView.AsyncResult, required: true

  defp confirmed(assigns) do
    [first | _] = assigns.bookings
    assigns = assign(assigns, flight: first.flight, first: first)

    ~H"""
    <h2 class="text-2xl font-bold">Booking Confirmed!</h2>
    <p class="mt-2 text-lg">
      Confirmation code: <span class="font-mono font-bold">{@first.confirmation_code}</span>
    </p>

    <div class="mt-6 text-left">
      <p>
        <strong>{@flight.departure_airport.iata_code} → {@flight.arrival_airport.iata_code}</strong><br />
        {@flight.airline.name} · Flight {@flight.flight_number}<br />
        {Calendar.strftime(@flight.departure_time, "%B %d, %Y %H:%M")} - {Calendar.strftime(
          @flight.arrival_time,
          "%H:%M"
        )}
      </p>

      <p class="mt-4">
        Seats: <strong>{@bookings |> Enum.map(& &1.seat.label) |> Enum.join(", ")}</strong>
      </p>

      <p class="mt-4 text-lg font-bold">
        Total paid: ${Enum.reduce(@bookings, Decimal.new(0), &Decimal.add(&1.total_price, &2))}
      </p>

      <FlightStatusComponents.flight_status status={@flight_status} class="mt-6" />
    </div>
    """
  end
end
