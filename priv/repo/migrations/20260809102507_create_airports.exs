defmodule AlbertAirline.Repo.Migrations.CreateAirports do
  use Ecto.Migration

  def change do
    create table(:airports) do
      add :iata_code, :string, null: false
      add :name, :string, null: false
      add :city, :string, null: false
      add :country, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:airports, [:iata_code])
  end
end
