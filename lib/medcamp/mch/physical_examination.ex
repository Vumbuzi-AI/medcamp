defmodule Medcamp.Mch.PhysicalExamination do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mch_physical_examinations" do
    belongs_to :pregnancy, Medcamp.Mch.Pregnancy
    field :examination_date, :date
    field :bp_systolic, :integer
    field :bp_diastolic, :integer
    field :pulse_rate, :integer
    field :cvs_notes, :string
    field :respiratory_notes, :string
    field :breasts_notes, :string
    field :abdomen_notes, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(exam, attrs) do
    exam
    |> cast(attrs, [
      :pregnancy_id,
      :examination_date,
      :bp_systolic,
      :bp_diastolic,
      :pulse_rate,
      :cvs_notes,
      :respiratory_notes,
      :breasts_notes,
      :abdomen_notes
    ])
    |> validate_required([:pregnancy_id])
    |> foreign_key_constraint(:pregnancy_id)
  end
end
