defmodule AlbertAirline.Contact.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contact_messages" do
    field :first_name, :string
    field :last_name, :string
    field :company_name, :string
    field :email, :string

    belongs_to :user, AlbertAirline.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:first_name, :last_name, :company_name, :email, :user_id])
    |> validate_required([:first_name, :last_name, :email])
    |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
      message: "must have the @ sign and no spaces"
    )
    |> validate_length(:first_name, max: 160)
    |> validate_length(:last_name, max: 160)
    |> validate_length(:company_name, max: 160)
    |> validate_length(:email, max: 160)
    |> foreign_key_constraint(:user_id)
  end
end
