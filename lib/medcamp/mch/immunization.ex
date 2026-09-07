defmodule Medcamp.Mch.Immunization do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mch_immunizations" do
    belongs_to :child, Medcamp.Mch.Child
    field :vaccine_name, :string
    field :dose_number, :integer
    field :scheduled_age, :string
    field :date_given, :date
    field :batch_number, :string
    field :next_visit_date, :date
    field :adverse_event, :boolean
    field :adverse_event_description, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(immunization, attrs) do
    immunization
    |> cast(attrs, [
      :child_id,
      :vaccine_name,
      :dose_number,
      :scheduled_age,
      :date_given,
      :batch_number,
      :next_visit_date,
      :adverse_event,
      :adverse_event_description
    ])
    |> validate_required([:child_id])
    |> foreign_key_constraint(:child_id)
  end
end
