defmodule AlbertAirline.Payments.Adapter do
  @moduledoc """
  Behaviour for a payment provider capable of hosted checkout, session
  lookup, and refunds. `AlbertAirline.Payments.StripeClient` is the real
  implementation; tests use a stub adapter configured via
  `:albert_airline, :payments_adapter` so no test ever calls out to Stripe.
  """

  @type checkout_params :: %{
          required(:amount) => Decimal.t(),
          required(:description) => String.t(),
          required(:success_url) => String.t(),
          required(:cancel_url) => String.t(),
          required(:metadata) => %{String.t() => String.t()}
        }

  @type session :: %{
          payment_status: String.t(),
          payment_intent: String.t() | nil,
          metadata: %{String.t() => String.t()}
        }

  @callback create_checkout_session(checkout_params()) ::
              {:ok, %{id: String.t(), url: String.t()}} | {:error, term()}
  @callback retrieve_checkout_session(session_id :: String.t()) ::
              {:ok, session()} | {:error, term()}
  @doc """
  Refunds a payment. `amount` nil refunds the full original payment (used
  when an entire order fails, e.g. a seat conflict during checkout);
  a `Decimal` amount issues a partial refund (used for cancelling one
  booking out of a multi-seat order).
  """
  @callback refund(payment_intent_id :: String.t(), amount :: Decimal.t() | nil) ::
              {:ok, map()} | {:error, term()}
end
