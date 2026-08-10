defmodule AlbertAirline.BookingsCheckoutTest do
  use AlbertAirline.DataCase, async: true

  import Swoosh.TestAssertions

  alias AlbertAirline.Bookings
  alias AlbertAirline.Flights

  import AlbertAirline.FlightsFixtures
  import AlbertAirline.AccountsFixtures

  setup do
    flight = flight_fixture()
    seat_a = seat_fixture(%{flight_id: flight.id, label: "1A"})
    seat_b = seat_fixture(%{flight_id: flight.id, label: "1B"})
    user = user_fixture()

    # user_fixture/1 sends an account-confirmation email as a side effect —
    # drop it so it can't be mistaken for a booking-confirmation email below.
    flush_emails()

    %{flight: flight, seat_a: seat_a, seat_b: seat_b, user: user}
  end

  describe "start_checkout/5" do
    test "creates a checkout session without touching the database", %{
      flight: flight,
      seat_a: seat_a,
      user: user
    } do
      assert {:ok, %{id: session_id, url: url}} =
               Bookings.start_checkout(
                 user,
                 flight,
                 [seat_a.id],
                 "https://example.com/ok",
                 "https://example.com/cancel"
               )

      assert is_binary(session_id)
      assert url =~ session_id

      # nothing was reserved just by starting checkout
      assert Bookings.list_bookings() == []
      assert Flights.get_seat!(seat_a.id).status == "available"
    end
  end

  describe "confirm_from_stripe_session/1" do
    test "claims every seat and marks them booked, once payment is confirmed paid", %{
      flight: flight,
      seat_a: seat_a,
      seat_b: seat_b,
      user: user
    } do
      {:ok, %{id: session_id}} =
        Bookings.start_checkout(
          user,
          flight,
          [seat_a.id, seat_b.id],
          "https://example.com/ok",
          "https://example.com/cancel"
        )

      assert {:ok, bookings} = Bookings.confirm_from_stripe_session(session_id)
      assert length(bookings) == 2
      assert Enum.all?(bookings, &(&1.status == "confirmed"))
      assert Enum.all?(bookings, &(&1.user_id == user.id))

      # stored so a later cancellation can actually refund this payment
      assert Enum.all?(bookings, &(&1.stripe_payment_intent_id != nil))
      assert Enum.uniq(Enum.map(bookings, & &1.stripe_payment_intent_id)) |> length() == 1

      assert Flights.get_seat!(seat_a.id).status == "booked"
      assert Flights.get_seat!(seat_b.id).status == "booked"

      assert_email_sent(subject: "Your booking is confirmed — #{hd(bookings).confirmation_code}")
    end

    test "is idempotent — confirming the same session twice doesn't double-book, error, or re-send the confirmation email",
         %{
           flight: flight,
           seat_a: seat_a,
           user: user
         } do
      {:ok, %{id: session_id}} =
        Bookings.start_checkout(
          user,
          flight,
          [seat_a.id],
          "https://example.com/ok",
          "https://example.com/cancel"
        )

      assert {:ok, [booking]} = Bookings.confirm_from_stripe_session(session_id)
      assert {:ok, [^booking]} = Bookings.confirm_from_stripe_session(session_id)

      assert length(Bookings.list_bookings_by_confirmation_code(booking.confirmation_code)) == 1

      subject = "Your booking is confirmed — #{booking.confirmation_code}"
      assert_email_sent(subject: subject)
      refute_email_sent(subject: ^subject)
    end

    test "refunds and reports a conflict if a seat was claimed by someone else during checkout",
         %{
           flight: flight,
           seat_a: seat_a,
           user: user
         } do
      {:ok, %{id: session_id}} =
        Bookings.start_checkout(
          user,
          flight,
          [seat_a.id],
          "https://example.com/ok",
          "https://example.com/cancel"
        )

      # someone else's checkout confirms first, claiming the seat
      other_user = user_fixture()

      {:ok, %{id: other_session_id}} =
        Bookings.start_checkout(
          other_user,
          flight,
          [seat_a.id],
          "https://example.com/ok",
          "https://example.com/cancel"
        )

      assert {:ok, [_other_booking]} = Bookings.confirm_from_stripe_session(other_session_id)

      assert {:error, :seat_conflict} = Bookings.confirm_from_stripe_session(session_id)

      # the loser's checkout was refunded, not left dangling
      {:ok, %{metadata: %{"confirmation_code" => losing_code}}} =
        AlbertAirline.Payments.retrieve_checkout_session(session_id)

      assert Bookings.list_bookings_by_confirmation_code(losing_code) == []
      assert Flights.get_seat!(seat_a.id).status == "booked"
    end

    test "does not create bookings for an unpaid/abandoned session", %{
      flight: flight,
      seat_a: seat_a,
      user: user
    } do
      # simulate an unpaid session directly via the stub's underlying create call
      {:ok, %{id: unpaid_session_id}} =
        AlbertAirline.Payments.create_checkout_session(%{
          amount: flight.base_price,
          description: "test",
          success_url: "https://example.com/ok",
          cancel_url: "https://example.com/cancel",
          metadata: %{
            "confirmation_code" => "UNPAIDTEST",
            "flight_id" => to_string(flight.id),
            "user_id" => to_string(user.id),
            "seat_ids" => to_string(seat_a.id),
            "simulate_unpaid" => "true"
          }
        })

      assert {:error, :payment_not_completed} =
               Bookings.confirm_from_stripe_session(unpaid_session_id)

      assert Bookings.list_bookings_by_confirmation_code("UNPAIDTEST") == []
      assert Flights.get_seat!(seat_a.id).status == "available"
    end
  end
end
