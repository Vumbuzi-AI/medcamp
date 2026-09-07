defmodule Mix.Tasks.Medcamp.Mcp.Reporting do
  use Mix.Task

  @shortdoc "Starts the read-only Ministry Reporting MCP server over stdio"
  @requirements ["app.config"]

  @moduledoc """
  Starts a local MCP server over stdio.

      mix medcamp.mcp.reporting

  Configure an MCP host to launch the command from the Medcamp project directory.
  The server exposes aggregate, read-only reporting tools and uses the same
  database configuration as the selected MIX_ENV.
  """

  @impl Mix.Task
  def run(_args) do
    # MCP reserves stdout for JSON-RPC messages. In particular, do not let an
    # automatic compile triggered by app.start write Mix status messages there.
    Mix.shell(Mix.Shell.Quiet)
    Logger.configure(level: :error)
    Mix.Task.run("app.start")

    IO.stream(:stdio, :line)
    |> Enum.each(&handle_line/1)
  end

  defp handle_line(line) do
    with {:ok, request} <- Jason.decode(line),
         response when is_map(response) <- Medcamp.MinistryReporting.MCP.handle(request) do
      IO.puts(Jason.encode!(response))
    else
      :notification ->
        :ok

      {:error, _error} ->
        IO.puts(
          Jason.encode!(%{
            "jsonrpc" => "2.0",
            "id" => nil,
            "error" => %{"code" => -32_700, "message" => "Parse error"}
          })
        )
    end
  end
end
