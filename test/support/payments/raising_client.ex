defmodule AlbertAirline.Payments.RaisingClient do
  @moduledoc """
  Test-only payment adapter that always raises, simulating what
  `AlbertAirline.Payments.StripeClient` does when `STRIPE_SECRET_KEY` is
  unset. Used to prove `AlbertAirline.Bookings.start_checkout/5` and
  `confirm_from_stripe_session/1` convert that into `{:error, _}` instead
  of crashing the caller, via the `rescue` clauses on both.
  """

  @behaviour AlbertAirline.Payments.Adapter

  @impl true
  def create_checkout_session(_params), do: raise("simulated Payments failure")

  @impl true
  def retrieve_checkout_session(_session_id), do: raise("simulated Payments failure")

  @impl true
  def refund(_payment_intent_id, _amount), do: raise("simulated Payments failure")
end
