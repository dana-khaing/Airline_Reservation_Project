defmodule AlbertAirline.Flights.Supplier do
  @moduledoc """
  Real flight-inventory access, dispatched to whichever adapter is
  configured under `:albert_airline, :flights_supplier_adapter` (the real
  Duffel client in dev/prod, a stub in test — see
  `AlbertAirline.Flights.Supplier.Adapter`).

  Distinct from `AlbertAirline.Flights`, which manages this app's own
  admin-curated flight/seat records — the two are not yet connected. This
  module exists so a real supplier integration can be built and tested
  independently before deciding how (or whether) it replaces admin-curated
  inventory in the booking flow. See GO_LIVE.md item 1.
  """

  @doc "Searches real flight offers for the given origin/destination/date."
  def search_offers(params), do: adapter().search_offers(params)

  @doc "Looks up the seat map for a given offer id."
  def get_seat_map(offer_id), do: adapter().get_seat_map(offer_id)

  defp adapter,
    do:
      Application.get_env(
        :albert_airline,
        :flights_supplier_adapter,
        AlbertAirline.Flights.Supplier.DuffelClient
      )
end
