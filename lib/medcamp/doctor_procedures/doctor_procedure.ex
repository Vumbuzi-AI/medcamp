defmodule Medcamp.DoctorProcedures.DoctorProcedure do
  use Ecto.Schema
  import Ecto.Changeset

  schema "doctor_procedures" do
    field :payment_type, :string
    field :insurance_name, :string
    field :has_paid, :boolean, default: false
    field :excluded_from_insurance_invoice, :boolean, default: false
    field :total_amount_paid, :integer
    belongs_to :procedure, Medcamp.Procedures.Procedure
    belongs_to :subsidized_procedure, Medcamp.SubsidizedProcedures.SubsidizedProcedure
    belongs_to :doctor, Medcamp.Accounts.User
    belongs_to :patient, Medcamp.Patients.Patient

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(doctor_procedure, attrs) do
    doctor_procedure
    |> cast(attrs, [
      :payment_type,
      :insurance_name,
      :has_paid,
      :excluded_from_insurance_invoice,
      :total_amount_paid,
      :procedure_id,
      :subsidized_procedure_id,
      :doctor_id,
      :patient_id
    ])
    |> validate_required([:payment_type, :has_paid])
    |> validate_procedure_or_subsidized()
  end

  defp validate_procedure_or_subsidized(changeset) do
    procedure_id = get_field(changeset, :procedure_id)
    subsidized_id = get_field(changeset, :subsidized_procedure_id)

    if procedure_id || subsidized_id do
      changeset
    else
      add_error(changeset, :procedure_id, "Select a procedure (Full Payment or Subsidized)")
    end
  end
end
