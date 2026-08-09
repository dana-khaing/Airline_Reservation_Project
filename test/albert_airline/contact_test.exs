defmodule AlbertAirline.ContactTest do
  use AlbertAirline.DataCase

  alias AlbertAirline.Contact

  describe "contact_messages" do
    alias AlbertAirline.Contact.Message

    import AlbertAirline.AccountsFixtures, only: [user_fixture: 0]
    import AlbertAirline.ContactFixtures

    @invalid_attrs %{first_name: nil, last_name: nil, company_name: nil, email: nil}

    test "list_contact_messages/0 returns messages newest first" do
      older = message_fixture()
      newer = message_fixture()
      assert Contact.list_contact_messages() == [newer, older]
    end

    test "create_message/1 with valid data creates a message, with no user required" do
      valid_attrs = %{
        first_name: "Jane",
        last_name: "Doe",
        company_name: "Acme",
        email: "jane@example.com"
      }

      assert {:ok, %Message{} = message} = Contact.create_message(valid_attrs)
      assert message.first_name == "Jane"
      assert message.last_name == "Doe"
      assert message.company_name == "Acme"
      assert message.email == "jane@example.com"
      assert message.user_id == nil
    end

    test "create_message/1 attributes to a logged-in user when given one", %{} do
      user = user_fixture()

      valid_attrs = %{
        first_name: "Jane",
        last_name: "Doe",
        email: "jane@example.com",
        user_id: user.id
      }

      assert {:ok, %Message{} = message} = Contact.create_message(valid_attrs)
      assert message.user_id == user.id
    end

    test "create_message/1 requires first name, last name, and email" do
      assert {:error, changeset} = Contact.create_message(@invalid_attrs)

      assert %{
               first_name: ["can't be blank"],
               last_name: ["can't be blank"],
               email: ["can't be blank"]
             } =
               errors_on(changeset)
    end

    test "create_message/1 rejects a malformed email" do
      assert {:error, changeset} =
               Contact.create_message(%{
                 first_name: "Jane",
                 last_name: "Doe",
                 email: "not-an-email"
               })

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "change_message/2 returns a message changeset" do
      message = message_fixture()
      assert %Ecto.Changeset{} = Contact.change_message(message)
    end
  end
end
