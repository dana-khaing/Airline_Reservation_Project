defmodule AlbertAirline.Repo.Migrations.CreateBookings do
  use Ecto.Migration

  def change do
    create table(:bookings) do
      add :status, :string, null: false, default: "confirmed"
      add :total_price, :decimal, null: false
      add :confirmation_code, :string, null: false
      add :booked_at, :utc_datetime, null: false
      add :seat_id, references(:seats, on_delete: :restrict), null: false
      add :flight_id, references(:flights, on_delete: :restrict), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:bookings, [:confirmation_code])
    create index(:bookings, [:flight_id])

    # A seat can have at most one *active* booking at a time — this is the
    # database-level guarantee against double-booking a seat, on top of the
    # app-level transaction in the booking feature. Cancelled bookings don't
    # count, so a cancelled seat can be rebooked.
    create unique_index(:bookings, [:seat_id],
             where: "status != 'cancelled'",
             name: :bookings_active_seat_id_index
           )
  end
end
