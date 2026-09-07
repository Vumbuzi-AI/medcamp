defmodule MedcampWeb.ExpandableTableStreamsTest do
  @moduledoc """
  Guards a whole bug class rather than one page.

  `CoreComponents.table/1` only sets `phx-update="stream"` when the table has no
  expand column. An expandable table (one with an `:action` slot, or with more
  `:col` slots than `visible_cols`) instead iterates its rows eagerly, so a
  `%Phoenix.LiveView.LiveStream{}` passed as `rows` renders correctly on the
  mount/reset that filled it and then renders *zero rows* on the next re-render
  that isn't a stream reset — ticking a checkbox, opening a modal, a flash.

  Expandable tables must therefore be fed a plain list assign.
  """

  use ExUnit.Case, async: true

  @template_extensions ~w(.ex .heex)
  @default_visible_cols 4

  describe "expandable tables" do
    test "are never fed a LiveStream" do
      offenders =
        template_files()
        |> Enum.flat_map(&stream_backed_expandable_tables/1)
        |> Enum.sort()

      assert offenders == [],
             """
             These tables pass a LiveStream into an expandable table, so their rows
             disappear on the first re-render that isn't a stream reset.

             Assign a plain list instead of `stream/3`, and drop the `{_id, row}`
             destructuring from the `:let`s.

             #{Enum.map_join(offenders, "\n", fn {file, line, stream} -> "  #{file}:#{line} (@streams.#{stream})" end)}
             """
    end
  end

  defp template_files do
    Path.wildcard("lib/**/*.{ex,heex}")
    |> Enum.filter(&(Path.extname(&1) in @template_extensions))
  end

  defp stream_backed_expandable_tables(file) do
    source = File.read!(file)

    source
    |> table_calls()
    |> Enum.filter(fn {attrs, body, _offset} -> expandable?(attrs, body) end)
    |> Enum.flat_map(fn {attrs, _body, offset} ->
      case Regex.run(~r/rows=\{@streams\.(\w+)\}/, attrs) do
        [_, stream] -> [{file, line_at(source, offset), stream}]
        nil -> []
      end
    end)
  end

  # Returns {opening_tag_attrs, body, byte_offset} for every `<.table ...>` in
  # the source. Tables never nest, so scanning for the next `</.table>` is enough.
  defp table_calls(source) do
    ~r/<\.table\b/
    |> Regex.scan(source, return: :index)
    |> Enum.map(fn [{offset, length}] ->
      attrs_start = offset + length
      attrs_end = tag_end(source, attrs_start)
      attrs = binary_part(source, attrs_start, attrs_end - attrs_start)

      body =
        case :binary.match(source, "</.table>", scope: {attrs_end, byte_size(source) - attrs_end}) do
          {close, _} -> binary_part(source, attrs_end, close - attrs_end)
          :nomatch -> binary_part(source, attrs_end, byte_size(source) - attrs_end)
        end

      {attrs, body, offset}
    end)
  end

  # Finds the `>` that closes the opening tag, skipping any `>` nested inside a
  # `{...}` attribute expression (`row_click={fn -> ... end}`, `&"row-#{&1.id}"`).
  defp tag_end(source, index), do: tag_end(source, index, 0)

  defp tag_end(source, index, depth) do
    case binary_part(source, index, 1) do
      "{" -> tag_end(source, index + 1, depth + 1)
      "}" -> tag_end(source, index + 1, depth - 1)
      ">" when depth == 0 -> index
      _ -> tag_end(source, index + 1, depth)
    end
  end

  defp expandable?(attrs, body) do
    cols = count(body, ~r/<:col\b/)
    actions = count(body, ~r/<:action\b/)

    visible_cols =
      case Regex.run(~r/visible_cols=\{?(\d+)/, attrs) do
        [_, n] -> String.to_integer(n)
        nil -> @default_visible_cols
      end

    # `always_show` flips the split from "first N cols" to "the flagged cols",
    # which leaves every unflagged col in the expand panel.
    always_show? = Regex.match?(~r/always_show/, body)

    actions > 0 or always_show? or cols > visible_cols
  end

  defp count(source, regex), do: regex |> Regex.scan(source) |> length()

  defp line_at(source, offset) do
    source |> binary_part(0, offset) |> :binary.matches("\n") |> length() |> Kernel.+(1)
  end
end
