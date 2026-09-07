defmodule Medcamp.Postal.TestClient do
  @moduledoc """
  Fake HTTP client for Medcamp.Postal — configured permanently in
  config/test.exs (see :http_client) so tests never hit the real Postal
  API. Started once for the whole suite (test/test_helper.exs). Calls
  are tagged by originating test process via $callers and filtered
  per-test, so this stays safe under async: true.
  """

  use Agent

  def start_link(_opts \\ []) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def post(url, body, headers) do
    origin = origin_pid()
    Agent.update(__MODULE__, fn calls -> [{origin, url, body, headers} | calls] end)
    {:ok, %Finch.Response{status: 200, body: Jason.encode!(%{"id" => "test-message-id"})}}
  end

  @doc "Returns calls made by the calling test (or a given pid), most recent first."
  def calls(for_pid \\ self()) do
    Agent.get(__MODULE__, fn calls ->
      calls
      |> Enum.filter(fn {origin, _, _, _} -> origin == for_pid end)
      |> Enum.map(fn {_origin, url, body, headers} -> {url, body, headers} end)
    end)
  end

  defp origin_pid do
    case Process.get(:"$callers") do
      callers when is_list(callers) and callers != [] -> List.last(callers)
      _ -> self()
    end
  end
end
