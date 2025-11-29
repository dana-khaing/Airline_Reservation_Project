defmodule AlbertAirline.SentryFinchHTTPClient do
  @moduledoc """
  Sentry's default HTTP client needs :hackney, and the rest of this app
  already standardizes on Req/Finch (see Payments.StripeClient) — this
  gives Sentry its own Finch pool instead of adding a second HTTP client
  library. Started under Sentry's own supervision tree via child_spec/0.
  """

  @behaviour Sentry.HTTPClient

  @impl true
  def child_spec do
    Supervisor.child_spec({Finch, name: __MODULE__}, id: __MODULE__)
  end

  @impl true
  def post(url, headers, body) do
    request = Finch.build(:post, url, headers, body)

    case Finch.request(request, __MODULE__) do
      {:ok, %Finch.Response{status: status, headers: headers, body: body}} ->
        {:ok, status, headers, body}

      {:error, error} ->
        {:error, error}
    end
  end
end
