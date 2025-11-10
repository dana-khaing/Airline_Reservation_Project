defmodule AlbertAirline.Repo.Migrations.CreateSeats do
  use Ecto.Migration

  def change do
    create table(:seats) do
      add :label, :string, null: false
      add :seat_class, :string, null: false
      add :status, :string, null: false, default: "available"
      add :flight_id, references(:flights, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:seats, [:flight_id])
    create unique_index(:seats, [:flight_id, :label])
  end
end
