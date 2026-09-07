defmodule Medcamp.Mch.Pregnancy do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mch_pregnancies" do
    belongs_to :mother, Medcamp.Mch.Mother
    field :status, :string, default: "active"
    field :lmp, :date
    field :edd, :date
    field :anc_number, :string

    has_many :anc_visits, Medcamp.Mch.AncVisit
    has_many :antenatal_profiles, Medcamp.Mch.AntenatalProfile
    has_many :physical_examinations, Medcamp.Mch.PhysicalExamination
    has_many :malaria_prophylaxis, Medcamp.Mch.MalariaProphylaxis
    has_many :ifas_supplements, Medcamp.Mch.IfasSupplement
    has_many :deworming_maternal, Medcamp.Mch.DewormingMaternal
    has_many :deliveries, Medcamp.Mch.Delivery

    timestamps(type: :utc_datetime)
  end

  def changeset(pregnancy, attrs) do
    pregnancy
    |> cast(attrs, [:mother_id, :status, :lmp, :edd, :anc_number])
    |> validate_required([:mother_id])
    |> foreign_key_constraint(:mother_id)
  end
end
