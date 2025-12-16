defmodule AlbertAirline.FlightStatusTest do
  use AlbertAirline.DataCase

  import AlbertAirline.FlightsFixtures

  alias AlbertAirline.FlightStatus

  test "get_status/1 returns the stub adapter's result for a matching flight" do
    airline = airline_fixture(%{code: "TG"})
    flight = flight_fixture(%{airline_id: airline.id, flight_number: "TG-220"}) |> with_airline()

    assert {:ok, status} = FlightStatus.get_status(flight)
    assert status.status == "active"
  end

  test "get_status/1 returns an error instead of crashing when the adapter raises" do
    previous = Application.get_env(:albert_airline, :flight_status_adapter)

    Application.put_env(
      :albert_airline,
      :flight_status_adapter,
      AlbertAirline.FlightStatus.RaisingClient
    )

    on_exit(fn ->
      Application.put_env(:albert_airline, :flight_status_adapter, previous)
    end)

    flight = flight_fixture() |> with_airline()

    assert {:error, _reason} = FlightStatus.get_status(flight)
  end

  defp with_airline(flight), do: AlbertAirline.Repo.preload(flight, :airline)
end
