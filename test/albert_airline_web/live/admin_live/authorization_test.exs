defmodule AlbertAirlineWeb.AdminLive.AuthorizationTest do
  use AlbertAirlineWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import AlbertAirline.AccountsFixtures

  @admin_paths ~w(/admin /admin/airports /admin/airlines /admin/flights)

  test "logged-out visitors are redirected away from every admin page", %{conn: conn} do
    for path <- @admin_paths do
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, path)
    end
  end

  test "logged-in non-admins are redirected away from every admin page", %{conn: conn} do
    conn = log_in_user(conn, user_fixture())

    for path <- @admin_paths do
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, path)
    end
  end

  test "admins can reach every admin page", %{conn: conn} do
    conn = log_in_user(conn, admin_user_fixture())

    for path <- @admin_paths do
      assert {:ok, _lv, _html} = live(conn, path)
    end
  end
end
