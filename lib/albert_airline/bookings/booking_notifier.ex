defmodule AlbertAirline.Bookings.BookingNotifier do
  alias AlbertAirline.Mailer

  defp deliver(recipient, subject, body) do
    Mailer.deliver_text_email(
      {"Albert Airline", "bookings@example.com"},
      recipient,
      subject,
      body
    )
  end

  @doc """
  Sends one confirmation email covering every seat in an order (all
  bookings sharing a confirmation_code), once — right after they're
  created. Not called on idempotent re-confirmation of an
  already-existing order, so refreshing the confirmation page never
  re-sends this.
  """
  def deliver_booking_confirmation(user, flight, bookings) do
    [first | _] = bookings
    seat_labels = bookings |> Enum.map(& &1.seat.label) |> Enum.sort() |> Enum.join(", ")

    total =
      Enum.reduce(bookings, Decimal.new(0), &Decimal.add(&1.total_price, &2))

    deliver(
      user.email,
      "Your booking is confirmed — #{first.confirmation_code}",
      """

      ==============================

      Hi #{user.email},

      Your booking is confirmed.

      Confirmation code: #{first.confirmation_code}
      Flight: #{flight.flight_number}
      From: #{flight.departure_airport.iata_code} at #{format_time(flight.departure_time)}
      To: #{flight.arrival_airport.iata_code} at #{format_time(flight.arrival_time)}
      Seat(s): #{seat_labels}
      Total paid: $#{total}

      You can view or cancel this booking any time from My Bookings.

      ==============================
      """
    )
  end

  @doc """
  Sends a cancellation notice for a single booking, including the
  refund amount when the booking had a payment on file.
  """
  def deliver_booking_cancellation(booking) do
    refund_line =
      if booking.stripe_payment_intent_id do
        "Refund: $#{booking.total_price} back to your original payment method."
      else
        "No payment was on file for this booking, so no refund was issued."
      end

    deliver(
      booking.user.email,
      "Booking cancelled — #{booking.confirmation_code}",
      """

      ==============================

      Hi #{booking.user.email},

      Your booking has been cancelled and your seat has been released.

      Confirmation code: #{booking.confirmation_code}
      Flight: #{booking.flight.flight_number}
      Seat: #{booking.seat.label}
      #{refund_line}

      ==============================
      """
    )
  end

  defp format_time(datetime), do: Calendar.strftime(datetime, "%B %d, %Y %H:%M UTC")
end
