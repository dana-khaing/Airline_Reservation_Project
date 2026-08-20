defmodule AlbertAirline.FlightStatus.Cache do
  @moduledoc """
  Simple ETS-backed cache for Aviationstack lookups, keyed by
  `{flight_iata, date}`, so N concurrently-connected viewers of the same
  flight's status panel don't each burn a separate call against the
  free-tier Aviationstack quota. Entries live for 60 seconds.

  The table is public and read/written directly by callers (similar in
  spirit to `AlbertAirline.RateLimiter`'s Hammer-backed ETS table) rather
  than serialized through this GenServer — it only owns the table's
  lifecycle. Two callers racing on the exact same expired key at the same
  moment will both call the adapter and both write the result; harmless
  (last write wins) and simpler than a per-key lock, which isn't worth it
  at this app's scale.
  """

  use GenServer

  @table __MODULE__
  @ttl_ms :timer.seconds(60)

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    :ets.new(@table, [:named_table, :public, :set, read_concurrency: true])
    {:ok, %{}}
  end

  @doc """
  Returns the cached value for `key` if younger than the TTL, otherwise
  calls `fun.()`, caches a successful (`{:ok, _}`) result, and returns it.
  Error results are not cached, so a transient failure doesn't get "stuck"
  for a full TTL window.
  """
  def fetch(key, fun) do
    case :ets.lookup(@table, key) do
      [{^key, value, inserted_at}] -> if fresh?(inserted_at), do: value, else: refresh(key, fun)
      [] -> refresh(key, fun)
    end
  end

  defp refresh(key, fun) do
    value = fun.()
    if match?({:ok, _}, value), do: :ets.insert(@table, {key, value, now()})
    value
  end

  defp fresh?(inserted_at), do: now() - inserted_at < @ttl_ms
  defp now, do: System.monotonic_time(:millisecond)
end
