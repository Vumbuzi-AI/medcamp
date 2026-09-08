#!/usr/bin/env elixir
# Parse-check every Elixir source file in the project.
#
# `mix compile` needs the dependency tree; this only needs Elixir itself, so
# it catches syntax damage (unbalanced do/end, stray commas, truncated
# clauses) without a working `mix deps.get`. It does NOT type-check, resolve
# modules or validate the HEEx inside ~H sigils - see
# `scripts/find_dangling_refs.py` and `scripts/check_heex.exs` for those.
#
#     elixir scripts/check_syntax.exs

files =
  Path.wildcard("lib/**/*.ex") ++
    Path.wildcard("lib/**/*.exs") ++
    Path.wildcard("test/**/*.exs") ++
    Path.wildcard("priv/repo/**/*.exs")

bad =
  Enum.reduce(files, [], fn file, acc ->
    case Code.string_to_quoted(File.read!(file), file: file) do
      {:ok, _ast} -> acc
      {:error, {meta, message, token}} -> [{file, meta, message, token} | acc]
    end
  end)

Enum.each(Enum.reverse(bad), fn {file, meta, message, token} ->
  line = Keyword.get(meta, :line, "?")
  IO.puts("#{file}:#{line}: #{message}#{token}")
end)

IO.puts("checked #{length(files)} files, #{length(bad)} with syntax errors")
System.halt(if bad == [], do: 0, else: 1)
