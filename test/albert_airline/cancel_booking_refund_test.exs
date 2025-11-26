defmodule AlbertAirline.CancelBookingRefundTest do
  @moduledoc """
  cancel_booking/1 didn't refund anything until this feature — it only
  marked the booking cancelled and freed the seat. These tests cover the
  actual refund behavior added on top of that, using
  AlbertAirline.Payments.StubClient.refunds/0 to assert on what was
  refunded without hitting the real Stripe API.

  Tests filter the shared stub's refund log by payment_intent_id (unique
  per test via System.unique_integer) rather than asserting on the whole
  list, since that Agent's state is shared across concurrently-running
  async tests.
  """

  use AlbertAirline.DataCase, async: true

  import AlbertAirline.FlightsFixtures
  import AlbertAirline.BookingsFixtures

  alias AlbertAirline.Bookings
  alias AlbertAirline.Payments.StubClient

  test "cancelling a booking with a stripe_payment_intent_id refunds its price" do
    payment_intent_id = "pi_test_#{System.unique_integer([:positive])}"

    booking =
      booking_fixture(%{
        total_price: "150.00",
        stripe_payment_intent_id: payment_intent_id
      })

    assert {:ok, cancelled} = Bookings.cancel_booking(booking)
    assert cancelled.status == "cancelled"

    refunds = Enum.filter(StubClient.refunds(), &(&1.payment_intent_id == payment_intent_id))
    assert [%{amount: amount}] = refunds
    assert Decimal.equal?(amount, Decimal.new("150.00"))
  end

  test "cancelling one seat out of a multi-seat order only refunds that seat's price" do
    flight = flight_fixture()
    payment_intent_id = "pi_test_#{System.unique_integer([:positive])}"

    seat_a = seat_fixture(%{flight_id: flight.id, label: "1A"})
    seat_b = seat_fixture(%{flight_id: flight.id, label: "1B"})

    confirmation_code = "GRP#{System.unique_integer([:positive])}"

    booking_a =
      booking_fixture(%{
        flight_id: flight.id,
        seat_id: seat_a.id,
        total_price: "100.00",
        confirmation_code: confirmation_code,
        stripe_payment_intent_id: payment_intent_id
      })

    _booking_b =
      booking_fixture(%{
        flight_id: flight.id,
        seat_id: seat_b.id,
        total_price: "100.00",
        confirmation_code: confirmation_code,
        stripe_payment_intent_id: payment_intent_id
      })

    assert {:ok, _cancelled} = Bookings.cancel_booking(booking_a)

    refunds = Enum.filter(StubClient.refunds(), &(&1.payment_intent_id == payment_intent_id))
    assert [%{amount: amount}] = refunds
    assert Decimal.equal?(amount, Decimal.new("100.00"))
  end

  test "cancelling a booking with no stripe_payment_intent_id skips the refund without error" do
    booking = booking_fixture(%{total_price: "75.00", stripe_payment_intent_id: nil})

    assert {:ok, cancelled} = Bookings.cancel_booking(booking)
    assert cancelled.status == "cancelled"

    # nil payment_intent_id can never appear in a refund log entry, so
    # asserting none exists for it proves no refund was attempted — without
    # touching the shared stub's list of every other concurrently-running
    # test's refunds.
    assert Enum.filter(StubClient.refunds(), &(&1.payment_intent_id == nil)) == []
  end

  test "cancelling an already-cancelled booking is a no-op, not a second refund" do
    payment_intent_id = "pi_test_#{System.unique_integer([:positive])}"

    booking =
      booking_fixture(%{
        total_price: "200.00",
        stripe_payment_intent_id: payment_intent_id
      })

    assert {:ok, cancelled} = Bookings.cancel_booking(booking)
    assert {:error, :already_cancelled} = Bookings.cancel_booking(cancelled)

    refunds = Enum.filter(StubClient.refunds(), &(&1.payment_intent_id == payment_intent_id))
    assert length(refunds) == 1
  end

  test "a refund failure does not prevent the booking from being cancelled" do
    booking =
      booking_fixture(%{
        total_price: "50.00",
        stripe_payment_intent_id: "pi_test_simulate_refund_failure"
      })

    assert {:ok, cancelled} = Bookings.cancel_booking(booking)
    assert cancelled.status == "cancelled"
  end
end
