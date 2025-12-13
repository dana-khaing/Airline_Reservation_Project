defmodule AlbertAirlineWeb.ContactLive.NewTest do
  use AlbertAirlineWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import AlbertAirline.AccountsFixtures

  alias AlbertAirline.Contact

  test "submitting valid details persists a message and shows a success flash", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/contact")

    html =
      lv
      |> form("#contact-form", %{
        "message" => %{
          "first_name" => "Jane",
          "last_name" => "Doe",
          "company_name" => "Acme",
          "email" => "jane@example.com",
          "message" => "I'd like to ask about group bookings."
        }
      })
      |> render_submit()

    assert html =~ "Thanks for reaching out"
    assert [message] = Contact.list_contact_messages()
    assert message.first_name == "Jane"
    assert message.email == "jane@example.com"
    assert message.message == "I'd like to ask about group bookings."
    assert message.user_id == nil
  end

  test "submitting without logging in requires no account", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/contact")

    lv
    |> form("#contact-form", %{
      "message" => %{
        "first_name" => "Anon",
        "last_name" => "Ymous",
        "email" => "anon@example.com",
        "message" => "Hello there."
      }
    })
    |> render_submit()

    assert [message] = Contact.list_contact_messages()
    assert message.user_id == nil
  end

  test "attributes the message to a logged-in user", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)

    {:ok, lv, _html} = live(conn, ~p"/contact")

    lv
    |> form("#contact-form", %{
      "message" => %{
        "first_name" => "Log",
        "last_name" => "GedIn",
        "email" => "loggedin@example.com",
        "message" => "Hello there."
      }
    })
    |> render_submit()

    assert [message] = Contact.list_contact_messages()
    assert message.user_id == user.id
  end

  test "ignores a spoofed user_id from an unauthenticated visitor", %{conn: conn} do
    victim = user_fixture()
    {:ok, lv, _html} = live(conn, ~p"/contact")

    # A real form submit can't carry a `user_id` field since none is
    # rendered, so this bypasses `form/3` and sends the "save" event
    # directly — the way a manipulated socket payload would.
    render_submit(lv, "save", %{
      "message" => %{
        "first_name" => "Anon",
        "last_name" => "Ymous",
        "email" => "anon@example.com",
        "message" => "Hello there.",
        "user_id" => to_string(victim.id)
      }
    })

    assert [message] = Contact.list_contact_messages()
    assert message.user_id == nil
  end

  test "shows inline validation errors and does not persist invalid data", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/contact")

    html =
      lv
      |> form("#contact-form", %{"message" => %{"first_name" => "", "email" => "not-an-email"}})
      |> render_change()

    assert html =~ "can&#39;t be blank"
    assert html =~ "must have the @ sign"
    assert Contact.list_contact_messages() == []
  end
end
