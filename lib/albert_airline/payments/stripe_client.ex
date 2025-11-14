defmodule AlbertAirline.Payments.StripeClient do
  @moduledoc """
  Real Stripe adapter, calling the REST API directly with Req (per this
  project's convention of using Req rather than a vendored SDK).

  Requires `STRIPE_SECRET_KEY` (a test-mode secret key, `sk_test_...`) to be
  set in the environment. Get one from https://dashboard.stripe.com/test/apikeys
  after creating a free Stripe account — this integration was built and
  tested against the stub adapter (see `AlbertAirline.Payments.StubClient`)
  since no live Stripe credentials are available in this environment; it
  has not yet been exercised against the real Stripe API.
  """

  @behaviour AlbertAirline.Payments.Adapter

  @base_url "https://api.stripe.com/v1"

  @impl true
  def create_checkout_session(params) do
    cents =
      params.amount
      |> Decimal.mult(Decimal.new(100))
      |> Decimal.round(0)
      |> Decimal.to_integer()

    body =
      %{
        "mode" => "payment",
        "success_url" => params.success_url,
        "cancel_url" => params.cancel_url,
        "line_items[0][quantity]" => "1",
        "line_items[0][price_data][currency]" => "usd",
        "line_items[0][price_data][unit_amount]" => to_string(cents),
        "line_items[0][price_data][product_data][name]" => params.description
      }
      |> Map.merge(metadata_params(params.metadata))

    "#{@base_url}/checkout/sessions"
    |> Req.post(form: body, auth: {:bearer, secret_key()})
    |> handle_response(fn body -> %{id: body["id"], url: body["url"]} end)
  end

  @impl true
  def retrieve_checkout_session(session_id) do
    "#{@base_url}/checkout/sessions/#{session_id}"
    |> Req.get(auth: {:bearer, secret_key()})
    |> handle_response(fn body ->
      %{
        payment_status: body["payment_status"],
        payment_intent: body["payment_intent"],
        metadata: body["metadata"] || %{}
      }
    end)
  end

  @impl true
  def refund(payment_intent_id) do
    "#{@base_url}/refunds"
    |> Req.post(form: %{"payment_intent" => payment_intent_id}, auth: {:bearer, secret_key()})
    |> handle_response(& &1)
  end

  defp handle_response({:ok, %{status: status, body: body}}, transform) when status in 200..299,
    do: {:ok, transform.(body)}

  defp handle_response({:ok, %{status: status, body: body}}, _transform),
    do: {:error, {:stripe_error, status, body}}

  defp handle_response({:error, reason}, _transform), do: {:error, reason}

  defp metadata_params(metadata) do
    Map.new(metadata, fn {k, v} -> {"metadata[#{k}]", v} end)
  end

  defp secret_key do
    Application.get_env(:albert_airline, :stripe_secret_key) ||
      raise """
      STRIPE_SECRET_KEY is not configured. Set it in the environment (a Stripe \
      test-mode secret key, sk_test_...) before the booking/payment flow can \
      create real Stripe checkout sessions.
      """
  end
end
