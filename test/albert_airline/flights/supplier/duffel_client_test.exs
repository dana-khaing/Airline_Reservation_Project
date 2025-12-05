defmodule AlbertAirline.Flights.Supplier.DuffelClientTest do
  @moduledoc """
  DuffelClient makes real HTTP calls to api.duffel.com and is not exercised
  end to end here (no live Duffel credentials are available in this
  environment — see the adapter's own moduledoc). This covers the one
  piece of its behavior that's both real and testable without a network
  call: refusing to proceed when DUFFEL_API_KEY isn't configured, rather
  than silently sending an unauthenticated request.
  """

  use ExUnit.Case, async: false

  alias AlbertAirline.Flights.Supplier.DuffelClient

  setup do
    previous = Application.get_env(:albert_airline, :duffel_api_key)
    Application.put_env(:albert_airline, :duffel_api_key, nil)

    on_exit(fn ->
      Application.put_env(:albert_airline, :duffel_api_key, previous)
    end)
  end

  test "search_offers/1 raises a clear error when no API key is configured" do
    assert_raise RuntimeError, ~r/DUFFEL_API_KEY is not configured/, fn ->
      DuffelClient.search_offers(%{
        origin: "JFK",
        destination: "LAX",
        departure_date: ~D[2026-09-01]
      })
    end
  end

  test "get_seat_map/1 raises a clear error when no API key is configured" do
    assert_raise RuntimeError, ~r/DUFFEL_API_KEY is not configured/, fn ->
      DuffelClient.get_seat_map("off_test_123")
    end
  end
end
