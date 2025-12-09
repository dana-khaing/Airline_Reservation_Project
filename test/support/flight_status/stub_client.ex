defmodule AlbertAirline.FlightStatus.StubClient do
  @moduledoc """
  Test-only flight-status adapter: no network calls. Returns a canned
  "active" status for flight_iata `"TG220"`, `{:error, :simulated_failure}`
  for `"ERR000"`, and `{:error, :not_found}` for anything else — matching
  the behavior expected for this app's mostly-fictional demo flight
  numbers.
  """

  @behaviour AlbertAirline.FlightStatus.Adapter

  @impl true
  def get_status("ERR000", _date), do: {:error, :simulated_failure}

  def get_status("TG220", date) do
    {:ok,
     %{
       status: "active",
       departure_scheduled: DateTime.new!(date, ~T[23:40:00], "Etc/UTC"),
       departure_estimated: DateTime.new!(date, ~T[23:55:00], "Etc/UTC"),
       departure_actual: DateTime.new!(date, ~T[23:58:00], "Etc/UTC"),
       departure_gate: "A12",
       departure_delay_minutes: 18,
       arrival_scheduled: nil,
       arrival_estimated: nil,
       arrival_actual: nil,
       arrival_gate: nil,
       arrival_delay_minutes: nil
     }}
  end

  def get_status(_flight_iata, _date), do: {:error, :not_found}
end
