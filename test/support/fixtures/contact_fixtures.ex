defmodule AlbertAirline.ContactFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `AlbertAirline.Contact` context.
  """

  @doc """
  Generate a message.
  """
  def message_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        company_name: "Some Company",
        email: "someone#{System.unique_integer([:positive])}@example.com",
        first_name: "Some",
        last_name: "Body"
      })

    {:ok, message} = AlbertAirline.Contact.create_message(attrs)
    message
  end
end
