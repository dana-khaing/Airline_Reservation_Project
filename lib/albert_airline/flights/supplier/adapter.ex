defmodule AlbertAirline.Flights.Supplier.Adapter do
  @moduledoc """
  Behaviour for a real flight-inventory supplier: offer search and seat
  maps. `AlbertAirline.Flights.Supplier.DuffelClient` is the real
  implementation (https://duffel.com); tests use a stub adapter configured
  via `:albert_airline, :flights_supplier_adapter` so no test ever calls
  out to Duffel. Mirrors the real/stub split in
  `AlbertAirline.Payments.Adapter`.

  This is search-only. It does not create bookings/orders against the
  supplier, and nothing in `AlbertAirline.Bookings` calls it yet — the
  seat-claim transaction there still operates on locally stored
  `AlbertAirline.Flights.Seat` rows. Wiring supplier offers into that flow
  is future work; see GO_LIVE.md item 1.
  """

  @type search_params :: %{
          required(:origin) => String.t(),
          required(:destination) => String.t(),
          required(:departure_date) => Date.t(),
          optional(:passengers) => pos_integer(),
          optional(:cabin_class) => String.t()
        }

  @type offer :: %{
          id: String.t(),
          airline: String.t() | nil,
          flight_number: String.t() | nil,
          departure_time: DateTime.t() | nil,
          arrival_time: DateTime.t() | nil,
          aircraft: String.t() | nil,
          total_amount: Decimal.t() | nil,
          currency: String.t() | nil
        }

  @type seat :: %{
          designator: String.t(),
          available: boolean(),
          extra_amount: Decimal.t() | nil,
          extra_currency: String.t() | nil
        }

  @doc "Searches real flight offers for a given origin/destination/date."
  @callback search_offers(search_params()) :: {:ok, [offer()]} | {:error, term()}

  @doc "Looks up the seat map for a given offer id."
  @callback get_seat_map(offer_id :: String.t()) :: {:ok, [seat()]} | {:error, term()}
end
