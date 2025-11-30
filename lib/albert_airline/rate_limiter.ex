defmodule AlbertAirline.RateLimiter do
  @moduledoc """
  Rate limiter for public, unauthenticated actions that either check a
  password or trigger an outgoing email — password login, magic-link
  requests, registration, and the contact form. Backed by an in-memory
  ETS table (per-node; fine at this app's current single-node scale).
  """

  use Hammer, backend: :ets

  @doc """
  Checks and increments the counter for `key` within `scale_ms`, allowing
  up to `limit` hits. Returns `:ok` or `{:error, :rate_limited}`.

  Disabled by default in :test (see config/test.exs) — otherwise unrelated
  tests sharing one conn.remote_ip/peer IP would trip each other's limits
  during a fast automated run. Override per-test with
  `Application.put_env(:albert_airline, AlbertAirline.RateLimiter, enabled: true)`
  (see the dedicated test in rate_limiter_test.exs) to test the mechanism
  itself.
  """
  def check(key, scale_ms, limit) do
    if enabled?() do
      case hit(key, scale_ms, limit) do
        {:allow, _count} -> :ok
        {:deny, _retry_after_ms} -> {:error, :rate_limited}
      end
    else
      :ok
    end
  end

  defp enabled? do
    Keyword.get(Application.get_env(:albert_airline, __MODULE__, []), :enabled, true)
  end
end
