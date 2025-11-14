defmodule AlbertAirline.Payments.StubClient do
  @moduledoc """
  Test-only payment adapter: no network calls. Simulates a successful
  Stripe checkout by default; pass `metadata: %{"simulate_unpaid" => "true"}`
  to a checkout call to simulate an abandoned/incomplete payment instead.
  """

  @behaviour AlbertAirline.Payments.Adapter

  use Agent

  def start_link(_opts), do: Agent.start_link(fn -> %{} end, name: __MODULE__)

  @impl true
  def create_checkout_session(params) do
    id = "cs_test_#{System.unique_integer([:positive])}"

    payment_status =
      if Map.get(params.metadata, "simulate_unpaid") == "true", do: "unpaid", else: "paid"

    session = %{
      payment_status: payment_status,
      payment_intent: "pi_test_#{System.unique_integer([:positive])}",
      metadata: params.metadata
    }

    Agent.update(__MODULE__, &Map.put(&1, id, session))

    {:ok, %{id: id, url: "https://stripe.test/checkout/#{id}"}}
  end

  @impl true
  def retrieve_checkout_session(session_id) do
    case Agent.get(__MODULE__, &Map.get(&1, session_id)) do
      nil -> {:error, :not_found}
      session -> {:ok, session}
    end
  end

  @impl true
  def refund(_payment_intent_id), do: {:ok, %{"status" => "succeeded"}}
end
