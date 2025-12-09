defmodule AlbertAirline.FlightStatus.Adapter do
  @moduledoc """
  Behaviour for a live flight-status lookup provider.
  `AlbertAirline.FlightStatus.AviationstackClient` is the real
  implementation (https://aviationstack.com); tests use a stub adapter
  configured via `:albert_airline, :flight_status_adapter`. Mirrors the
  real/stub split in `AlbertAirline.Flights.Supplier.Adapter` and
  `AlbertAirline.Payments.Adapter`.
  """

  @type status :: %{
          status: String.t() | nil,
          departure_scheduled: DateTime.t() | nil,
          departure_estimated: DateTime.t() | nil,
          departure_actual: DateTime.t() | nil,
          departure_gate: String.t() | nil,
          departure_delay_minutes: integer() | nil,
          arrival_scheduled: DateTime.t() | nil,
          arrival_estimated: DateTime.t() | nil,
          arrival_actual: DateTime.t() | nil,
          arrival_gate: String.t() | nil,
          arrival_delay_minutes: integer() | nil
        }

  @doc """
  Looks up live status for `flight_iata` (airline IATA code + flight
  number, no separator, e.g. `"TG220"`) on `date`. Returns
  `{:error, :not_found}` when the provider has no live match for that
  flight/date — the expected outcome for this app's fictional demo flight
  numbers, distinct from an adapter/network failure.
  """
  @callback get_status(flight_iata :: String.t(), date :: Date.t()) ::
              {:ok, status()} | {:error, :not_found} | {:error, term()}
end
