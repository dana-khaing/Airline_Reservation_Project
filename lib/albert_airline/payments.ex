defmodule AlbertAirline.Payments do
  @moduledoc """
  Payment provider access, dispatched to whichever adapter is configured
  under `:albert_airline, :payments_adapter` (the real Stripe client in
  dev/prod, a stub in test — see `AlbertAirline.Payments.Adapter`).
  """

  @doc "Creates a hosted checkout session for the given amount/metadata."
  def create_checkout_session(params), do: adapter().create_checkout_session(params)

  @doc "Looks up a checkout session's payment status and metadata."
  def retrieve_checkout_session(session_id), do: adapter().retrieve_checkout_session(session_id)

  @doc "Refunds a completed payment by its payment intent id."
  def refund(payment_intent_id), do: adapter().refund(payment_intent_id)

  defp adapter,
    do:
      Application.get_env(:albert_airline, :payments_adapter, AlbertAirline.Payments.StripeClient)
end
