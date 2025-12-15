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

    test "get_booking_for_user!/2 returns the booking when it belongs to the given user" do
      user = AlbertAirline.AccountsFixtures.user_fixture()
      booking = booking_fixture(%{user_id: user.id})

      assert Bookings.get_booking_for_user!(booking.id, user.id).id == booking.id
    end

    test "get_booking_for_user!/2 raises when the booking belongs to a different user" do
      owner = AlbertAirline.AccountsFixtures.user_fixture()
      other_user = AlbertAirline.AccountsFixtures.user_fixture()
      booking = booking_fixture(%{user_id: owner.id})

      assert_raise Ecto.NoResultsError, fn ->
        Bookings.get_booking_for_user!(booking.id, other_user.id)
      end
    end

    test "get_booking_for_user!/2 raises when the booking id doesn't exist" do
      user = AlbertAirline.AccountsFixtures.user_fixture()

      assert_raise Ecto.NoResultsError, fn ->
        Bookings.get_booking_for_user!(-1, user.id)
      end
    end

    test "create_booking/1 with valid data creates a booking" do
      seat = AlbertAirline.FlightsFixtures.seat_fixture()
      flight = AlbertAirline.FlightsFixtures.flight_fixture()
      user = AlbertAirline.AccountsFixtures.user_fixture()

      valid_attrs = %{
        status: "confirmed",
        total_price: "120.5",
        confirmation_code: "some confirmation_code",
        booked_at: ~U[2026-08-08 10:25:00Z],
        seat_id: seat.id,
        flight_id: flight.id,
        user_id: user.id
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
      user = AlbertAirline.AccountsFixtures.user_fixture()

      assert {:ok, _booking} =
               Bookings.create_booking(%{
                 status: "confirmed",
                 total_price: "120.5",
                 confirmation_code: "first-confirmation",
                 booked_at: ~U[2026-08-08 10:25:00Z],
                 seat_id: seat.id,
                 flight_id: flight.id,
                 user_id: user.id
               })

      assert {:error, changeset} =
               Bookings.create_booking(%{
                 status: "confirmed",
                 total_price: "120.5",
                 confirmation_code: "second-confirmation",
                 booked_at: ~U[2026-08-08 10:25:00Z],
                 seat_id: seat.id,
                 flight_id: flight.id,
                 user_id: user.id
               })

      assert %{seat_id: ["has already been taken"]} = errors_on(changeset)
    end
  end

  describe "resilience to Payments adapter failures" do
    setup do
      previous = Application.get_env(:albert_airline, :payments_adapter)

      Application.put_env(
        :albert_airline,
        :payments_adapter,
        AlbertAirline.Payments.RaisingClient
      )

      on_exit(fn ->
        Application.put_env(:albert_airline, :payments_adapter, previous)
      end)
    end

    test "start_checkout/5 returns an error instead of crashing when Payments raises" do
      flight = AlbertAirline.FlightsFixtures.flight_fixture()
      seat = AlbertAirline.FlightsFixtures.seat_fixture(%{flight_id: flight.id})
      user = AlbertAirline.AccountsFixtures.user_fixture()

      assert {:error, _reason} =
               Bookings.start_checkout(
                 user,
                 flight,
                 [seat.id],
                 "https://example.com/ok",
                 "https://example.com/cancel"
               )
    end

    test "confirm_from_stripe_session/1 returns an error instead of crashing when Payments raises" do
      assert {:error, _reason} = Bookings.confirm_from_stripe_session("cs_test_whatever")
    end
  end
end
