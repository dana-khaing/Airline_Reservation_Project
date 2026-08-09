defmodule AlbertAirline.Repo.Migrations.AddUserIdToBookings do
  use Ecto.Migration

  def change do
    alter table(:bookings) do
      add :user_id, references(:users, on_delete: :restrict), null: false
    end

    create index(:bookings, [:user_id])
  end
end
