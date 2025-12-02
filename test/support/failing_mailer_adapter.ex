defmodule AlbertAirline.FailingMailerAdapter do
  @moduledoc """
  Test-only Swoosh adapter that always fails delivery, for testing the
  {:error, reason} handling in code that calls Mailer.deliver — normal
  test config uses Swoosh.Adapters.Test, which always succeeds and has
  no way to simulate a delivery failure.
  """

  use Swoosh.Adapter

  def deliver(_email, _config), do: {:error, :simulated_mail_failure}
end
