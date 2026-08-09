defmodule AlbertAirlineWeb.PageController do
  use AlbertAirlineWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def about(conn, _params) do
    render(conn, :about)
  end

  def contact(conn, _params) do
    render(conn, :contact)
  end

  def search(conn, _params) do
    render(conn, :coming_soon,
      title: "Flight Search",
      message: "Flight search is being built next — check back soon."
    )
  end
end
