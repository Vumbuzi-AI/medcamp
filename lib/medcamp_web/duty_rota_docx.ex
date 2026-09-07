defmodule MedcampWeb.DutyRotaDocx do
  @moduledoc false

  @type rota_column :: %{
          date: Date.t() | nil,
          day_label: String.t() | nil,
          date_label: String.t()
        }

  @type staff_row :: %{
          name: String.t(),
          codes: [String.t()]
        }

  @type t :: %{
          headings: [String.t()],
          columns: [rota_column()],
          staff_rows: [staff_row()],
          key: [%{code: String.t(), label: String.t()}],
          activities: [String.t()],
          prepared_by: String.t() | nil
        }

  @spec parse(String.t()) :: {:ok, t()} | {:error, term()}
  def parse(docx_path) when is_binary(docx_path) do
    with true <- File.exists?(docx_path) || {:error, :not_found},
         {:ok, document_xml} <- read_zip_entry(docx_path, "word/document.xml"),
         {:ok, doc} <- parse_xml(document_xml) do
      {:ok, parse_doc(doc)}
    end
  end

  defp read_zip_entry(docx_path, entry_name) do
    case :zip.extract(String.to_charlist(docx_path), [:memory]) do
      {:ok, files} ->
        case Enum.find(files, fn {name, _bin} -> to_string(name) == entry_name end) do
          {_, bin} -> {:ok, bin}
          nil -> {:error, {:missing_entry, entry_name}}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_xml(xml_binary) when is_binary(xml_binary) do
    try do
      {doc, _rest} = :xmerl_scan.string(:erlang.binary_to_list(xml_binary))
      {:ok, doc}
    catch
      :exit, reason -> {:error, reason}
      kind, reason -> {:error, {kind, reason}}
    end
  end

  defp parse_doc(doc) do
    body = find_first(doc, :"w:body")
    body_children = xml_children(body)

    {pre_table_nodes, _rest} =
      Enum.split_while(body_children, fn node -> xml_name(node) != :"w:tbl" end)

    headings =
      pre_table_nodes
      |> Enum.filter(&(xml_name(&1) == :"w:p"))
      |> Enum.map(&node_text/1)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    tables =
      body_children
      |> Enum.filter(&(xml_name(&1) == :"w:tbl"))

    schedule_table = Enum.at(tables, 0)
    meta_table = Enum.at(tables, 1)

    {columns, staff_rows} = parse_schedule_table(schedule_table, headings)
    {key, activities} = parse_meta_table(meta_table)

    prepared_by =
      body_children
      |> Enum.filter(&(xml_name(&1) == :"w:p"))
      |> Enum.map(&node_text/1)
      |> Enum.map(&String.trim/1)
      |> Enum.find(&String.contains?(&1, "Prepared by"))

    %{
      headings: headings,
      columns: columns,
      staff_rows: staff_rows,
      key: key,
      activities: activities,
      prepared_by: prepared_by
    }
  end

  defp parse_schedule_table(nil, _headings), do: {[], []}

  defp parse_schedule_table(table, headings) do
    rows =
      table
      |> direct_children(:"w:tr")
      |> Enum.map(&row_cells_text/1)

    day_row = Enum.at(rows, 0, [])
    date_row = Enum.at(rows, 1, [])

    day_labels = Enum.drop(day_row, 2)
    date_labels = Enum.drop(date_row, 2)

    {year, month} = parse_month_year(headings)
    columns = build_columns(date_labels, day_labels, year, month)

    staff_rows =
      rows
      |> Enum.drop(2)
      |> Enum.map(fn
        [name | codes] ->
          %{name: String.trim(name), codes: Enum.map(codes, &String.trim/1)}

        _ ->
          %{name: "", codes: []}
      end)
      |> Enum.reject(&(&1.name == ""))

    {columns, staff_rows}
  end

  defp build_columns(date_labels, day_labels, year, month) do
    dates =
      date_labels
      |> Enum.map(&String.trim/1)

    day_labels =
      day_labels
      |> Enum.map(&String.trim/1)

    {date_structs, _} =
      Enum.reduce(dates, {[], {year, month, nil}}, fn date_label, {acc, {y, m, prev_day}} ->
        day_int = parse_int(date_label)

        {y2, m2} =
          cond do
            is_integer(day_int) and is_integer(prev_day) and day_int < prev_day ->
              next_month(y, m)

            true ->
              {y, m}
          end

        date =
          case day_int do
            nil ->
              nil

            day ->
              case Date.new(y2, m2, day) do
                {:ok, d} -> d
                {:error, _} -> nil
              end
          end

        prev_day2 = if is_integer(day_int), do: day_int, else: prev_day

        {[date | acc], {y2, m2, prev_day2}}
      end)

    date_structs = Enum.reverse(date_structs)

    Enum.with_index(dates)
    |> Enum.map(fn {date_label, idx} ->
      date = Enum.at(date_structs, idx)

      day_label =
        cond do
          is_binary(Enum.at(day_labels, idx)) and Enum.at(day_labels, idx) != "" ->
            Enum.at(day_labels, idx)

          is_struct(date, Date) ->
            Calendar.strftime(date, "%a")

          true ->
            nil
        end

      %{
        date: date,
        day_label: day_label,
        date_label: date_label
      }
    end)
  end

  defp parse_meta_table(nil), do: {[], []}

  defp parse_meta_table(table) do
    rows =
      table
      |> direct_children(:"w:tr")
      |> Enum.map(&row_cells_text/1)

    key =
      rows
      |> Enum.take(3)
      |> Enum.map(fn
        [code, label] -> %{code: String.trim(code), label: String.trim(label)}
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)

    activities =
      rows
      |> Enum.drop(3)
      |> Enum.map(fn
        [_maybe_blank, text] -> String.trim(text)
        [text] -> String.trim(text)
        _ -> ""
      end)
      |> Enum.reject(&(&1 == ""))

    {key, activities}
  end

  defp parse_month_year(headings) do
    heading = headings |> Enum.join(" ") |> String.upcase()

    month =
      Enum.find_value(month_map(), fn {name, num} ->
        if String.contains?(heading, name), do: num, else: nil
      end) || 6

    year =
      case Regex.run(~r/\b(20\d{2})\b/, heading) do
        [_, y] -> String.to_integer(y)
        _ -> Date.utc_today().year
      end

    {year, month}
  end

  defp month_map do
    %{
      "JANUARY" => 1,
      "FEBRUARY" => 2,
      "MARCH" => 3,
      "APRIL" => 4,
      "MAY" => 5,
      "JUNE" => 6,
      "JULY" => 7,
      "AUGUST" => 8,
      "SEPTEMBER" => 9,
      "OCTOBER" => 10,
      "NOVEMBER" => 11,
      "DECEMBER" => 12
    }
  end

  defp parse_int(str) do
    str = String.trim(str || "")

    case Integer.parse(str) do
      {int, ""} -> int
      _ -> nil
    end
  end

  defp next_month(year, month) when month == 12, do: {year + 1, 1}
  defp next_month(year, month), do: {year, month + 1}

  defp row_cells_text(row) do
    row
    |> direct_children(:"w:tc")
    |> Enum.map(&cell_text/1)
  end

  defp cell_text(cell) do
    cell
    |> node_text()
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp node_text(node) do
    node
    |> find_all(:"w:t")
    |> Enum.map(&xml_text_value/1)
    |> Enum.join("")
    |> String.replace("\u00A0", " ")
  end

  defp xml_text_value({:xmlElement, :"w:t", _, _, _, _, _, _, content, _, _, _}) do
    content
    |> Enum.map(&xml_text_value/1)
    |> Enum.join("")
  end

  defp xml_text_value({:xmlText, _parents, _pos, _lang, value, _type}) when is_list(value),
    do: to_string(value)

  defp xml_text_value(_), do: ""

  defp xml_name({:xmlElement, name, _, _, _, _, _, _, _, _, _, _}), do: name
  defp xml_name(_), do: nil

  defp xml_children({:xmlElement, _name, _, _, _, _, _, _, children, _, _, _}), do: children
  defp xml_children(_), do: []

  defp direct_children(node, name) do
    node
    |> xml_children()
    |> Enum.filter(&(xml_name(&1) == name))
  end

  defp find_first(node, name) do
    case find_all(node, name) do
      [first | _] -> first
      [] -> nil
    end
  end

  defp find_all(node, name), do: do_find_all([node], name, [])

  defp do_find_all([], _name, acc), do: Enum.reverse(acc)

  defp do_find_all(
         [{:xmlElement, element_name, _, _, _, _, _, _, children, _, _, _} = el | rest],
         name,
         acc
       )
       when element_name == name do
    do_find_all(children ++ rest, name, [el | acc])
  end

  defp do_find_all([{:xmlElement, _other, _, _, _, _, _, _, children, _, _, _} | rest], name, acc) do
    do_find_all(children ++ rest, name, acc)
  end

  defp do_find_all([_other | rest], name, acc), do: do_find_all(rest, name, acc)
end
