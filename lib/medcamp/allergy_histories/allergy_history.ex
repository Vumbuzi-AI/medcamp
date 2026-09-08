defmodule Medcamp.AllergyHistories.AllergyHistory do
  use Ecto.Schema
  use Medcamp.Tenancy.Schema
  import Ecto.Changeset

  @categories ~w(food medication environment biologic)
  @types ~w(allergy intolerance)
  @clinical_statuses ~w(active inactive resolved)
  @verification_statuses ~w(confirmed unconfirmed refuted entered-in-error)
  @criticalities ~w(low high unable-to-assess)
  @severities ~w(mild moderate severe)

  schema "allergy_histories" do
    tenant_field()

    field :substance_name, :string
    field :substance_code, :string
    field :substance_code_system, :string
    field :category, :string
    field :type, :string
    field :clinical_status, :string, default: "active"
    field :verification_status, :string, default: "unconfirmed"
    field :criticality, :string
    field :reaction_manifestation, :string
    field :reaction_severity, :string
    field :onset_date, :date
    field :notes, :string

    belongs_to :patient, Medcamp.Patients.Patient
    belongs_to :recorded_by, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def categories, do: @categories
  def types, do: @types
  def clinical_statuses, do: @clinical_statuses
  def verification_statuses, do: @verification_statuses
  def criticalities, do: @criticalities
  def severities, do: @severities

  @doc false
  def changeset(allergy_history, attrs) do
    allergy_history
    |> cast(attrs, [
      :substance_name,
      :substance_code,
      :substance_code_system,
      :category,
      :type,
      :clinical_status,
      :verification_status,
      :criticality,
      :reaction_manifestation,
      :reaction_severity,
      :onset_date,
      :notes,
      :patient_id,
      :recorded_by_id
    ])
    |> validate_required([
      :substance_name,
      :category,
      :type,
      :clinical_status,
      :verification_status,
      :criticality,
      :patient_id
    ])
    |> validate_inclusion(:category, @categories)
    |> validate_inclusion(:type, @types)
    |> validate_inclusion(:clinical_status, @clinical_statuses)
    |> validate_inclusion(:verification_status, @verification_statuses)
    |> validate_inclusion(:criticality, @criticalities)
    |> validate_inclusion(:reaction_severity, @severities ++ [nil])
    |> foreign_key_constraint(:patient_id)
    |> foreign_key_constraint(:recorded_by_id)
    |> put_org_id()
  end
end
