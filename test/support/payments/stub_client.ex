defmodule AlbertAirline.Payments.StubClient do
  @moduledoc """
  Test-only payment adapter: no network calls. Simulates a successful
  Stripe checkout by default; pass `metadata: %{"simulate_unpaid" => "true"}`
  to a checkout call to simulate an abandoned/incomplete payment instead.
  """

  @behaviour AlbertAirline.Payments.Adapter

  use Agent

  def start_link(_opts),
    do: Agent.start_link(fn -> %{sessions: %{}, refunds: []} end, name: __MODULE__)

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

    Agent.update(__MODULE__, &put_in(&1, [:sessions, id], session))

    {:ok, %{id: id, url: "https://stripe.test/checkout/#{id}"}}
  end

  @impl true
  def retrieve_checkout_session(session_id) do
    case Agent.get(__MODULE__, &get_in(&1, [:sessions, session_id])) do
      nil -> {:error, :not_found}
      session -> {:ok, session}
    end
  end

  @impl true
  def refund(payment_intent_id, amount) do
    Agent.update(__MODULE__, fn state ->
      update_in(
        state,
        [:refunds],
        &[%{payment_intent_id: payment_intent_id, amount: amount} | &1]
      )
    end)

    if payment_intent_id == "pi_test_simulate_refund_failure" do
      {:error, :simulated_failure}
    else
      {:ok, %{"status" => "succeeded"}}
    end
  end

  @doc "All refunds issued so far, most recent first — for asserting on in tests."
  def refunds do
    Agent.get(__MODULE__, & &1.refunds)
  end
end
