defmodule Medcamp.LabTestTemplates.LabTestEntry do
  @moduledoc """
  Schema for actual lab test entries/results.

  Links a lab_result (the request) to a specific test template,
  and stores the actual values in `results` JSON field.

  ## Results Structure

  The `results` field is a map where keys match the `name` fields
  from the template's `field_definitions`:

  ```
  %{
    "wbc" => %{"value" => "7.5", "flag" => "normal"},
    "rbc" => %{"value" => "4.8", "flag" => "normal"},
    "hgb" => %{"value" => "10.5", "flag" => "low"}
  }
  ```

  Flags: "normal", "low", "high", "critical_low", "critical_high"
  """
  use Ecto.Schema
  use Medcamp.Tenancy.Schema
  import Ecto.Changeset

  @statuses ["pending", "in_progress", "completed", "verified"]

  schema "lab_test_entries" do
    tenant_field()

    field :results, :map, default: %{}
    field :remarks, :string
    field :sample_collected_on, :date
    field :test_performed_on, :date
    field :verified_at, :utc_datetime
    field :status, :string, default: "pending"

    belongs_to :lab_result, Medcamp.LabResults.LabResult
    belongs_to :template, Medcamp.LabTestTemplates.LabTestTemplate
    belongs_to :performed_by, Medcamp.Accounts.User
    belongs_to :verified_by, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @required_fields [:lab_result_id, :template_id]
  @optional_fields [
    :results,
    :remarks,
    :sample_collected_on,
    :test_performed_on,
    :verified_at,
    :status,
    :performed_by_id,
    :verified_by_id
  ]

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:lab_result_id)
    |> foreign_key_constraint(:template_id)
    |> foreign_key_constraint(:performed_by_id)
    |> foreign_key_constraint(:verified_by_id)
    |> unique_constraint([:lab_result_id, :template_id],
      name: :lab_test_entries_unique_test_per_request,
      message: "this test has already been added to this lab request"
    )
    |> put_org_id()
  end

  def results_changeset(entry, attrs) do
    entry
    |> cast(attrs, [
      :results,
      :remarks,
      :sample_collected_on,
      :test_performed_on,
      :status,
      :performed_by_id
    ])
    |> maybe_set_completed()
  end

  def verify_changeset(entry, attrs) do
    entry
    |> cast(attrs, [:verified_by_id, :verified_at, :status])
    |> put_change(:status, "verified")
    |> put_change(:verified_at, DateTime.utc_now())
  end

  defp maybe_set_completed(changeset) do
    results = get_field(changeset, :results)

    if results && map_size(results) > 0 do
      put_change(changeset, :status, "completed")
    else
      changeset
    end
  end

  @doc """
  Calculates flag based on value and reference range
  """
  def calculate_flag(value, ref_min, ref_max) when is_number(value) do
    cond do
      ref_min && ref_max && value < ref_min -> "low"
      ref_min && ref_max && value > ref_max -> "high"
      true -> "normal"
    end
  end

  def calculate_flag(value, ref_min, ref_max) when is_binary(value) do
    case Float.parse(value) do
      {num, _} -> calculate_flag(num, ref_min, ref_max)
      :error -> nil
    end
  end

  def calculate_flag(_, _, _), do: nil

  @doc """
  Returns results with flags calculated based on template
  """
  def results_with_flags(%__MODULE__{results: results, template: template})
      when not is_nil(template) do
    field_defs = template.field_definitions

    Enum.map(results, fn {field_name, result_data} ->
      field_def =
        Enum.find(field_defs, fn f ->
          f["name"] == field_name || f[:name] == field_name
        end)

      flag =
        if field_def do
          ref_min = field_def["ref_range_min"] || field_def[:ref_range_min]
          ref_max = field_def["ref_range_max"] || field_def[:ref_range_max]
          calculate_flag(result_data["value"], ref_min, ref_max)
        else
          nil
        end

      {field_name, Map.put(result_data, "flag", flag)}
    end)
    |> Map.new()
  end

  def results_with_flags(%__MODULE__{results: results}), do: results
end
