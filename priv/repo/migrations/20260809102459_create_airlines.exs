defmodule AlbertAirline.Repo.Migrations.CreateAirlines do
  use Ecto.Migration

  def change do
    create table(:airlines) do
      add :name, :string, null: false
      add :code, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:airlines, [:code])
  end
end
