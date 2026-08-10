defmodule AlbertAirline.BookingsEmailFailureTest do
  @moduledoc """
  Covers the {:error, reason} branch of Bookings' email-delivery failure
  handling (send_confirmation_email/3, send_cancellation_email/1) — every
  other test in the suite runs against Swoosh.Adapters.Test, which always
  succeeds, so this path had no coverage until now.

  Runs async: false and swaps the mailer to AlbertAirline.FailingMailerAdapter
  only right before the action under test (never during fixture setup,
  which sends its own account-confirmation email and would break if that
  failed) — this mutates global application config other concurrently
  running async tests could be affected by.
  """

  use AlbertAirline.DataCase, async: false

  import ExUnit.CaptureLog

  alias AlbertAirline.Bookings

  import AlbertAirline.FlightsFixtures
  import AlbertAirline.AccountsFixtures
  import AlbertAirline.BookingsFixtures

  defp use_failing_mailer do
    original = Application.get_env(:albert_airline, AlbertAirline.Mailer)

    Application.put_env(:albert_airline, AlbertAirline.Mailer,
      adapter: AlbertAirline.FailingMailerAdapter
    )

    on_exit(fn -> Application.put_env(:albert_airline, AlbertAirline.Mailer, original) end)
  end

  test "a booking confirmation email failure is logged, and the booking still succeeds" do
    flight = flight_fixture()
    seat = seat_fixture(%{flight_id: flight.id})
    user = user_fixture()

    {:ok, %{id: session_id}} =
      Bookings.start_checkout(
        user,
        flight,
        [seat.id],
        "https://example.com/ok",
        "https://example.com/cancel"
      )

    use_failing_mailer()

    log =
      capture_log(fn ->
        assert {:ok, [_booking]} = Bookings.confirm_from_stripe_session(session_id)
      end)

    assert log =~ "Failed to send email (booking confirmation for user #{user.id})"
  end

  test "a cancellation email failure is logged, and the cancellation still succeeds" do
    booking = booking_fixture(%{total_price: "50.00", stripe_payment_intent_id: nil})

    use_failing_mailer()

    log =
      capture_log(fn ->
        assert {:ok, cancelled} = Bookings.cancel_booking(booking)
        assert cancelled.status == "cancelled"
      end)

    assert log =~ "Failed to send email (cancellation for booking #{booking.id})"
  end
end
