defmodule AlbertAirlineWeb.FlightLive.Helpers do
  @moduledoc """
  Display helpers shared between the flight-search and flight-detail
  LiveViews.
  """

  @doc """
  Renders a flight's stop count as the label the UI shows next to it.
  """
  def stops_label(0), do: "Direct"
  def stops_label(1), do: "1 Connection"
  def stops_label(n), do: "#{n} Connections"
end
