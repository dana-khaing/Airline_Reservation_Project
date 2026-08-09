defmodule AlbertAirline.Flights.Airport do
  use Ecto.Schema
  import Ecto.Changeset

  schema "airports" do
    field :iata_code, :string
    field :name, :string
    field :city, :string
    field :country, :string

    has_many :departing_flights, AlbertAirline.Flights.Flight, foreign_key: :departure_airport_id
    has_many :arriving_flights, AlbertAirline.Flights.Flight, foreign_key: :arrival_airport_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(airport, attrs) do
    airport
    |> cast(attrs, [:iata_code, :name, :city, :country])
    |> validate_required([:iata_code, :name, :city, :country])
    |> unique_constraint(:iata_code)
  end
end
