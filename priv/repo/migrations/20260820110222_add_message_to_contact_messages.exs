defmodule AlbertAirline.Repo.Migrations.AddMessageToContactMessages do
  use Ecto.Migration

  def change do
    alter table(:contact_messages) do
      add :message, :text, null: false, default: ""
    end
  end
end
