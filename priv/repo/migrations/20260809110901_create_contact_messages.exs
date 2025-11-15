defmodule AlbertAirline.Repo.Migrations.CreateContactMessages do
  use Ecto.Migration

  def change do
    create table(:contact_messages) do
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :company_name, :string
      add :email, :string, null: false
      add :user_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:contact_messages, [:user_id])
  end
end
