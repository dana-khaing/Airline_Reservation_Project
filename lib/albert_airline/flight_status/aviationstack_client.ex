defmodule AlbertAirline.FlightStatus.AviationstackClient do
  @moduledoc """
  Real Aviationstack adapter (https://aviationstack.com), calling the REST
  API directly with Req (per this project's convention of using Req rather
  than a vendored SDK — see `AlbertAirline.Flights.Supplier.DuffelClient`).

  Requires `AVIATIONSTACK_API_KEY` (a free-tier key) to be set in the
  environment. Two things this client has to handle that the app's other
  Req-based clients don't:

    * The free tier is HTTP-only (no HTTPS) — `@base_url` below is
      deliberately `http://`, not a typo.
    * Aviationstack frequently responds with HTTP 200 even for a bad,
      unauthorized, or rate-limited request, putting an `"error"` object
      in the body instead of `"data"`. `handle_response/2` checks for that
      explicitly before falling through to the normal success path, so a
      rate-limit hit doesn't silently render as "no live flight found."

  This integration was built and tested against `Req.Test`-stubbed
  responses (see `aviationstack_client_test.exs`) and the stub adapter
  (`AlbertAirline.FlightStatus.StubClient`) used elsewhere in the app,
  since no live Aviationstack credentials are available in this
  environment — it has not yet been exercised against the real API.
  Validate it against a real response before relying on it for a demo.
  """

  @behaviour AlbertAirline.FlightStatus.Adapter

  @base_url "http://api.aviationstack.com/v1/flights"

  @impl true
  def get_status(flight_iata, date) do
    @base_url
    |> Req.get(params: [access_key: api_key(), flight_iata: flight_iata])
    |> handle_response(date)
  end

  defp handle_response({:ok, %{status: status, body: %{"error" => error}}}, _date)
       when status in 200..299,
       do: {:error, {:aviationstack_error, error}}

  defp handle_response({:ok, %{status: status, body: body}}, date) when status in 200..299 do
    iso_date = Date.to_iso8601(date)

    body
    |> Map.get("data", [])
    |> Enum.find(&(&1["flight_date"] == iso_date))
    |> case do
      nil -> {:error, :not_found}
      entry -> {:ok, parse_status(entry)}
    end
  end

  defp handle_response({:ok, %{status: status, body: body}}, _date),
    do: {:error, {:aviationstack_error, status, body}}

  defp handle_response({:error, reason}, _date), do: {:error, reason}

  defp parse_status(entry) do
    %{
      status: entry["flight_status"],
      departure_scheduled: parse_datetime(get_in(entry, ["departure", "scheduled"])),
      departure_estimated: parse_datetime(get_in(entry, ["departure", "estimated"])),
      departure_actual: parse_datetime(get_in(entry, ["departure", "actual"])),
      departure_gate: get_in(entry, ["departure", "gate"]),
      departure_delay_minutes: get_in(entry, ["departure", "delay"]),
      arrival_scheduled: parse_datetime(get_in(entry, ["arrival", "scheduled"])),
      arrival_estimated: parse_datetime(get_in(entry, ["arrival", "estimated"])),
      arrival_actual: parse_datetime(get_in(entry, ["arrival", "actual"])),
      arrival_gate: get_in(entry, ["arrival", "gate"]),
      arrival_delay_minutes: get_in(entry, ["arrival", "delay"])
    }
  end

  defp parse_datetime(nil), do: nil

  defp parse_datetime(string) do
    case DateTime.from_iso8601(string) do
      {:ok, datetime, _offset} -> datetime
      {:error, _reason} -> nil
    end
  end

  defp api_key do
    Application.get_env(:albert_airline, :aviationstack_api_key) ||
      raise """
      AVIATIONSTACK_API_KEY is not configured. Set it in the environment \
      (a free-tier Aviationstack API key) before live flight-status lookups \
      can be made. Get a free key at https://aviationstack.com — note the \
      free tier is HTTP-only (no HTTPS) and rate-limited; check current \
      limits on their pricing page before relying on it for a demo.
      """
  end
end
