defmodule Medcamp.LabTestTemplates do
  @moduledoc """
  Context for managing lab test templates and test entries.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo
  alias Medcamp.LabTestTemplates.{LabTestCategory, LabTestTemplate, LabTestEntry}

  # ===========================================================================
  # CATEGORIES
  # ===========================================================================

  def list_categories do
    LabTestCategory
    |> order_by([c], asc: c.display_order, asc: c.name)
    |> Repo.all()
  end

  def get_category!(id), do: Repo.get!(LabTestCategory, id)

  # ===========================================================================
  # TEMPLATES
  # ===========================================================================

  def list_templates do
    LabTestTemplate
    |> where([t], t.is_active == true)
    |> order_by([t], asc: t.display_order, asc: t.name)
    |> preload(:category)
    |> Repo.all()
  end

  def list_templates_by_category(category_id) do
    LabTestTemplate
    |> where([t], t.category_id == ^category_id and t.is_active == true)
    |> order_by([t], asc: t.display_order, asc: t.name)
    |> Repo.all()
  end

  def list_templates_grouped_by_category do
    list_templates()
    |> Enum.group_by(& &1.category)
  end

  def get_template!(id) do
    LabTestTemplate
    |> preload(:category)
    |> Repo.get!(id)
  end

  def get_template_by_name(name) do
    LabTestTemplate
    |> where([t], t.name == ^name or t.short_name == ^name)
    |> preload(:category)
    |> Repo.one()
  end

  def search_templates(query) do
    search_term = "%#{query}%"

    LabTestTemplate
    |> where([t], t.is_active == true)
    |> where([t], ilike(t.name, ^search_term) or ilike(t.short_name, ^search_term))
    |> order_by([t], asc: t.name)
    |> preload(:category)
    |> Repo.all()
  end

  def create_template(attrs \\ %{}) do
    %LabTestTemplate{}
    |> LabTestTemplate.changeset(attrs)
    |> Repo.insert()
  end

  def update_template(%LabTestTemplate{} = template, attrs) do
    template
    |> LabTestTemplate.changeset(attrs)
    |> Repo.update()
  end

  # ===========================================================================
  # TEST ENTRIES
  # ===========================================================================

  @doc """
  Lists all test entries for a lab result.
  """
  def list_entries_for_lab_result(lab_result_id) do
    LabTestEntry
    |> where([e], e.lab_result_id == ^lab_result_id)
    |> preload([:template, :performed_by, :verified_by])
    |> order_by([e], asc: e.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single test entry with preloads.
  """
  def get_entry!(id) do
    LabTestEntry
    |> preload([:template, :performed_by, :verified_by, lab_result: [:patient, :doctor]])
    |> Repo.get!(id)
  end

  @doc """
  Creates a new test entry for a lab result.
  """
  def create_entry(attrs \\ %{}) do
    %LabTestEntry{}
    |> LabTestEntry.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Adds a test to a lab result.
  """
  def add_test_to_lab_result(lab_result_id, template_id) do
    create_entry(%{
      lab_result_id: lab_result_id,
      template_id: template_id,
      status: "pending"
    })
  end

  @doc """
  Updates the results for a test entry.
  """
  def update_entry_results(%LabTestEntry{} = entry, attrs) do
    entry
    |> LabTestEntry.results_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Fills in test results with automatic flag calculation. Accepts an optional
  `notes_map` keyed by field name for short per-field interpretation notes.
  """
  def fill_entry_results(%LabTestEntry{} = entry, results_map, notes_map \\ %{}, user_id) do
    # Load template if not loaded
    entry = Repo.preload(entry, :template)

    # Calculate flags for each result and attach the matching note (if any)
    results_with_flags =
      Enum.map(results_map, fn {field_name, value} ->
        field_def = find_field_definition(entry.template, field_name)

        flag =
          if field_def do
            ref_min = field_def["ref_range_min"] || field_def[:ref_range_min]
            ref_max = field_def["ref_range_max"] || field_def[:ref_range_max]
            LabTestEntry.calculate_flag(value, ref_min, ref_max)
          else
            nil
          end

        note = (notes_map[field_name] || "") |> to_string() |> String.trim()
        result_map = %{"value" => value, "flag" => flag}
        result_map = if note != "", do: Map.put(result_map, "note", note), else: result_map

        {field_name, result_map}
      end)
      |> Map.new()

    update_entry_results(entry, %{
      results: results_with_flags,
      performed_by_id: user_id,
      test_performed_on: Date.utc_today(),
      status: "completed"
    })
  end

  @doc """
  Verifies a completed test entry.
  """
  def verify_entry(%LabTestEntry{} = entry, verifier_id) do
    entry
    |> LabTestEntry.verify_changeset(%{verified_by_id: verifier_id})
    |> Repo.update()
  end

  @doc """
  Deletes a test entry (only if pending).
  """
  def delete_entry(%LabTestEntry{status: "pending"} = entry) do
    Repo.delete(entry)
  end

  def delete_entry(%LabTestEntry{}), do: {:error, :cannot_delete_completed}

  @doc """
  Checks if all tests in a lab result are completed.
  """
  def all_tests_completed?(lab_result_id) do
    pending_count =
      LabTestEntry
      |> where([e], e.lab_result_id == ^lab_result_id)
      |> where([e], e.status in ["pending", "in_progress"])
      |> Repo.aggregate(:count, :id)

    pending_count == 0
  end

  @doc """
  Gets IDs of templates already added to a lab result.
  """
  def get_existing_template_ids(lab_result_id) do
    LabTestEntry
    |> where([e], e.lab_result_id == ^lab_result_id)
    |> select([e], e.template_id)
    |> Repo.all()
  end

  # ===========================================================================
  # HELPERS
  # ===========================================================================

  defp find_field_definition(template, field_name) do
    Enum.find(template.field_definitions, fn field ->
      field["name"] == field_name || field[:name] == to_string(field_name)
    end)
  end

  @doc """
  Gets a summary of test entry for display.
  """
  def get_entry_summary(%LabTestEntry{} = entry) do
    entry = Repo.preload(entry, :template)

    %{
      test_name: entry.template.name,
      status: entry.status,
      performed_on: entry.test_performed_on,
      results: format_results_for_display(entry)
    }
  end

  defp format_results_for_display(%LabTestEntry{results: results, template: template}) do
    template
    |> LabTestTemplate.sorted_fields()
    |> Enum.map(fn field_def ->
      field_name = field_def["name"] || field_def[:name]
      result_data = Map.get(results, field_name, %{})

      %{
        name: field_name,
        label: field_def["label"] || field_def[:label],
        value: result_data["value"],
        flag: result_data["flag"],
        unit: field_def["unit"] || field_def[:unit],
        ref_range: field_def["ref_range_text"] || field_def[:ref_range_text],
        section: field_def["section"] || field_def[:section]
      }
    end)
  end

  @doc """
  Deletes a template.
  """
  def delete_template(%LabTestTemplate{} = template) do
    Repo.delete(template)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking template changes.
  """
  def change_template(%LabTestTemplate{} = template, attrs \\ %{}) do
    LabTestTemplate.changeset(template, attrs)
  end

  ## Categories

  @doc """
  Creates a category.
  """
  def create_category(attrs \\ %{}) do
    %LabTestCategory{}
    |> LabTestCategory.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a category.
  """
  def update_category(%LabTestCategory{} = category, attrs) do
    category
    |> LabTestCategory.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a category.
  """
  def delete_category(%LabTestCategory{} = category) do
    Repo.delete(category)
  end
end
