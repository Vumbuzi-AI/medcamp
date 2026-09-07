ExUnit.start()
{:ok, _pid} = Medcamp.Postal.TestClient.start_link()
Ecto.Adapters.SQL.Sandbox.mode(Medcamp.Repo, :manual)
