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

  test "the shared layout has a skip link and a main landmark for keyboard/screen-reader users",
       %{
         conn: conn
       } do
    html = get(conn, ~p"/") |> html_response(200)

    assert html =~ ~s(href="#main-content")
    assert html =~ ~s(id="main-content")
  end
end
