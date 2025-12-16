defmodule AlbertAirline.FlightStatus.RaisingClient do
  @moduledoc """
  Test-only flight-status adapter that always raises, simulating what
  `AviationstackClient` does when `AVIATIONSTACK_API_KEY` is unset. Used
  to prove `AlbertAirline.FlightStatus.get_status/1` converts that into
  `{:error, _}` instead of crashing the caller.
  """

  @behaviour AlbertAirline.FlightStatus.Adapter

  @impl true
  def get_status(_flight_iata, _date), do: raise("simulated FlightStatus failure")
end
