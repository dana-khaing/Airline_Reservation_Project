defmodule AlbertAirlineWeb.RateLimit do
  @moduledoc """
  LiveView-facing wrapper around `AlbertAirline.RateLimiter`, for public
  actions handled entirely as socket events (magic-link requests,
  registration, the contact form) — these never reach a Plug pipeline,
  so a router-level plug can't cover them the way it covers a plain HTTP
  POST like `/users/log-in`.
  """

  import Phoenix.LiveView, only: [get_connect_info: 2]
  import Phoenix.Component, only: [assign: 3]

  @doc """
  Assigns the connecting client's IP (as a string, or "unknown" if peer
  data isn't available) to `:client_ip`. `get_connect_info/2` only works
  during `mount/3` — call this there and read `socket.assigns.client_ip`
  later, e.g. from `handle_event/3`, where connect_info is no longer
  available.
  """
  def assign_client_ip(socket) do
    ip =
      case get_connect_info(socket, :peer_data) do
        %{address: address} -> address |> :inet.ntoa() |> to_string()
        _ -> "unknown"
      end

    assign(socket, :client_ip, ip)
  end

  @doc "Checks and increments the counter for `key`. See `AlbertAirline.RateLimiter.check/3`."
  defdelegate check(key, scale_ms, limit), to: AlbertAirline.RateLimiter
end
