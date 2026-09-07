defmodule Medcamp.LabTestTemplates.LabTestTemplate do
  @moduledoc """
  Schema for lab test templates.

  Each template defines a type of test (e.g., "Full Haemogram", "Liver Function Test")
  and its field structure stored in `field_definitions` as JSON.

  ## Field Definition Structure

  Each field in `field_definitions` is a map with:
  - `name` - unique identifier for the field (used as key in results)
  - `label` - display label
  - `type` - "number", "text", "select", "boolean"
  - `unit` - unit of measurement (e.g., "mmol/L", "%")
  - `ref_range_min` - minimum reference value (for flagging)
  - `ref_range_max` - maximum reference value (for flagging)
  - `ref_range_text` - display text for reference range
  - `options` - list of options for "select" type
  - `required` - whether field is required
  - `display_order` - order to display field
  - `section` - grouping label (e.g., "Microscopy", "Chemical")
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "lab_test_templates" do
    field :name, :string
    field :short_name, :string
    field :description, :string
    field :is_active, :boolean, default: true
    field :display_order, :integer, default: 0
    field :field_definitions, {:array, :map}, default: []

    belongs_to :category, Medcamp.LabTestTemplates.LabTestCategory

    timestamps(type: :utc_datetime)
  end

  @required_fields [:name, :field_definitions]
  @optional_fields [:short_name, :description, :is_active, :display_order, :category_id]

  def changeset(template, attrs) do
    template
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_field_definitions()
    |> unique_constraint(:name)
    |> foreign_key_constraint(:category_id)
  end

  defp validate_field_definitions(changeset) do
    case get_change(changeset, :field_definitions) do
      nil ->
        changeset

      definitions when is_list(definitions) ->
        if Enum.all?(definitions, &valid_field_definition?/1) do
          changeset
        else
          add_error(changeset, :field_definitions, "contains invalid field definitions")
        end

      _ ->
        add_error(changeset, :field_definitions, "must be a list")
    end
  end

  defp valid_field_definition?(field) when is_map(field) do
    Map.has_key?(field, :name) || Map.has_key?(field, "name")
  end

  defp valid_field_definition?(_), do: false

  @doc """
  Returns field definitions sorted by display_order
  """
  def sorted_fields(%__MODULE__{field_definitions: definitions}) do
    Enum.sort_by(definitions, fn field ->
      field[:display_order] || field["display_order"] || 999
    end)
  end

  @doc """
  Returns fields grouped by section
  """
  def grouped_fields(%__MODULE__{} = template) do
    template
    |> sorted_fields()
    |> Enum.group_by(fn field ->
      field[:section] || field["section"] || "main"
    end)
  end
end
