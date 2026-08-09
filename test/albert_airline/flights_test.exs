defmodule AlbertAirline.FlightsTest do
  use AlbertAirline.DataCase

  alias AlbertAirline.Flights

  describe "airlines" do
    alias AlbertAirline.Flights.Airline

    import AlbertAirline.FlightsFixtures

    @invalid_attrs %{code: nil, name: nil}

    test "list_airlines/0 returns all airlines" do
      airline = airline_fixture()
      assert Flights.list_airlines() == [airline]
    end

    test "get_airline!/1 returns the airline with given id" do
      airline = airline_fixture()
      assert Flights.get_airline!(airline.id) == airline
    end

    test "create_airline/1 with valid data creates a airline" do
      valid_attrs = %{code: "some code", name: "some name"}

      assert {:ok, %Airline{} = airline} = Flights.create_airline(valid_attrs)
      assert airline.code == "some code"
      assert airline.name == "some name"
    end

    test "create_airline/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Flights.create_airline(@invalid_attrs)
    end

    test "update_airline/2 with valid data updates the airline" do
      airline = airline_fixture()
      update_attrs = %{code: "some updated code", name: "some updated name"}

      assert {:ok, %Airline{} = airline} = Flights.update_airline(airline, update_attrs)
      assert airline.code == "some updated code"
      assert airline.name == "some updated name"
    end

    test "update_airline/2 with invalid data returns error changeset" do
      airline = airline_fixture()
      assert {:error, %Ecto.Changeset{}} = Flights.update_airline(airline, @invalid_attrs)
      assert airline == Flights.get_airline!(airline.id)
    end

    test "delete_airline/1 deletes the airline" do
      airline = airline_fixture()
      assert {:ok, %Airline{}} = Flights.delete_airline(airline)
      assert_raise Ecto.NoResultsError, fn -> Flights.get_airline!(airline.id) end
    end

    test "change_airline/1 returns a airline changeset" do
      airline = airline_fixture()
      assert %Ecto.Changeset{} = Flights.change_airline(airline)
    end
  end

  describe "airports" do
    alias AlbertAirline.Flights.Airport

    import AlbertAirline.FlightsFixtures

    @invalid_attrs %{name: nil, iata_code: nil, city: nil, country: nil}

    test "list_airports/0 returns all airports" do
      airport = airport_fixture()
      assert Flights.list_airports() == [airport]
    end

    test "get_airport!/1 returns the airport with given id" do
      airport = airport_fixture()
      assert Flights.get_airport!(airport.id) == airport
    end

    test "create_airport/1 with valid data creates a airport" do
      valid_attrs = %{
        name: "some name",
        iata_code: "some iata_code",
        city: "some city",
        country: "some country"
      }

      assert {:ok, %Airport{} = airport} = Flights.create_airport(valid_attrs)
      assert airport.name == "some name"
      assert airport.iata_code == "some iata_code"
      assert airport.city == "some city"
      assert airport.country == "some country"
    end

    test "create_airport/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Flights.create_airport(@invalid_attrs)
    end

    test "update_airport/2 with valid data updates the airport" do
      airport = airport_fixture()

      update_attrs = %{
        name: "some updated name",
        iata_code: "some updated iata_code",
        city: "some updated city",
        country: "some updated country"
      }

      assert {:ok, %Airport{} = airport} = Flights.update_airport(airport, update_attrs)
      assert airport.name == "some updated name"
      assert airport.iata_code == "some updated iata_code"
      assert airport.city == "some updated city"
      assert airport.country == "some updated country"
    end

    test "update_airport/2 with invalid data returns error changeset" do
      airport = airport_fixture()
      assert {:error, %Ecto.Changeset{}} = Flights.update_airport(airport, @invalid_attrs)
      assert airport == Flights.get_airport!(airport.id)
    end

    test "delete_airport/1 deletes the airport" do
      airport = airport_fixture()
      assert {:ok, %Airport{}} = Flights.delete_airport(airport)
      assert_raise Ecto.NoResultsError, fn -> Flights.get_airport!(airport.id) end
    end

    test "change_airport/1 returns a airport changeset" do
      airport = airport_fixture()
      assert %Ecto.Changeset{} = Flights.change_airport(airport)
    end
  end

  describe "flights" do
    alias AlbertAirline.Flights.Flight

    import AlbertAirline.FlightsFixtures

    @invalid_attrs %{
      flight_number: nil,
      departure_time: nil,
      arrival_time: nil,
      aircraft: nil,
      base_price: nil,
      stops: nil
    }

    test "list_flights/0 returns all flights" do
      flight = flight_fixture()
      assert Flights.list_flights() == [flight]
    end

    test "get_flight!/1 returns the flight with given id" do
      flight = flight_fixture()
      assert Flights.get_flight!(flight.id) == flight
    end

    test "create_flight/1 with valid data creates a flight" do
      airline = airline_fixture()
      departure_airport = airport_fixture()
      arrival_airport = airport_fixture()

      valid_attrs = %{
        flight_number: "some flight_number",
        departure_time: ~U[2026-08-08 10:25:00Z],
        arrival_time: ~U[2026-08-08 18:00:00Z],
        aircraft: "some aircraft",
        base_price: "120.5",
        stops: 0,
        airline_id: airline.id,
        departure_airport_id: departure_airport.id,
        arrival_airport_id: arrival_airport.id
      }

      assert {:ok, %Flight{} = flight} = Flights.create_flight(valid_attrs)
      assert flight.flight_number == "some flight_number"
      assert flight.departure_time == ~U[2026-08-08 10:25:00Z]
      assert flight.arrival_time == ~U[2026-08-08 18:00:00Z]
      assert flight.aircraft == "some aircraft"
      assert flight.base_price == Decimal.new("120.5")
      assert flight.stops == 0
    end

    test "create_flight/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Flights.create_flight(@invalid_attrs)
    end

    test "update_flight/2 with valid data updates the flight" do
      flight = flight_fixture()

      update_attrs = %{
        flight_number: "some updated flight_number",
        departure_time: ~U[2026-08-09 10:25:00Z],
        arrival_time: ~U[2026-08-09 18:00:00Z],
        aircraft: "some updated aircraft",
        base_price: "456.7",
        stops: 1
      }

      assert {:ok, %Flight{} = flight} = Flights.update_flight(flight, update_attrs)
      assert flight.flight_number == "some updated flight_number"
      assert flight.departure_time == ~U[2026-08-09 10:25:00Z]
      assert flight.arrival_time == ~U[2026-08-09 18:00:00Z]
      assert flight.aircraft == "some updated aircraft"
      assert flight.base_price == Decimal.new("456.7")
      assert flight.stops == 1
    end

    test "update_flight/2 with invalid data returns error changeset" do
      flight = flight_fixture()
      assert {:error, %Ecto.Changeset{}} = Flights.update_flight(flight, @invalid_attrs)
      assert flight == Flights.get_flight!(flight.id)
    end

    test "delete_flight/1 deletes the flight" do
      flight = flight_fixture()
      assert {:ok, %Flight{}} = Flights.delete_flight(flight)
      assert_raise Ecto.NoResultsError, fn -> Flights.get_flight!(flight.id) end
    end

    test "change_flight/1 returns a flight changeset" do
      flight = flight_fixture()
      assert %Ecto.Changeset{} = Flights.change_flight(flight)
    end
  end

  describe "seats" do
    alias AlbertAirline.Flights.Seat

    import AlbertAirline.FlightsFixtures

    @invalid_attrs %{label: nil, status: nil, seat_class: nil}

    test "list_seats/0 returns all seats" do
      seat = seat_fixture()
      assert Flights.list_seats() == [seat]
    end

    test "get_seat!/1 returns the seat with given id" do
      seat = seat_fixture()
      assert Flights.get_seat!(seat.id) == seat
    end

    test "create_seat/1 with valid data creates a seat" do
      flight = flight_fixture()

      valid_attrs = %{
        label: "some label",
        status: "available",
        seat_class: "economy",
        flight_id: flight.id
      }

      assert {:ok, %Seat{} = seat} = Flights.create_seat(valid_attrs)
      assert seat.label == "some label"
      assert seat.status == "available"
      assert seat.seat_class == "economy"
    end

    test "create_seat/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Flights.create_seat(@invalid_attrs)
    end

    test "update_seat/2 with valid data updates the seat" do
      seat = seat_fixture()
      update_attrs = %{label: "some updated label", status: "booked", seat_class: "business"}

      assert {:ok, %Seat{} = seat} = Flights.update_seat(seat, update_attrs)
      assert seat.label == "some updated label"
      assert seat.status == "booked"
      assert seat.seat_class == "business"
    end

    test "update_seat/2 with invalid data returns error changeset" do
      seat = seat_fixture()
      assert {:error, %Ecto.Changeset{}} = Flights.update_seat(seat, @invalid_attrs)
      assert seat == Flights.get_seat!(seat.id)
    end

    test "delete_seat/1 deletes the seat" do
      seat = seat_fixture()
      assert {:ok, %Seat{}} = Flights.delete_seat(seat)
      assert_raise Ecto.NoResultsError, fn -> Flights.get_seat!(seat.id) end
    end

    test "change_seat/1 returns a seat changeset" do
      seat = seat_fixture()
      assert %Ecto.Changeset{} = Flights.change_seat(seat)
    end
  end
end
