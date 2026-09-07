defmodule Medcamp.Mch.PncMotherVisit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mch_pnc_mother_visits" do
    belongs_to :mother, Medcamp.Mch.Mother
    belongs_to :delivery, Medcamp.Mch.Delivery, foreign_key: :delivery_id
    field :visit_number, :integer
    field :visit_date, :date
    field :bp_systolic, :integer
    field :bp_diastolic, :integer
    field :temperature, :decimal
    field :general_condition, :string
    field :breast_condition, :string
    field :uterus_involution, :string
    field :haemoglobin, :decimal
    field :fp_counseling_done, :boolean
    field :fp_method, :string

    has_many :pnc_baby_visits, Medcamp.Mch.PncBabyVisit

    timestamps(type: :utc_datetime)
  end

  def changeset(visit, attrs) do
    visit
    |> cast(attrs, [
      :mother_id,
      :delivery_id,
      :visit_number,
      :visit_date,
      :bp_systolic,
      :bp_diastolic,
      :temperature,
      :general_condition,
      :breast_condition,
      :uterus_involution,
      :haemoglobin,
      :fp_counseling_done,
      :fp_method
    ])
    |> validate_required([:mother_id])
    |> foreign_key_constraint(:mother_id)
  end
end
