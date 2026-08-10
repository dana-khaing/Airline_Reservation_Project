defmodule AlbertAirlineWeb.FlightLive.Helpers do
  @moduledoc """
  Display helpers shared across flight-related LiveViews (search,
  flight-detail, and the admin flight form).
  """

  @doc """
  Renders a flight's stop count as the label the UI shows next to it.
  """
  def stops_label(0), do: "Direct"
  def stops_label(1), do: "1 Connection"
  def stops_label(n), do: "#{n} Connections"

  @doc """
  Builds `<.input type="select">` options from a list of airports, labeled
  by IATA code and name.
  """
  def airport_options(airports) do
    Enum.map(airports, fn a -> {"#{a.iata_code} — #{a.name}", a.id} end)
  end
end
