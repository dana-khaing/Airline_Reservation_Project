defmodule AlbertAirline.Flights.Supplier.StubClient do
  @moduledoc """
  Test-only flight-supplier adapter: no network calls. Returns one canned
  offer from `search_offers/1` and a small canned seat map from
  `get_seat_map/1`. Pass `origin: "ERR"` to `search_offers/1`, or the offer
  id `"off_test_error"` to `get_seat_map/1`, to simulate a supplier error
  instead.
  """

  @behaviour AlbertAirline.Flights.Supplier.Adapter

  @impl true
  def search_offers(%{origin: "ERR"}), do: {:error, :simulated_failure}

  def search_offers(params) do
    departure = DateTime.new!(params.departure_date, ~T[09:00:00], "Etc/UTC")

    {:ok,
     [
       %{
         id: "off_test_#{System.unique_integer([:positive])}",
         airline: "Stub Airways",
         flight_number: "SA123",
         departure_time: departure,
         arrival_time: DateTime.add(departure, 3 * 60 * 60),
         aircraft: "Airbus A320",
         total_amount: Decimal.new("199.00"),
         currency: "USD"
       }
     ]}
  end

  @impl true
  def get_seat_map("off_test_error"), do: {:error, :simulated_failure}

  def get_seat_map(_offer_id) do
    {:ok,
     [
       %{
         designator: "1A",
         available: true,
         extra_amount: Decimal.new("25.00"),
         extra_currency: "USD"
       },
       %{designator: "1B", available: false, extra_amount: nil, extra_currency: nil}
     ]}
  end
end
