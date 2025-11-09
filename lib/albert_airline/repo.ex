defmodule AlbertAirline.Repo do
  use Ecto.Repo,
    otp_app: :albert_airline,
    adapter: Ecto.Adapters.Postgres
end
