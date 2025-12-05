defmodule AlbertAirline.Flights.SupplierTest do
  use ExUnit.Case, async: true

  alias AlbertAirline.Flights.Supplier

  describe "search_offers/1" do
    test "returns offers from the configured adapter" do
      assert {:ok, [offer]} =
               Supplier.search_offers(%{
                 origin: "JFK",
                 destination: "LAX",
                 departure_date: ~D[2026-09-01]
               })

      assert offer.flight_number == "SA123"
      assert %DateTime{} = offer.departure_time
      assert DateTime.compare(offer.arrival_time, offer.departure_time) == :gt
    end

    test "propagates an adapter error" do
      assert {:error, :simulated_failure} =
               Supplier.search_offers(%{
                 origin: "ERR",
                 destination: "LAX",
                 departure_date: ~D[2026-09-01]
               })
    end
  end

  describe "get_seat_map/1" do
    test "returns seats from the configured adapter" do
      assert {:ok, seats} = Supplier.get_seat_map("off_test_123")
      assert Enum.any?(seats, & &1.available)
      assert Enum.any?(seats, &(not &1.available))
    end

    test "propagates an adapter error" do
      assert {:error, :simulated_failure} = Supplier.get_seat_map("off_test_error")
    end
  end
end
