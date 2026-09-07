defmodule Medcamp.LabConsumables.LabConsumable do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lab_consumables" do
    field :date, :string
    field :consumed_quantity, :string
    field :purpose, :string
    belongs_to :patient, Medcamp.Patients.Patient, foreign_key: :patient_id

    belongs_to :lab_allocation, Medcamp.LabAllocations.LabAllocation,
      foreign_key: :lab_allocation_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(lab_consumable, attrs) do
    lab_consumable
    |> cast(attrs, [:consumed_quantity, :date, :purpose, :patient_id, :lab_allocation_id])
    |> validate_required([:consumed_quantity, :date, :purpose])
  end
end
