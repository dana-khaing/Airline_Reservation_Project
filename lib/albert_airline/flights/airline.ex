defmodule AlbertAirline.Flights.Airline do
  use Ecto.Schema
  import Ecto.Changeset

  schema "airlines" do
    field :name, :string
    field :code, :string

    has_many :flights, AlbertAirline.Flights.Flight

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(airline, attrs) do
    airline
    |> cast(attrs, [:name, :code])
    |> validate_required([:name, :code])
    |> unique_constraint(:code)
  end
end
