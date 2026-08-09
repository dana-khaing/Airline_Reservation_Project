defmodule AlbertAirlineWeb.PageControllerTest do
  use AlbertAirlineWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "LET'S FLY TOGETHER"
  end

  test "GET /about", %{conn: conn} do
    conn = get(conn, ~p"/about")
    assert html_response(conn, 200) =~ "ABOUT US"
  end
end
