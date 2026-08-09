defmodule AlbertAirline.Repo.Migrations.DropUniqueConstraintOnBookingConfirmationCode do
  use Ecto.Migration

  def change do
    # A confirmation_code identifies an *order*, not a single row — a
    # multi-seat booking creates one Booking row per seat, all sharing the
    # same code. It was wrongly made globally unique per-row in the schema
    # feature, before multi-seat orders existed.
    drop unique_index(:bookings, [:confirmation_code])
    create index(:bookings, [:confirmation_code])
  end
end
