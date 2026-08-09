defmodule AlbertAirlineWeb.BookingController do
  use AlbertAirlineWeb, :controller

  @doc """
  Stripe Checkout's cancel_url. No Booking rows exist to clean up here —
  nothing is reserved until payment is confirmed, so there's nothing to
  release.
  """
  def cancelled(conn, _params) do
    conn
    |> put_flash(:info, "Checkout cancelled — your seats were not booked.")
    |> redirect(to: ~p"/search")
  end
end
