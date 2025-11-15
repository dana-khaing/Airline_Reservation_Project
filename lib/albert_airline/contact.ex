defmodule AlbertAirline.Contact do
  @moduledoc """
  The Contact context. The contact form is public — no login required to
  submit — so, unlike most of this app's resources, this context is not
  scoped to a `AlbertAirline.Accounts.Scope`. A submission is attributed to
  a user only incidentally, if one happens to be logged in when they submit.
  """

  import Ecto.Query, warn: false
  alias AlbertAirline.Repo

  alias AlbertAirline.Contact.Message

  @doc """
  Returns the list of contact messages, most recent first. For the future
  admin interface.
  """
  def list_contact_messages do
    Repo.all(from(m in Message, order_by: [desc: m.inserted_at, desc: m.id]))
  end

  @doc """
  Creates a contact message.

  ## Examples

      iex> create_message(%{field: value})
      {:ok, %Message{}}

      iex> create_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.
  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end
end
