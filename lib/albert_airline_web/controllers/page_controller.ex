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

  def login(conn, _params) do
    render(conn, :coming_soon,
      title: "Log in",
      message: "Account sign-in is being built next — check back soon."
    )
  end

  def signup(conn, _params) do
    render(conn, :coming_soon,
      title: "Sign up",
      message: "New account creation is being built next — check back soon."
    )
  end

  def search(conn, _params) do
    render(conn, :coming_soon,
      title: "Flight Search",
      message: "Flight search is being built next — check back soon."
    )
  end
end
