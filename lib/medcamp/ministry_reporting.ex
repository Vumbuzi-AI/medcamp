defmodule Medcamp.MinistryReporting do
  @moduledoc """
  Loads Ministry of Health reporting form definitions from JSON.
  """

  alias Medcamp.MinistryReporting.MOH706
  alias Medcamp.MinistryReporting.MOH710

  @auto_fill_forms %{
    "moh_706" => MOH706,
    "moh_710" => MOH710
  }

  def forms do
    forms_path()
    |> File.read!()
    |> Jason.decode!()
  end

  def get_form(id) when is_binary(id) do
    Enum.find(forms(), &(&1["id"] == id))
  end

  def default_form_id do
    forms()
    |> List.first()
    |> Map.fetch!("id")
  end

  def pages(form), do: get_in(form, ["layout", "pages"]) || []

  def orientation(form), do: get_in(form, ["layout", "orientation"]) || "portrait"

  def auto_fill_supported?(form_id), do: Map.has_key?(@auto_fill_forms, form_id)

  def report_capability(form_id) do
    case form_id do
      "moh_706" ->
        %{
          status: "supported",
          mode: "deterministic",
          source: "completed structured laboratory entries",
          ai_advisory: true,
          limitations: []
        }

      "moh_710" ->
        %{
          status: "partially_supported",
          mode: "deterministic",
          source: "MCH immunization and child-health records",
          ai_advisory: true,
          limitations: [
            "Static/outreach delivery mode is not recorded.",
            "Cold-chain and vaccine-stock logistics remain manual."
          ]
        }

      _ ->
        %{
          status: "schema_only",
          mode: "manual_with_ai_advisory",
          source: nil,
          ai_advisory: true,
          limitations: ["An approved deterministic source mapping has not been implemented."]
        }
    end
  end

  def mapping_candidates(form) do
    form
    |> Map.get("sections", [])
    |> Enum.with_index()
    |> Enum.flat_map(fn {section, section_index} ->
      section
      |> section_rows()
      |> Enum.with_index()
      |> Enum.flat_map(fn {row, row_index} ->
        code = if is_map(row), do: Map.get(row, "code", ""), else: ""
        label = row_label(row)

        blank_placeholder? =
          is_map(row) && String.starts_with?(Map.get(row, "id", ""), "blank_")

        if blank_placeholder? || (code == "" && label == "") do
          []
        else
          [
            %{
              "candidate_id" => "#{section_index}:#{row_index}",
              "section" => section["title"],
              "row_code" => code,
              "row_label" => label
            }
          ]
        end
      end)
    end)
  end

  def auto_fill(form_id, date_from, date_to) when is_binary(form_id) do
    with {:ok, date_from} <- parse_date(date_from),
         {:ok, date_to} <- parse_date(date_to),
         :ok <- validate_range(date_from, date_to),
         {:ok, calculator} <- Map.fetch(@auto_fill_forms, form_id) do
      {:ok, calculator.generate(date_from, date_to)}
    else
      :error -> {:error, :unsupported_form}
      {:error, _reason} = error -> error
    end
  end

  def auto_fill(_form_id, _date_from, _date_to), do: {:error, :invalid_date}

  def field_ids(form) do
    form
    |> form_fields()
    |> Enum.map(& &1["id"])
  end

  def table_cell_ids(form) do
    form
    |> Map.get("sections", [])
    |> Enum.flat_map(fn section ->
      section_id = slug(section["title"])
      rows = section_rows(section)
      rows = Enum.reject(rows, &(is_map(&1) && Map.get(&1, "input", true) == false))

      section
      |> Map.get("columns", [])
      |> Enum.drop(Map.get(section, "label_columns", 1))
      |> Enum.with_index()
      |> Enum.flat_map(fn {column, column_index} ->
        column_id =
          slug(if is_map(column), do: Map.get(column, "id", column["label"]), else: column)

        rows
        |> Enum.with_index()
        |> Enum.map(fn {row, row_index} ->
          row_id =
            if is_map(row) do
              Map.get(row, "id") ||
                "#{Map.get(row, "code", "")}_#{Map.get(row, "label", "")}"
            else
              row
            end

          "table_#{section_id}_r#{row_index}_#{slug(row_id)}_c#{column_index}_#{column_id}"
        end)
      end)
    end)
  end

  def table_cell_id(section, row, row_index, column, column_index) do
    section_id = slug(section["title"])

    row_id =
      if is_map(row) do
        Map.get(row, "id") ||
          "#{Map.get(row, "code", "")}_#{Map.get(row, "label", "")}"
      else
        row
      end

    column_id =
      slug(if is_map(column), do: Map.get(column, "id", column["label"]), else: column)

    "table_#{section_id}_r#{row_index}_#{slug(row_id)}_c#{column_index}_#{column_id}"
  end

  def find_table_cell_id(form, section_title, row_label, column_label) do
    find_matching_table_cell_id(
      form,
      section_title,
      &row_matches_label?(&1, row_label),
      column_label
    )
  end

  def find_table_cell_id_by_code(form, section_title, row_code, row_label, column_label) do
    find_matching_table_cell_id(
      form,
      section_title,
      &row_matches_code_and_label?(&1, row_code, row_label),
      column_label
    )
  end

  defp find_matching_table_cell_id(form, section_title, row_match?, column_label) do
    with %{} = section <-
           Enum.find(Map.get(form, "sections", []), &(&1["title"] == section_title)),
         {row, row_index} <-
           section
           |> section_rows()
           |> Enum.with_index()
           |> Enum.find(fn {row, _index} -> row_match?.(row) end),
         {column, column_index} <-
           section
           |> Map.get("columns", [])
           |> Enum.drop(Map.get(section, "label_columns", 1))
           |> Enum.with_index()
           |> Enum.find(fn {column, _index} -> column_label(column) == column_label end) do
      table_cell_id(section, row, row_index, column, column_index)
    else
      _ -> nil
    end
  end

  defp form_fields(form) do
    meta_fields = Map.get(form, "meta_fields", [])

    section_fields =
      form
      |> Map.get("sections", [])
      |> Enum.flat_map(&Map.get(&1, "fields", []))

    meta_fields ++ section_fields
  end

  defp section_rows(section) do
    case Map.get(section, "rows") do
      rows when is_list(rows) ->
        rows

      _ ->
        for group <- Map.get(section, "row_groups", []),
            template <- Map.get(section, "row_templates", []) do
          %{
            "id" => "#{Map.get(group, "id", group["label"])}_#{template["id"]}",
            "code" => group["label"],
            "label" => template["label"]
          }
        end
    end
  end

  def slug(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "_")
    |> String.trim("_")
  end

  defp parse_date(%Date{} = date), do: {:ok, date}

  defp parse_date(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> {:ok, date}
      _ -> {:error, :invalid_date}
    end
  end

  defp parse_date(_value), do: {:error, :invalid_date}

  defp validate_range(date_from, date_to) do
    if Date.compare(date_from, date_to) in [:lt, :eq],
      do: :ok,
      else: {:error, :invalid_range}
  end

  defp row_label(row) when is_map(row), do: Map.get(row, "label", "")
  defp row_label(row), do: row

  defp row_matches_label?(row, label), do: row_label(row) == label

  defp row_matches_code_and_label?(row, code, label) when is_map(row),
    do: Map.get(row, "code", "") == code && row_label(row) == label

  defp row_matches_code_and_label?(_row, _code, _label), do: false

  defp column_label(column) when is_map(column), do: Map.get(column, "label", "")
  defp column_label(column), do: column

  defp forms_path do
    :medcamp
    |> :code.priv_dir()
    |> Path.join("ministry_reporting/forms.json")
  end
end
