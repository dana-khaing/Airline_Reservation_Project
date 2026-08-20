defmodule AlbertAirlineWeb.FlightLive.Show do
  use AlbertAirlineWeb, :live_view

  alias AlbertAirline.Bookings
  alias AlbertAirline.Flights
  alias AlbertAirlineWeb.FlightLive.Helpers

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    flight =
      Flights.get_flight!(id)
      |> AlbertAirline.Repo.preload([:airline, :departure_airport, :arrival_airport])

    if connected?(socket), do: Flights.subscribe_to_seats(flight.id)

    {:ok,
     socket
     |> assign(
       :page_title,
       "#{flight.departure_airport.iata_code} to #{flight.arrival_airport.iata_code}"
     )
     |> assign(:flight, flight)
     |> assign(:seats, Flights.list_seats_for_flight(flight.id))
     |> assign(:selected_seat_ids, MapSet.new())}
  end

  @impl true
  def handle_event("toggle_seat", %{"id" => id_string}, socket) do
    id = String.to_integer(id_string)
    seat = Enum.find(socket.assigns.seats, &(&1.id == id))

    socket =
      cond do
        is_nil(seat) ->
          socket

        seat.status != "available" and not MapSet.member?(socket.assigns.selected_seat_ids, id) ->
          put_flash(socket, :error, "That seat is no longer available.")

        MapSet.member?(socket.assigns.selected_seat_ids, id) ->
          update(socket, :selected_seat_ids, &MapSet.delete(&1, id))

        true ->
          update(socket, :selected_seat_ids, &MapSet.put(&1, id))
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("book", _params, socket) do
    seat_ids = MapSet.to_list(socket.assigns.selected_seat_ids)

    case {socket.assigns.current_scope, seat_ids} do
      {%{user: %{} = user}, seat_ids} when seat_ids != [] ->
        success_url = url(~p"/bookings/confirm") <> "?session_id={CHECKOUT_SESSION_ID}"
        cancel_url = url(~p"/bookings/cancelled")

        case Bookings.start_checkout(
               user,
               socket.assigns.flight,
               seat_ids,
               success_url,
               cancel_url
             ) do
          {:ok, %{url: checkout_url}} ->
            {:noreply, redirect(socket, external: checkout_url)}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, "Could not start checkout. Please try again.")}
        end

      {nil, seat_ids} when seat_ids != [] ->
        {:noreply,
         socket
         |> put_flash(:error, "Please log in to book a flight.")
         |> redirect(to: ~p"/users/log-in")}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:seat_updated, updated_seat}, socket) do
    seats =
      Enum.map(socket.assigns.seats, fn seat ->
        if seat.id == updated_seat.id, do: updated_seat, else: seat
      end)

    socket =
      socket
      |> assign(:seats, seats)
      |> maybe_drop_now_unavailable_seat(updated_seat)

    {:noreply, socket}
  end

  # LiveView reuses one BEAM process across `navigate`-linked views in the
  # same live_session, so if a stray seat-broadcast arrives after this
  # process has since been replaced by another LiveView, an unmatched
  # handle_info/2 clause would crash that process with a
  # FunctionClauseError. This catch-all keeps any such stray message a
  # harmless no-op.
  @impl true
  def handle_info(_message, socket), do: {:noreply, socket}

  defp maybe_drop_now_unavailable_seat(socket, %{status: "available"}), do: socket

  defp maybe_drop_now_unavailable_seat(socket, updated_seat) do
    if MapSet.member?(socket.assigns.selected_seat_ids, updated_seat.id) do
      socket
      |> update(:selected_seat_ids, &MapSet.delete(&1, updated_seat.id))
      |> put_flash(
        :error,
        "Seat #{updated_seat.label} was just taken and removed from your selection."
      )
    else
      socket
    end
  end

  defp total_price(flight, selected_seat_ids) do
    Decimal.mult(flight.base_price, Decimal.new(MapSet.size(selected_seat_ids)))
  end

  defp seat_rows(seats), do: Enum.chunk_by(seats, &row_number(&1.label))

  defp row_number(label) do
    case Regex.run(~r/^(\d+)/, label) do
      [_, digits] -> String.to_integer(digits)
      _ -> 0
    end
  end

  defp seat_class(seat, selected_seat_ids) do
    cond do
      MapSet.member?(selected_seat_ids, seat.id) ->
        "border-brand-600 bg-brand-600 text-white"

      seat.status != "available" ->
        "cursor-not-allowed border-(--border-default) bg-(--surface-sunken) text-(--text-muted) line-through"

      true ->
        "border-(--border-default) bg-(--surface) text-(--text-default) hover:bg-brand-50 dark:hover:bg-brand-950"
    end
  end

  defp seat_status_label(seat, selected_seat_ids) do
    cond do
      MapSet.member?(selected_seat_ids, seat.id) -> "selected"
      seat.status != "available" -> "unavailable"
      true -> "available"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="card mx-auto max-w-3xl">
        <h2 class="text-2xl font-bold">
          {Calendar.strftime(@flight.departure_time, "%H:%M")} - {Calendar.strftime(
            @flight.arrival_time,
            "%H:%M"
          )} ({Helpers.stops_label(@flight.stops)})
        </h2>
        <h3 class="mt-2 text-xl">
          {@flight.departure_airport.iata_code} ------&gt; {@flight.arrival_airport.iata_code}
        </h3>

        <p class="mt-4">
          From {@flight.departure_airport.name} ({Calendar.strftime(@flight.departure_time, "%H:%M")})<br />
          Flight Number - {@flight.flight_number}<br />{@flight.airline.name}<br />
          {@flight.aircraft}
        </p>
        <p class="mt-4">
          To {@flight.arrival_airport.name} ({Calendar.strftime(@flight.arrival_time, "%H:%M")})<br />
          Flight Number - {@flight.flight_number}<br />{@flight.airline.name}<br />
          {@flight.aircraft}
        </p>

        <h4 class="mt-6 font-semibold">Choose the seat for the trip :</h4>
        <p class="mt-1 text-sm text-(--text-muted)">
          Available seats are white, selected seats are blue, unavailable seats are struck through and gray.
        </p>
        <div class="mt-3 overflow-x-auto">
          <div
            role="group"
            aria-label="Seat map"
            class="flex w-fit flex-col items-center gap-1 mx-auto"
          >
            <div :for={row <- seat_rows(@seats)} class="flex gap-1">
              <button
                :for={seat <- row}
                type="button"
                phx-click="toggle_seat"
                phx-value-id={seat.id}
                aria-pressed={to_string(MapSet.member?(@selected_seat_ids, seat.id))}
                aria-label={"Seat #{seat.label}, #{seat.seat_class}, #{seat_status_label(seat, @selected_seat_ids)}"}
                disabled={
                  seat.status != "available" and not MapSet.member?(@selected_seat_ids, seat.id)
                }
                class={[
                  "h-8 w-10 shrink-0 rounded border text-xs font-semibold",
                  seat_class(seat, @selected_seat_ids)
                ]}
              >
                {seat.label}
              </button>
            </div>
          </div>
        </div>

        <h4 class="mt-6 font-semibold">Bags</h4>
        <p>&#10003; Carry-on bags included *</p>
        <p>&#10003; 1st check bag included *</p>
        <h4 class="mt-4 font-semibold">Refundable</h4>
        <p>&#10003; Less any non-refundable fee</p>
        <p>&#10003; No change fee</p>

        <h4 class="mt-6 font-semibold">
          Total fee ({MapSet.size(@selected_seat_ids)} seat{if MapSet.size(@selected_seat_ids) != 1,
            do: "s"}) : ${total_price(
            @flight,
            @selected_seat_ids
          )}
        </h4>
        <div class="mt-4">
          <.button
            type="button"
            phx-click="book"
            disabled={MapSet.size(@selected_seat_ids) == 0}
            variant="primary"
            class="px-6 py-3"
          >
            Book the flight
          </.button>
          <p
            :if={is_nil(@current_scope) and MapSet.size(@selected_seat_ids) > 0}
            class="mt-2 text-sm text-(--text-muted)"
          >
            You'll be asked to log in before payment.
          </p>
        </div>
        <p class="mt-2 text-sm text-(--text-muted)">
          ** Baggage fees reflect the airline's standard fees based on the selected fare class. **
        </p>
      </div>
    </Layouts.app>
    """
  end
end
