defmodule AlbertAirline.Flights.Seat do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(available booked)
  @classes ~w(economy business)

  schema "seats" do
    field :label, :string
    field :seat_class, :string
    field :status, :string, default: "available"

    belongs_to :flight, AlbertAirline.Flights.Flight
    has_many :bookings, AlbertAirline.Bookings.Booking

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(seat, attrs) do
    seat
    |> cast(attrs, [:label, :seat_class, :status, :flight_id])
    |> validate_required([:label, :seat_class, :status, :flight_id])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:seat_class, @classes)
    |> foreign_key_constraint(:flight_id)
    |> unique_constraint([:flight_id, :label])
  end
end
