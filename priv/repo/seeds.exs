# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Seeds a small but realistic dataset: real airports/airlines (fixing the
# legacy mockup's fictional "YGN/LNH/Thai" terminal codes into proper IATA
# codes), a handful of flights across those routes with a mix of direct and
# one-stop options, and a full seat grid per flight (matching the original
# 10x10 mockup layout) with a few seats already booked so the seat map has
# something to show from the start.

alias AlbertAirline.Repo
alias AlbertAirline.Flights.{Airline, Airport, Flight, Seat}
alias AlbertAirline.Bookings.Booking

seat_rows = 1..10
seat_columns = ~w(A B C D E F G H I J)
business_rows = [1, 2]

airports =
  Enum.map(
    [
      %{
        iata_code: "YGN",
        name: "Yangon International Airport",
        city: "Yangon",
        country: "Myanmar"
      },
      %{
        iata_code: "LHR",
        name: "London Heathrow Airport",
        city: "London",
        country: "United Kingdom"
      },
      %{iata_code: "BKK", name: "Suvarnabhumi Airport", city: "Bangkok", country: "Thailand"}
    ],
    fn attrs ->
      {:ok, airport} = Repo.insert(Airport.changeset(%Airport{}, attrs))
      airport
    end
  )

[ygn, lhr, bkk] = airports

airlines =
  Enum.map(
    [
      %{name: "Albert Airline", code: "A8"},
      %{name: "KBZ International Airline", code: "K7"},
      %{name: "MAI International Airline", code: "MI"},
      %{name: "Thai Airways", code: "TG"}
    ],
    fn attrs ->
      {:ok, airline} = Repo.insert(Airline.changeset(%Airline{}, attrs))
      airline
    end
  )

[albert, kbz, mai, thai] = airlines

flight_specs = [
  %{
    flight_number: "A8-101",
    airline: albert,
    departure_airport: lhr,
    arrival_airport: ygn,
    departure_time: ~U[2026-09-01 21:25:00Z],
    arrival_time: ~U[2026-09-02 18:00:00Z],
    aircraft: "Boeing 777-300ER",
    base_price: "1217.00",
    stops: 1,
    already_booked_seats: ~w(1A 1B 3C 3D 5F)
  },
  %{
    flight_number: "A8-102",
    airline: albert,
    departure_airport: ygn,
    arrival_airport: lhr,
    departure_time: ~U[2026-09-05 19:00:00Z],
    arrival_time: ~U[2026-09-06 07:50:00Z],
    aircraft: "Boeing 777-300ER",
    base_price: "1104.02",
    stops: 1,
    already_booked_seats: ~w(2A 2B)
  },
  %{
    flight_number: "TG-220",
    airline: thai,
    departure_airport: bkk,
    arrival_airport: lhr,
    departure_time: ~U[2026-09-01 23:40:00Z],
    arrival_time: ~U[2026-09-02 06:15:00Z],
    aircraft: "Airbus A350-900",
    base_price: "980.00",
    stops: 0,
    already_booked_seats: ~w(1A 1C 1E)
  },
  %{
    flight_number: "K7-330",
    airline: kbz,
    departure_airport: ygn,
    arrival_airport: bkk,
    departure_time: ~U[2026-09-03 08:15:00Z],
    arrival_time: ~U[2026-09-03 10:05:00Z],
    aircraft: "Airbus A320",
    base_price: "215.00",
    stops: 0,
    already_booked_seats: []
  },
  %{
    flight_number: "MI-410",
    airline: mai,
    departure_airport: bkk,
    arrival_airport: ygn,
    departure_time: ~U[2026-09-04 14:30:00Z],
    arrival_time: ~U[2026-09-04 16:10:00Z],
    aircraft: "Airbus A319",
    base_price: "198.50",
    stops: 0,
    already_booked_seats: ~w(4B)
  },
  %{
    flight_number: "TG-221",
    airline: thai,
    departure_airport: lhr,
    arrival_airport: bkk,
    departure_time: ~U[2026-09-08 12:10:00Z],
    arrival_time: ~U[2026-09-09 07:35:00Z],
    aircraft: "Airbus A350-900",
    base_price: "945.00",
    stops: 1,
    already_booked_seats: ~w(1B 1D 6A 6B)
  }
]

Enum.each(flight_specs, fn spec ->
  {:ok, flight} =
    Repo.insert(
      Flight.changeset(%Flight{}, %{
        flight_number: spec.flight_number,
        airline_id: spec.airline.id,
        departure_airport_id: spec.departure_airport.id,
        arrival_airport_id: spec.arrival_airport.id,
        departure_time: spec.departure_time,
        arrival_time: spec.arrival_time,
        aircraft: spec.aircraft,
        base_price: spec.base_price,
        stops: spec.stops
      })
    )

  seats =
    for row <- seat_rows, column <- seat_columns do
      label = "#{row}#{column}"
      seat_class = if row in business_rows, do: "business", else: "economy"
      status = if label in spec.already_booked_seats, do: "booked", else: "available"

      {:ok, seat} =
        Repo.insert(
          Seat.changeset(%Seat{}, %{
            flight_id: flight.id,
            label: label,
            seat_class: seat_class,
            status: status
          })
        )

      seat
    end

  seats
  |> Enum.filter(&(&1.status == "booked"))
  |> Enum.each(fn seat ->
    {:ok, _booking} =
      Repo.insert(
        Booking.changeset(%Booking{}, %{
          seat_id: seat.id,
          flight_id: flight.id,
          status: "confirmed",
          total_price: spec.base_price,
          confirmation_code: "SEED-#{flight.flight_number}-#{seat.label}",
          booked_at: DateTime.add(spec.departure_time, -14, :day)
        })
      )
  end)
end)

IO.puts(
  "Seeded #{length(airports)} airports, #{length(airlines)} airlines, #{length(flight_specs)} flights with full seat grids."
)
