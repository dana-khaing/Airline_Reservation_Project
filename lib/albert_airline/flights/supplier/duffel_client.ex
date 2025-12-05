defmodule AlbertAirline.Flights.Supplier.DuffelClient do
  @moduledoc """
  Real Duffel adapter (https://duffel.com), calling the REST API directly
  with Req (per this project's convention of using Req rather than a
  vendored SDK — see `AlbertAirline.Payments.StripeClient`).

  Requires `DUFFEL_API_KEY` (a test-mode access token, `duffel_test_...`)
  to be set in the environment. Get one from a free Duffel account —
  no business verification is required for test access, only for later
  switching to a live (`duffel_live_...`) token.

  The response parsing below follows Duffel's published API reference for
  the Offer and Seat Map objects, but this integration was built and
  tested against the stub adapter (see
  `AlbertAirline.Flights.Supplier.StubClient`), since no live Duffel
  credentials are available in this environment — it has not yet been
  exercised against the real Duffel API. Validate it against a real
  sandbox response before relying on it.
  """

  @behaviour AlbertAirline.Flights.Supplier.Adapter

  @base_url "https://api.duffel.com"
  @duffel_version "v2"

  @impl true
  def search_offers(params) do
    body = %{
      "data" => %{
        "slices" => [
          %{
            "origin" => params.origin,
            "destination" => params.destination,
            "departure_date" => Date.to_iso8601(params.departure_date)
          }
        ],
        "passengers" => List.duplicate(%{"type" => "adult"}, Map.get(params, :passengers, 1)),
        "cabin_class" => Map.get(params, :cabin_class, "economy")
      }
    }

    "#{@base_url}/air/offer_requests?return_offers=true"
    |> Req.post(json: body, headers: headers())
    |> handle_response(fn body -> Enum.map(body["data"]["offers"] || [], &parse_offer/1) end)
  end

  @impl true
  def get_seat_map(offer_id) do
    "#{@base_url}/air/seat_maps?offer_id=#{URI.encode_www_form(offer_id)}"
    |> Req.get(headers: headers())
    |> handle_response(fn body ->
      body["data"]
      |> List.wrap()
      |> Enum.flat_map(&seats_from_seat_map/1)
    end)
  end

  defp seats_from_seat_map(seat_map) do
    for cabin <- seat_map["cabins"] || [],
        row <- cabin["rows"] || [],
        section <- row["sections"] || [],
        element <- section["elements"] || [],
        element["type"] == "seat" do
      parse_seat(element)
    end
  end

  defp parse_seat(element) do
    services = element["available_services"] || []
    first_service = List.first(services)

    %{
      designator: element["designator"],
      available: services != [],
      extra_amount: first_service && to_decimal(first_service["total_amount"]),
      extra_currency: first_service && first_service["total_currency"]
    }
  end

  defp parse_offer(offer) do
    slice = List.first(offer["slices"] || [])
    segment = slice && List.first(slice["segments"] || [])

    %{
      id: offer["id"],
      airline: segment && get_in(segment, ["marketing_carrier", "name"]),
      flight_number: segment && flight_number(segment),
      departure_time: segment && parse_datetime(segment["departing_at"]),
      arrival_time: segment && parse_datetime(segment["arriving_at"]),
      aircraft: segment && get_in(segment, ["aircraft", "name"]),
      total_amount: to_decimal(offer["total_amount"]),
      currency: offer["total_currency"]
    }
  end

  defp flight_number(segment) do
    code = get_in(segment, ["marketing_carrier", "iata_code"])
    number = segment["marketing_carrier_flight_number"]
    if code && number, do: "#{code}#{number}"
  end

  defp parse_datetime(nil), do: nil

  defp parse_datetime(string) do
    case DateTime.from_iso8601(string) do
      {:ok, datetime, _offset} -> datetime
      {:error, _reason} -> nil
    end
  end

  defp to_decimal(nil), do: nil
  defp to_decimal(value), do: Decimal.new(value)

  defp handle_response({:ok, %{status: status, body: body}}, transform) when status in 200..299,
    do: {:ok, transform.(body)}

  defp handle_response({:ok, %{status: status, body: body}}, _transform),
    do: {:error, {:duffel_error, status, body}}

  defp handle_response({:error, reason}, _transform), do: {:error, reason}

  defp headers do
    [
      {"Authorization", "Bearer #{api_key()}"},
      {"Duffel-Version", @duffel_version},
      {"Accept", "application/json"}
    ]
  end

  defp api_key do
    Application.get_env(:albert_airline, :duffel_api_key) ||
      raise """
      DUFFEL_API_KEY is not configured. Set it in the environment (a Duffel \
      test-mode access token, duffel_test_...) before real flight search/seat-map \
      lookups can be made. Get a free key at https://duffel.com — no business \
      verification is required for test access.
      """
  end
end
