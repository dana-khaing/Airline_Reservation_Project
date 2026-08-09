ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(AlbertAirline.Repo, :manual)
{:ok, _pid} = AlbertAirline.Payments.StubClient.start_link([])
