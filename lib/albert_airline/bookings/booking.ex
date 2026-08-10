defmodule AlbertAirline.Bookings.Booking do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(confirmed cancelled)

  schema "bookings" do
    field :status, :string, default: "confirmed"
    field :total_price, :decimal
    field :confirmation_code, :string
    field :booked_at, :utc_datetime
    field :stripe_payment_intent_id, :string

    belongs_to :seat, AlbertAirline.Flights.Seat
    belongs_to :flight, AlbertAirline.Flights.Flight
    belongs_to :user, AlbertAirline.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(booking, attrs) do
    booking
    |> cast(attrs, [
      :status,
      :total_price,
      :confirmation_code,
      :booked_at,
      :stripe_payment_intent_id,
      :seat_id,
      :flight_id,
      :user_id
    ])
    |> validate_required([
      :status,
      :total_price,
      :confirmation_code,
      :booked_at,
      :seat_id,
      :flight_id,
      :user_id
    ])
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:total_price, greater_than: 0)
    |> unique_constraint(:seat_id, name: :bookings_active_seat_id_index)
    |> foreign_key_constraint(:seat_id)
    |> foreign_key_constraint(:flight_id)
    |> foreign_key_constraint(:user_id)
  end
end
