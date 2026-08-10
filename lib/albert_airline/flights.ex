defmodule AlbertAirline.Flights do
  @moduledoc """
  The Flights context.
  """

  import Ecto.Query, warn: false
  alias AlbertAirline.Repo

  alias AlbertAirline.Flights.Airline

  @doc """
  Returns the list of airlines.

  ## Examples

      iex> list_airlines()
      [%Airline{}, ...]

  """
  def list_airlines do
    Repo.all(Airline)
  end

  @doc """
  Gets a single airline.

  Raises `Ecto.NoResultsError` if the Airline does not exist.

  ## Examples

      iex> get_airline!(123)
      %Airline{}

      iex> get_airline!(456)
      ** (Ecto.NoResultsError)

  """
  def get_airline!(id), do: Repo.get!(Airline, id)

  @doc """
  Creates a airline.

  ## Examples

      iex> create_airline(%{field: value})
      {:ok, %Airline{}}

      iex> create_airline(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_airline(attrs) do
    %Airline{}
    |> Airline.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a airline.

  ## Examples

      iex> update_airline(airline, %{field: new_value})
      {:ok, %Airline{}}

      iex> update_airline(airline, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_airline(%Airline{} = airline, attrs) do
    airline
    |> Airline.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a airline.

  ## Examples

      iex> delete_airline(airline)
      {:ok, %Airline{}}

      iex> delete_airline(airline)
      {:error, %Ecto.Changeset{}}

  """
  def delete_airline(%Airline{} = airline) do
    airline
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.no_assoc_constraint(:flights, name: :flights_airline_id_fkey)
    |> Repo.delete()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking airline changes.

  ## Examples

      iex> change_airline(airline)
      %Ecto.Changeset{data: %Airline{}}

  """
  def change_airline(%Airline{} = airline, attrs \\ %{}) do
    Airline.changeset(airline, attrs)
  end

  alias AlbertAirline.Flights.Airport

  @doc """
  Returns the list of airports.

  ## Examples

      iex> list_airports()
      [%Airport{}, ...]

  """
  def list_airports do
    Repo.all(Airport)
  end

  @doc """
  Gets a single airport.

  Raises `Ecto.NoResultsError` if the Airport does not exist.

  ## Examples

      iex> get_airport!(123)
      %Airport{}

      iex> get_airport!(456)
      ** (Ecto.NoResultsError)

  """
  def get_airport!(id), do: Repo.get!(Airport, id)

  @doc """
  Creates a airport.

  ## Examples

      iex> create_airport(%{field: value})
      {:ok, %Airport{}}

      iex> create_airport(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_airport(attrs) do
    %Airport{}
    |> Airport.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a airport.

  ## Examples

      iex> update_airport(airport, %{field: new_value})
      {:ok, %Airport{}}

      iex> update_airport(airport, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_airport(%Airport{} = airport, attrs) do
    airport
    |> Airport.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a airport.

  ## Examples

      iex> delete_airport(airport)
      {:ok, %Airport{}}

      iex> delete_airport(airport)
      {:error, %Ecto.Changeset{}}

  """
  def delete_airport(%Airport{} = airport) do
    airport
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.no_assoc_constraint(:departing_flights,
      name: :flights_departure_airport_id_fkey
    )
    |> Ecto.Changeset.no_assoc_constraint(:arriving_flights,
      name: :flights_arrival_airport_id_fkey
    )
    |> Repo.delete()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking airport changes.

  ## Examples

      iex> change_airport(airport)
      %Ecto.Changeset{data: %Airport{}}

  """
  def change_airport(%Airport{} = airport, attrs \\ %{}) do
    Airport.changeset(airport, attrs)
  end

  alias AlbertAirline.Flights.Flight

  @doc """
  Returns the list of flights.

  ## Examples

      iex> list_flights()
      [%Flight{}, ...]

  """
  def list_flights do
    Repo.all(Flight)
  end

  @doc """
  Gets a single flight.

  Raises `Ecto.NoResultsError` if the Flight does not exist.

  ## Examples

      iex> get_flight!(123)
      %Flight{}

      iex> get_flight!(456)
      ** (Ecto.NoResultsError)

  """
  def get_flight!(id), do: Repo.get!(Flight, id)

  @doc """
  Creates a flight.

  ## Examples

      iex> create_flight(%{field: value})
      {:ok, %Flight{}}

      iex> create_flight(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_flight(attrs) do
    %Flight{}
    |> Flight.changeset(attrs)
    |> Repo.insert()
  end

  @seat_rows 1..10
  @seat_columns ~w(A B C D E F G H I J)
  @business_rows [1, 2]

  @doc """
  The seat grid shape (row numbers, column letters, which rows are business
  class) used both by create_flight_with_seats/1 and by the seed script,
  which needs the same layout but finer control over individual seat
  status than that function exposes.
  """
  def seat_grid_layout do
    %{rows: @seat_rows, columns: @seat_columns, business_rows: @business_rows}
  end

  @doc """
  Creates a flight and generates its full 10x10 seat grid (rows 1-2
  business, rest economy) in one transaction — what the admin UI uses, so
  a newly created flight is immediately searchable and bookable instead of
  needing a separate manual seeding step.
  """
  def create_flight_with_seats(attrs) do
    Repo.transaction(fn ->
      with {:ok, flight} <- create_flight(attrs) do
        Enum.each(@seat_rows, fn row ->
          Enum.each(@seat_columns, fn column ->
            seat_class = if row in @business_rows, do: "business", else: "economy"

            case create_seat(%{
                   flight_id: flight.id,
                   label: "#{row}#{column}",
                   seat_class: seat_class,
                   status: "available"
                 }) do
              {:ok, _seat} -> :ok
              {:error, changeset} -> Repo.rollback(changeset)
            end
          end)
        end)

        flight
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Updates a flight.

  ## Examples

      iex> update_flight(flight, %{field: new_value})
      {:ok, %Flight{}}

      iex> update_flight(flight, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_flight(%Flight{} = flight, attrs) do
    flight
    |> Flight.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a flight.

  ## Examples

      iex> delete_flight(flight)
      {:ok, %Flight{}}

      iex> delete_flight(flight)
      {:error, %Ecto.Changeset{}}

  """
  def delete_flight(%Flight{} = flight) do
    flight
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.no_assoc_constraint(:bookings, name: :bookings_flight_id_fkey)
    |> Repo.delete()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking flight changes.

  ## Examples

      iex> change_flight(flight)
      %Ecto.Changeset{data: %Flight{}}

  """
  def change_flight(%Flight{} = flight, attrs \\ %{}) do
    Flight.changeset(flight, attrs)
  end

  alias AlbertAirline.Flights.Seat

  @doc """
  Returns the list of seats.

  ## Examples

      iex> list_seats()
      [%Seat{}, ...]

  """
  def list_seats do
    Repo.all(Seat)
  end

  @doc """
  Returns all seats for a flight, ordered for grid display (row, then column).
  """
  def list_seats_for_flight(flight_id) do
    Repo.all(from(s in Seat, where: s.flight_id == ^flight_id, order_by: [asc: s.id]))
  end

  @doc """
  Fetches multiple seats by id in a single query.
  """
  def get_seats(ids) do
    Repo.all(from(s in Seat, where: s.id in ^ids))
  end

  @doc """
  Gets a single seat.

  Raises `Ecto.NoResultsError` if the Seat does not exist.

  ## Examples

      iex> get_seat!(123)
      %Seat{}

      iex> get_seat!(456)
      ** (Ecto.NoResultsError)

  """
  def get_seat!(id), do: Repo.get!(Seat, id)

  @doc """
  Creates a seat.

  ## Examples

      iex> create_seat(%{field: value})
      {:ok, %Seat{}}

      iex> create_seat(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_seat(attrs) do
    %Seat{}
    |> Seat.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a seat.

  ## Examples

      iex> update_seat(seat, %{field: new_value})
      {:ok, %Seat{}}

      iex> update_seat(seat, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_seat(%Seat{} = seat, attrs) do
    seat
    |> Seat.changeset(attrs)
    |> Repo.update()
    |> broadcast_seat_change()
  end

  @doc """
  Deletes a seat.

  ## Examples

      iex> delete_seat(seat)
      {:ok, %Seat{}}

      iex> delete_seat(seat)
      {:error, %Ecto.Changeset{}}

  """
  def delete_seat(%Seat{} = seat) do
    Repo.delete(seat)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking seat changes.

  ## Examples

      iex> change_seat(seat)
      %Ecto.Changeset{data: %Seat{}}

  """
  def change_seat(%Seat{} = seat, attrs \\ %{}) do
    Seat.changeset(seat, attrs)
  end

  @doc """
  Searches flights by departure/arrival airport, date, stop count, airline,
  and minimum available seats. All criteria are optional — an empty
  criteria map returns every flight, soonest departure first.
  """
  def search_flights(criteria \\ %{}) do
    Flight
    |> maybe_filter_departure_airport(criteria[:departure_airport_id])
    |> maybe_filter_arrival_airport(criteria[:arrival_airport_id])
    |> maybe_filter_date(criteria[:date])
    |> maybe_filter_stops(criteria[:stops])
    |> maybe_filter_airlines(criteria[:airline_ids])
    |> maybe_filter_min_seats(criteria[:seats])
    |> order_by([f], asc: f.departure_time)
    |> preload([:airline, :departure_airport, :arrival_airport])
    |> Repo.all()
  end

  defp maybe_filter_departure_airport(query, id) when id in [nil, ""], do: query

  defp maybe_filter_departure_airport(query, id),
    do: from(f in query, where: f.departure_airport_id == ^id)

  defp maybe_filter_arrival_airport(query, id) when id in [nil, ""], do: query

  defp maybe_filter_arrival_airport(query, id),
    do: from(f in query, where: f.arrival_airport_id == ^id)

  defp maybe_filter_date(query, date) when date in [nil, ""], do: query

  defp maybe_filter_date(query, date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} ->
        starts_at = DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
        ends_at = DateTime.new!(date, ~T[23:59:59], "Etc/UTC")
        from(f in query, where: f.departure_time >= ^starts_at and f.departure_time <= ^ends_at)

      {:error, _reason} ->
        query
    end
  end

  defp maybe_filter_stops(query, categories) when categories in [nil, []], do: query

  defp maybe_filter_stops(query, categories) do
    exact_values =
      categories
      |> Enum.reject(&(&1 == "two_plus"))
      |> Enum.map(&stops_for_category/1)

    include_two_plus? = "two_plus" in categories

    cond do
      exact_values != [] and include_two_plus? ->
        from(f in query, where: f.stops in ^exact_values or f.stops >= 2)

      exact_values != [] ->
        from(f in query, where: f.stops in ^exact_values)

      include_two_plus? ->
        from(f in query, where: f.stops >= 2)

      true ->
        query
    end
  end

  defp stops_for_category("direct"), do: 0
  defp stops_for_category("one_stop"), do: 1

  defp maybe_filter_airlines(query, ids) when ids in [nil, []], do: query

  defp maybe_filter_airlines(query, ids), do: from(f in query, where: f.airline_id in ^ids)

  defp maybe_filter_min_seats(query, seats) when seats in [nil, ""], do: query

  defp maybe_filter_min_seats(query, seats) do
    case Integer.parse(to_string(seats)) do
      {n, _} when n > 1 ->
        from(f in query,
          where:
            fragment(
              "(SELECT count(*) FROM seats WHERE seats.flight_id = ? AND seats.status = 'available') >= ?",
              f.id,
              ^n
            )
        )

      _ ->
        query
    end
  end

  @doc """
  Counts available (unbooked) seats for a flight.
  """
  def available_seat_count(flight_id) do
    Repo.aggregate(
      from(s in Seat, where: s.flight_id == ^flight_id and s.status == "available"),
      :count
    )
  end

  @doc """
  Subscribes the calling process to live seat-status updates for a flight.
  Broadcasts a `{:seat_updated, seat}` message whenever any seat on this
  flight changes (e.g. a booking claims it, or a cancellation frees it up).
  """
  def subscribe_to_seats(flight_id) do
    Phoenix.PubSub.subscribe(AlbertAirline.PubSub, seat_topic(flight_id))
  end

  @doc """
  Broadcasts that a seat's status changed, without performing the update
  itself. For callers (like the booking transaction) that update a seat as
  part of a larger multi-step transaction and only want to notify watchers
  after that transaction has actually committed.
  """
  def broadcast_seat_updated(%Seat{} = seat) do
    Phoenix.PubSub.broadcast(
      AlbertAirline.PubSub,
      seat_topic(seat.flight_id),
      {:seat_updated, seat}
    )

    seat
  end

  defp seat_topic(flight_id), do: "flight:#{flight_id}:seats"

  defp broadcast_seat_change({:ok, %Seat{} = seat} = result) do
    Phoenix.PubSub.broadcast(
      AlbertAirline.PubSub,
      seat_topic(seat.flight_id),
      {:seat_updated, seat}
    )

    result
  end

  defp broadcast_seat_change(result), do: result
end
