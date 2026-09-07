defmodule Medcamp.Mch.AntenatalProfile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mch_antenatal_profiles" do
    belongs_to :pregnancy, Medcamp.Mch.Pregnancy
    field :haemoglobin_hb, :decimal
    field :blood_group, :string
    field :rhesus_factor, :string
    field :urinalysis, :string
    field :blood_rbs, :decimal
    field :tb_screening_date, :date
    field :tb_screening_outcome, :string
    field :triple_test_date, :date
    field :hiv_status, :string
    field :syphilis_status, :string
    field :hepatitis_b_status, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [
      :pregnancy_id,
      :haemoglobin_hb,
      :blood_group,
      :rhesus_factor,
      :urinalysis,
      :blood_rbs,
      :tb_screening_date,
      :tb_screening_outcome,
      :triple_test_date,
      :hiv_status,
      :syphilis_status,
      :hepatitis_b_status
    ])
    |> validate_required([:pregnancy_id])
    |> foreign_key_constraint(:pregnancy_id)
  end
end
