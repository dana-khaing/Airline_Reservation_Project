defmodule AlbertAirline.Mailer do
  use Swoosh.Mailer, otp_app: :albert_airline

  @doc """
  Builds and delivers a plain-text email. Shared by
  `Accounts.UserNotifier` and `Bookings.BookingNotifier`, which had each
  grown an identical private `deliver/3` differing only in their sender
  tuple (and, before this, had already drifted — one sent as
  "AlbertAirline", the other "Albert Airline").
  """
  def deliver_text_email(from, recipient, subject, body) do
    email =
      Swoosh.Email.new()
      |> Swoosh.Email.to(recipient)
      |> Swoosh.Email.from(from)
      |> Swoosh.Email.subject(subject)
      |> Swoosh.Email.text_body(body)

    with {:ok, _metadata} <- deliver(email) do
      {:ok, email}
    end
  end
end
