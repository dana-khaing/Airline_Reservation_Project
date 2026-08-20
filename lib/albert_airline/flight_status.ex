defmodule AlbertAirline.FlightStatus do
  @moduledoc """
  Live flight-status lookups (scheduled/active/landed, delay, gate),
  dispatched to whichever adapter is configured under
  `:albert_airline, :flight_status_adapter` (the real Aviationstack client
  in dev/prod, a stub in test — see `AlbertAirline.FlightStatus.Adapter`).
  Results are cached briefly (`AlbertAirline.FlightStatus.Cache`) so N
  connected viewers of one flight don't multiply the API calls.
  """

  alias AlbertAirline.FlightStatus.Cache

  @doc """
  Looks up live status for an `AlbertAirline.Flights.Flight` — must have
  `:airline` preloaded. Returns `{:ok, status}`, `{:error, :not_found}`
  (no live match — expected for this app's fictional seeded flight
  numbers), or `{:error, term()}` for an adapter/network failure.
  """
  def get_status(%AlbertAirline.Flights.Flight{} = flight) do
    flight_iata = flight_iata(flight)
    date = DateTime.to_date(flight.departure_time)

    Cache.fetch({flight_iata, date}, fn -> adapter().get_status(flight_iata, date) end)
  end

  defp flight_iata(flight) do
    number = flight.flight_number |> String.split("-") |> List.last()
    "#{flight.airline.code}#{number}"
  end

  defp adapter,
    do:
      Application.get_env(
        :albert_airline,
        :flight_status_adapter,
        AlbertAirline.FlightStatus.AviationstackClient
      )
end
