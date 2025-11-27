defmodule AlbertAirlineWeb.PageController do
  use AlbertAirlineWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def about(conn, _params) do
    render(conn, :about)
  end

  def terms(conn, _params) do
    render(conn, :terms)
  end

  def privacy(conn, _params) do
    render(conn, :privacy)
  end

  def refund_policy(conn, _params) do
    render(conn, :refund_policy)
  end
end
