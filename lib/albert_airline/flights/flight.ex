defmodule AlbertAirline.Flights.Flight do
  use Ecto.Schema
  import Ecto.Changeset

  schema "flights" do
    field :flight_number, :string
    field :departure_time, :utc_datetime
    field :arrival_time, :utc_datetime
    field :aircraft, :string
    field :base_price, :decimal
    field :stops, :integer, default: 0

    belongs_to :airline, AlbertAirline.Flights.Airline
    belongs_to :departure_airport, AlbertAirline.Flights.Airport
    belongs_to :arrival_airport, AlbertAirline.Flights.Airport

    has_many :seats, AlbertAirline.Flights.Seat
    has_many :bookings, AlbertAirline.Bookings.Booking

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(flight, attrs) do
    flight
    |> cast(attrs, [
      :flight_number,
      :departure_time,
      :arrival_time,
      :aircraft,
      :base_price,
      :stops,
      :airline_id,
      :departure_airport_id,
      :arrival_airport_id
    ])
    |> validate_required([
      :flight_number,
      :departure_time,
      :arrival_time,
      :aircraft,
      :base_price,
      :stops,
      :airline_id,
      :departure_airport_id,
      :arrival_airport_id
    ])
    |> validate_number(:base_price, greater_than: 0)
    |> validate_number(:stops, greater_than_or_equal_to: 0)
    |> validate_arrival_after_departure()
    |> validate_different_airports()
    |> foreign_key_constraint(:airline_id)
    |> foreign_key_constraint(:departure_airport_id)
    |> foreign_key_constraint(:arrival_airport_id)
    |> check_constraint(:departure_airport_id, name: :different_departure_and_arrival_airport)
  end

  defp validate_arrival_after_departure(changeset) do
    departure = get_field(changeset, :departure_time)
    arrival = get_field(changeset, :arrival_time)

    if departure && arrival && DateTime.compare(arrival, departure) != :gt do
      add_error(changeset, :arrival_time, "must be after departure time")
    else
      changeset
    end
  end

  defp validate_different_airports(changeset) do
    departure = get_field(changeset, :departure_airport_id)
    arrival = get_field(changeset, :arrival_airport_id)

    if departure && arrival && departure == arrival do
      add_error(changeset, :arrival_airport_id, "must be different from departure airport")
    else
      changeset
    end
  end
end
