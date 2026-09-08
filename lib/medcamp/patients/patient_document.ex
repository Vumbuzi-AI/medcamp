defmodule Medcamp.Patients.PatientDocument do
  use Ecto.Schema
  use Medcamp.Tenancy.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :id,
             :document_name,
             :document_type,
             :file_path,
             :content_type,
             :patient_id,
             :inserted_at,
             :updated_at
           ]}

  schema "patient_documents" do
    tenant_field()

    field :document_name, :string

    field :document_type,
          Ecto.Enum,
          values: [
            :birth_certificate,
            :national_id,
            :passport,
            :insurance_card,
            :lab_report,
            :prescription,
            :referral_letter,
            :xray,
            :mri,
            :other
          ]

    field :file_path, :string
    field :content_type, :string

    belongs_to :patient, Medcamp.Patients.Patient

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(patient_document, attrs) do
    patient_document
    |> cast(attrs, [
      :document_name,
      :document_type,
      :file_path,
      :content_type,
      :patient_id
    ])
    |> validate_required([
      :document_name,
      :document_type,
      :file_path,
      :content_type,
      :patient_id
    ])
    |> foreign_key_constraint(:patient_id)
    |> put_org_id()
  end
end
