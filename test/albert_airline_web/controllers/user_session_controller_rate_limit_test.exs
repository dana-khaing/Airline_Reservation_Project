defmodule AlbertAirlineWeb.UserSessionControllerRateLimitTest do
  @moduledoc """
  Separate, non-async module from UserSessionControllerTest: proving the
  rate-limit plug on POST /users/log-in actually blocks means enabling
  AlbertAirline.RateLimiter (off by default in :test), which mutates
  global application config that other, concurrently-running async tests
  could otherwise be affected by.
  """

  use AlbertAirlineWeb.ConnCase, async: false

  import AlbertAirline.AccountsFixtures

  alias AlbertAirline.RateLimiter

  setup do
    Application.put_env(:albert_airline, RateLimiter, enabled: true)
    on_exit(fn -> Application.put_env(:albert_airline, RateLimiter, enabled: false) end)

    %{user: user_fixture() |> set_password()}
  end

  test "blocks further login attempts from the same IP after the limit is exceeded", %{
    conn: conn,
    user: user
  } do
    attempt = fn conn ->
      post(conn, ~p"/users/log-in", %{
        "user" => %{"email" => user.email, "password" => "wrong password"}
      })
    end

    responses = for _ <- 1..10, do: attempt.(conn)
    assert Enum.all?(responses, &(Phoenix.Flash.get(&1.assigns.flash, :error) != nil))

    blocked_conn = attempt.(conn)

    assert Phoenix.Flash.get(blocked_conn.assigns.flash, :error) ==
             "Too many login attempts. Please wait a moment and try again."

    # a correct password doesn't bypass the block once it's tripped
    blocked_conn =
      post(conn, ~p"/users/log-in", %{
        "user" => %{"email" => user.email, "password" => valid_user_password()}
      })

    refute get_session(blocked_conn, :user_token)
  end
end
