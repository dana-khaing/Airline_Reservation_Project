defmodule AlbertAirlineWeb.FlightStatusComponents do
  @moduledoc """
  Renders a live Aviationstack flight-status lookup (see
  `AlbertAirline.FlightStatus`) as a small `.albert-card` panel: loading,
  found (status badge + delay + gate), not-found ("no live match" — the
  expected outcome for this app's mostly-fictional demo flight numbers),
  or error.
  """
  use Phoenix.Component

  attr :status, Phoenix.LiveView.AsyncResult, required: true
  attr :class, :any, default: nil

  def flight_status(assigns) do
    assigns =
      assigns
      |> assign(:state, classify(assigns.status))
      |> assign(:found, found_status(assigns.status))

    ~H"""
    <div class={["albert-card", @class]}>
      <h4 class="font-semibold">Live flight status</h4>

      <p :if={@state == :loading} class="mt-2 text-sm text-black/60">
        Checking live status…
      </p>

      <p :if={@state in [:not_found, :error]} class="mt-2 text-sm text-black/60">
        Live tracking unavailable for this flight.
      </p>

      <div :if={@state == :found} class="mt-2">
        <span class={[
          "inline-block rounded-full px-3 py-1 text-xs font-semibold",
          status_badge_class(@found.status)
        ]}>
          {String.capitalize(@found.status || "unknown")}
        </span>
        <p :if={@found.departure_gate} class="mt-2 text-sm">
          Gate: <span class="font-semibold">{@found.departure_gate}</span>
        </p>
        <p :if={@found.departure_delay_minutes} class="mt-1 text-sm">
          Delayed {@found.departure_delay_minutes} min
        </p>
      </div>
    </div>
    """
  end

  defp classify(%{loading: loading}) when not is_nil(loading), do: :loading
  defp classify(%{failed: failed}) when not is_nil(failed), do: :error
  defp classify(%{ok?: true, result: {:ok, _status}}), do: :found
  defp classify(%{ok?: true, result: {:error, :not_found}}), do: :not_found
  defp classify(%{ok?: true, result: {:error, _reason}}), do: :error
  defp classify(_async_result), do: :loading

  defp found_status(%{ok?: true, result: {:ok, status}}), do: status
  defp found_status(_async_result), do: nil

  defp status_badge_class("landed"), do: "bg-green-100 text-green-800"
  defp status_badge_class("active"), do: "bg-blue-100 text-blue-800"
  defp status_badge_class("scheduled"), do: "bg-gray-100 text-gray-800"
  defp status_badge_class("cancelled"), do: "bg-red-100 text-red-800"
  defp status_badge_class("diverted"), do: "bg-yellow-100 text-yellow-800"
  defp status_badge_class(_status), do: "bg-gray-100 text-gray-800"
end
