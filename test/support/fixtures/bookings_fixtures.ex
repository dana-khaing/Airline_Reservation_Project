defmodule AlbertAirline.BookingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `AlbertAirline.Bookings` context.
  """

  import AlbertAirline.FlightsFixtures

  @doc """
  Generate a unique booking confirmation_code.
  """
  def unique_booking_confirmation_code, do: "CONF#{System.unique_integer([:positive])}"

  @doc """
  Generate a booking.
  """
  def booking_fixture(attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{})
      |> Map.put_new_lazy(:seat_id, fn -> seat_fixture().id end)
      |> Map.put_new_lazy(:flight_id, fn -> flight_fixture().id end)

    {:ok, booking} =
      attrs
      |> Enum.into(%{
        booked_at: ~U[2026-08-08 10:25:00Z],
        confirmation_code: unique_booking_confirmation_code(),
        status: "confirmed",
        total_price: "120.50"
      })
      |> AlbertAirline.Bookings.create_booking()

    booking
  end
end
