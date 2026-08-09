defmodule AlbertAirline.Repo.Migrations.CreateFlights do
  use Ecto.Migration

  def change do
    create table(:flights) do
      add :flight_number, :string, null: false
      add :departure_time, :utc_datetime, null: false
      add :arrival_time, :utc_datetime, null: false
      add :aircraft, :string, null: false
      add :base_price, :decimal, null: false
      add :stops, :integer, null: false, default: 0
      add :airline_id, references(:airlines, on_delete: :restrict), null: false
      add :departure_airport_id, references(:airports, on_delete: :restrict), null: false
      add :arrival_airport_id, references(:airports, on_delete: :restrict), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:flights, [:airline_id])
    create index(:flights, [:departure_airport_id])
    create index(:flights, [:arrival_airport_id])
    create index(:flights, [:departure_time])

    create constraint(:flights, :different_departure_and_arrival_airport,
             check: "departure_airport_id != arrival_airport_id"
           )
  end
end
