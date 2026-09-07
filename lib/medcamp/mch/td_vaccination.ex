defmodule Medcamp.Mch.TdVaccination do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mch_td_vaccinations" do
    belongs_to :mother, Medcamp.Mch.Mother
    field :dose_number, :integer
    field :date_given, :date
    field :next_visit, :date

    timestamps(type: :utc_datetime)
  end

  def changeset(td, attrs) do
    td
    |> cast(attrs, [:mother_id, :dose_number, :date_given, :next_visit])
    |> validate_required([:mother_id])
    |> foreign_key_constraint(:mother_id)
  end
end
