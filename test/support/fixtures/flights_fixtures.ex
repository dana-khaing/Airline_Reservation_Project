defmodule AlbertAirline.FlightsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `AlbertAirline.Flights` context.
  """

  @doc """
  Generate a unique airline code.
  """
  def unique_airline_code, do: "AL#{System.unique_integer([:positive])}"

  @doc """
  Generate a airline.
  """
  def airline_fixture(attrs \\ %{}) do
    {:ok, airline} =
      attrs
      |> Enum.into(%{
        code: unique_airline_code(),
        name: "Albert Airline"
      })
      |> AlbertAirline.Flights.create_airline()

    airline
  end

  @doc """
  Generate a unique airport iata_code.
  """
  def unique_airport_iata_code, do: "A#{System.unique_integer([:positive])}"

  @doc """
  Generate a airport.
  """
  def airport_fixture(attrs \\ %{}) do
    {:ok, airport} =
      attrs
      |> Enum.into(%{
        city: "Some City",
        country: "Some Country",
        iata_code: unique_airport_iata_code(),
        name: "Some International Airport"
      })
      |> AlbertAirline.Flights.create_airport()

    airport
  end

  @doc """
  Generate a unique flight number.
  """
  def unique_flight_number, do: "AB#{System.unique_integer([:positive])}"

  @doc """
  Generate a flight.
  """
  def flight_fixture(attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})

    attrs =
      attrs
      |> Map.put_new_lazy(:airline_id, fn -> airline_fixture().id end)
      |> Map.put_new_lazy(:departure_airport_id, fn -> airport_fixture().id end)
      |> Map.put_new_lazy(:arrival_airport_id, fn -> airport_fixture().id end)

    {:ok, flight} =
      attrs
      |> Enum.into(%{
        aircraft: "Boeing 777-300ER",
        arrival_time: ~U[2026-08-08 18:00:00Z],
        base_price: "120.50",
        departure_time: ~U[2026-08-08 10:25:00Z],
        flight_number: unique_flight_number(),
        stops: 0
      })
      |> AlbertAirline.Flights.create_flight()

    flight
  end

  @doc """
  Generate a seat.
  """
  def seat_fixture(attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{})
      |> Map.put_new_lazy(:flight_id, fn -> flight_fixture().id end)

    {:ok, seat} =
      attrs
      |> Enum.into(%{
        label: "1A",
        seat_class: "economy",
        status: "available"
      })
      |> AlbertAirline.Flights.create_seat()

    seat
  end
end
