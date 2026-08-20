defmodule AlbertAirline.FlightStatus.AviationstackClientTest do
  @moduledoc """
  AviationstackClient makes real HTTP calls to api.aviationstack.com and is
  not exercised end to end here (no live Aviationstack credentials are
  available in this environment — see the adapter's own moduledoc).
  Instead, Req calls are routed through a Req.Test stub (configured in
  config/test.exs), so the response-parsing logic itself — including the
  "200 with an error body" quirk — is verified without a network call,
  plus the one piece covered the same way as AlbertAirline.Flights.Supplier.DuffelClientTest:
  refusing to proceed when AVIATIONSTACK_API_KEY isn't configured.
  """

  use ExUnit.Case, async: false

  alias AlbertAirline.FlightStatus.AviationstackClient

  setup do
    previous = Application.get_env(:albert_airline, :aviationstack_api_key)
    Application.put_env(:albert_airline, :aviationstack_api_key, "test_key")

    on_exit(fn ->
      Application.put_env(:albert_airline, :aviationstack_api_key, previous)
    end)
  end

  test "get_status/2 raises a clear error when no API key is configured" do
    Application.put_env(:albert_airline, :aviationstack_api_key, nil)

    assert_raise RuntimeError, ~r/AVIATIONSTACK_API_KEY is not configured/, fn ->
      AviationstackClient.get_status("TG220", ~D[2026-09-01])
    end
  end

  test "get_status/2 parses a matching entry into a status map" do
    Req.Test.stub(AviationstackClient, fn conn ->
      Req.Test.json(conn, %{
        "data" => [
          %{
            "flight_date" => "2026-09-01",
            "flight_status" => "active",
            "departure" => %{
              "scheduled" => "2026-09-01T23:40:00+00:00",
              "estimated" => "2026-09-01T23:55:00+00:00",
              "actual" => "2026-09-01T23:58:00+00:00",
              "gate" => "A12",
              "delay" => 18
            },
            "arrival" => %{
              "scheduled" => "2026-09-02T06:15:00+00:00",
              "estimated" => nil,
              "actual" => nil,
              "gate" => nil,
              "delay" => nil
            }
          }
        ]
      })
    end)

    assert {:ok, status} = AviationstackClient.get_status("TG220", ~D[2026-09-01])
    assert status.status == "active"
    assert status.departure_gate == "A12"
    assert status.departure_delay_minutes == 18
    assert status.departure_scheduled == ~U[2026-09-01 23:40:00Z]
    assert status.arrival_scheduled == ~U[2026-09-02 06:15:00Z]
  end

  test "get_status/2 returns :not_found when no entry matches the requested date" do
    Req.Test.stub(AviationstackClient, fn conn ->
      Req.Test.json(conn, %{
        "data" => [%{"flight_date" => "2026-01-01", "flight_status" => "scheduled"}]
      })
    end)

    assert AviationstackClient.get_status("TG220", ~D[2026-09-01]) == {:error, :not_found}
  end

  test "get_status/2 returns :not_found when data is empty" do
    Req.Test.stub(AviationstackClient, fn conn ->
      Req.Test.json(conn, %{"data" => []})
    end)

    assert AviationstackClient.get_status("TG220", ~D[2026-09-01]) == {:error, :not_found}
  end

  test "get_status/2 surfaces Aviationstack's 200-with-error-body quirk as an error" do
    Req.Test.stub(AviationstackClient, fn conn ->
      Req.Test.json(conn, %{
        "error" => %{"code" => "rate_limit_reached", "message" => "Too many requests"}
      })
    end)

    assert {:error, {:aviationstack_error, %{"code" => "rate_limit_reached"}}} =
             AviationstackClient.get_status("TG220", ~D[2026-09-01])
  end

  test "get_status/2 returns an error for a non-2xx response" do
    Req.Test.stub(AviationstackClient, fn conn ->
      conn |> Plug.Conn.put_status(500) |> Req.Test.json(%{"message" => "server error"})
    end)

    assert {:error, {:aviationstack_error, 500, _body}} =
             AviationstackClient.get_status("TG220", ~D[2026-09-01])
  end
end
