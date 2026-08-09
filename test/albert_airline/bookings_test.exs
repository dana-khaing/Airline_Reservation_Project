defmodule AlbertAirline.BookingsTest do
  use AlbertAirline.DataCase

  alias AlbertAirline.Bookings

  describe "bookings" do
    alias AlbertAirline.Bookings.Booking

    import AlbertAirline.BookingsFixtures

    @invalid_attrs %{status: nil, total_price: nil, confirmation_code: nil, booked_at: nil}

    test "list_bookings/0 returns all bookings" do
      booking = booking_fixture()
      assert Bookings.list_bookings() == [booking]
    end

    test "get_booking!/1 returns the booking with given id" do
      booking = booking_fixture()
      assert Bookings.get_booking!(booking.id) == booking
    end

    test "create_booking/1 with valid data creates a booking" do
      seat = AlbertAirline.FlightsFixtures.seat_fixture()
      flight = AlbertAirline.FlightsFixtures.flight_fixture()

      valid_attrs = %{
        status: "confirmed",
        total_price: "120.5",
        confirmation_code: "some confirmation_code",
        booked_at: ~U[2026-08-08 10:25:00Z],
        seat_id: seat.id,
        flight_id: flight.id
      }

      assert {:ok, %Booking{} = booking} = Bookings.create_booking(valid_attrs)
      assert booking.status == "confirmed"
      assert booking.total_price == Decimal.new("120.5")
      assert booking.confirmation_code == "some confirmation_code"
      assert booking.booked_at == ~U[2026-08-08 10:25:00Z]
    end

    test "create_booking/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bookings.create_booking(@invalid_attrs)
    end

    test "update_booking/2 with valid data updates the booking" do
      booking = booking_fixture()

      update_attrs = %{
        status: "cancelled",
        total_price: "456.7",
        confirmation_code: "some updated confirmation_code",
        booked_at: ~U[2026-08-09 10:25:00Z]
      }

      assert {:ok, %Booking{} = booking} = Bookings.update_booking(booking, update_attrs)
      assert booking.status == "cancelled"
      assert booking.total_price == Decimal.new("456.7")
      assert booking.confirmation_code == "some updated confirmation_code"
      assert booking.booked_at == ~U[2026-08-09 10:25:00Z]
    end

    test "update_booking/2 with invalid data returns error changeset" do
      booking = booking_fixture()
      assert {:error, %Ecto.Changeset{}} = Bookings.update_booking(booking, @invalid_attrs)
      assert booking == Bookings.get_booking!(booking.id)
    end

    test "delete_booking/1 deletes the booking" do
      booking = booking_fixture()
      assert {:ok, %Booking{}} = Bookings.delete_booking(booking)
      assert_raise Ecto.NoResultsError, fn -> Bookings.get_booking!(booking.id) end
    end

    test "change_booking/1 returns a booking changeset" do
      booking = booking_fixture()
      assert %Ecto.Changeset{} = Bookings.change_booking(booking)
    end

    test "a seat cannot have two active bookings at once" do
      seat = AlbertAirline.FlightsFixtures.seat_fixture()
      flight = AlbertAirline.FlightsFixtures.flight_fixture()

      assert {:ok, _booking} =
               Bookings.create_booking(%{
                 status: "confirmed",
                 total_price: "120.5",
                 confirmation_code: "first-confirmation",
                 booked_at: ~U[2026-08-08 10:25:00Z],
                 seat_id: seat.id,
                 flight_id: flight.id
               })

      assert {:error, changeset} =
               Bookings.create_booking(%{
                 status: "confirmed",
                 total_price: "120.5",
                 confirmation_code: "second-confirmation",
                 booked_at: ~U[2026-08-08 10:25:00Z],
                 seat_id: seat.id,
                 flight_id: flight.id
               })

      assert %{seat_id: ["has already been taken"]} = errors_on(changeset)
    end
  end
end
