defmodule AlbertAirline.RateLimiterTest do
  @moduledoc """
  Rate limiting is off by default in :test (see config/test.exs) so
  unrelated async tests sharing one conn/peer IP don't trip each other's
  limits. This module flips it on for the duration of each test to prove
  the mechanism itself works, so it must run async: false — enabling it
  mutates global application config that other, concurrently-running
  async tests could otherwise be affected by.
  """

  use ExUnit.Case, async: false

  alias AlbertAirline.RateLimiter

  setup do
    Application.put_env(:albert_airline, RateLimiter, enabled: true)
    on_exit(fn -> Application.put_env(:albert_airline, RateLimiter, enabled: false) end)
  end

  test "allows up to the limit, then denies further hits within the same window" do
    key = "test:#{System.unique_integer([:positive])}"

    assert :ok = RateLimiter.check(key, :timer.minutes(1), 3)
    assert :ok = RateLimiter.check(key, :timer.minutes(1), 3)
    assert :ok = RateLimiter.check(key, :timer.minutes(1), 3)
    assert {:error, :rate_limited} = RateLimiter.check(key, :timer.minutes(1), 3)
  end

  test "different keys have independent limits" do
    key_a = "test:#{System.unique_integer([:positive])}"
    key_b = "test:#{System.unique_integer([:positive])}"

    assert :ok = RateLimiter.check(key_a, :timer.minutes(1), 1)
    assert {:error, :rate_limited} = RateLimiter.check(key_a, :timer.minutes(1), 1)
    assert :ok = RateLimiter.check(key_b, :timer.minutes(1), 1)
  end

  test "does nothing (always :ok) when disabled" do
    Application.put_env(:albert_airline, RateLimiter, enabled: false)
    key = "test:#{System.unique_integer([:positive])}"

    assert :ok = RateLimiter.check(key, :timer.minutes(1), 1)
    assert :ok = RateLimiter.check(key, :timer.minutes(1), 1)
  end
end
