defmodule AlbertAirline.Payments.StripeClientTest do
  @moduledoc """
  StripeClient makes real HTTP calls to api.stripe.com and is not exercised
  end to end here (no live Stripe credentials are available in this
  environment — see the adapter's own moduledoc). This covers the one
  piece of its behavior that's both real and testable without a network
  call: refusing to proceed when STRIPE_SECRET_KEY isn't configured,
  rather than silently sending an unauthenticated request.
  """

  use ExUnit.Case, async: false

  alias AlbertAirline.Payments.StripeClient

  setup do
    previous = Application.get_env(:albert_airline, :stripe_secret_key)
    Application.put_env(:albert_airline, :stripe_secret_key, nil)

    on_exit(fn ->
      Application.put_env(:albert_airline, :stripe_secret_key, previous)
    end)
  end

  test "create_checkout_session/1 raises a clear error when no secret key is configured" do
    assert_raise RuntimeError, ~r/STRIPE_SECRET_KEY is not configured/, fn ->
      StripeClient.create_checkout_session(%{
        amount: Decimal.new("100.00"),
        description: "test",
        success_url: "https://example.com/ok",
        cancel_url: "https://example.com/cancel",
        metadata: %{}
      })
    end
  end
end
