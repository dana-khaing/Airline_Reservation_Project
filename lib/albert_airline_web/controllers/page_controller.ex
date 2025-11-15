defmodule AlbertAirlineWeb.PageController do
  use AlbertAirlineWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def about(conn, _params) do
    render(conn, :about)
  end
end
