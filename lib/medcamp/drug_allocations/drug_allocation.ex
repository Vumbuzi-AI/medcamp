defmodule Medcamp.DrugAllocations.DrugAllocation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "drug_allocations" do
    field :quantity, :integer
    field :prescription, :string
    field :payment_type, :string
    field :insurance_name, :string
    field :total_amount_paid, :integer
    field :has_paid, :boolean, default: false
    field :excluded_from_insurance_invoice, :boolean, default: false
    field :has_been_assigned, :boolean, default: false
    field :if_prompted_by_pharmacist, :boolean, default: false
    belongs_to :pharmacist, Medcamp.Accounts.User, foreign_key: :pharmacist_id
    belongs_to :patient, Medcamp.Patients.Patient
    belongs_to :doctor_note, Medcamp.DoctorNotes.DoctorNote
    belongs_to :doctor, Medcamp.Accounts.User
    embeds_many :drugs_assigned, Medcamp.DrugAllocations.DrugAssigned, on_replace: :delete
    has_many :drugs_given, Medcamp.DrugsGiven.DrugGiven
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(drug_allocation, attrs, opts \\ []) do
    drug_allocation
    |> cast(attrs, [
      :quantity,
      :prescription,
      :patient_id,
      :payment_type,
      :insurance_name,
      :total_amount_paid,
      :has_paid,
      :excluded_from_insurance_invoice,
      :has_been_assigned,
      :if_prompted_by_pharmacist,
      :doctor_note_id,
      :doctor_id,
      :pharmacist_id
    ])
    |> validate_required([
      :prescription,
      :patient_id,
      :has_been_assigned
    ])
    |> cast_embed(:drugs_assigned,
      with: fn drug_assigned, attrs ->
        Medcamp.DrugAllocations.DrugAssigned.changeset(drug_assigned, attrs, opts)
      end
    )
  end
end
