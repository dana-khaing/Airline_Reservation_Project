defmodule AlbertAirline.Repo.Migrations.AddStripePaymentIntentIdToBookings do
  use Ecto.Migration

  def change do
    alter table(:bookings) do
      # Nullable: older/seed-script bookings never went through Stripe and
      # have nothing to refund against. Needed so cancel_booking/1 can issue
      # a real refund instead of just freeing the seat.
      add :stripe_payment_intent_id, :string
    end
  end
end
