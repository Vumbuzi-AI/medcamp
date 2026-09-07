defmodule Medcamp.Mch.Delivery do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mch_deliveries" do
    belongs_to :pregnancy, Medcamp.Mch.Pregnancy
    belongs_to :child, Medcamp.Mch.Child, foreign_key: :child_id
    field :delivery_date, :date
    field :delivery_time, :time
    field :duration_of_pregnancy_weeks, :integer
    field :mode_of_delivery, :string
    field :birth_weight_grams, :integer
    field :birth_length_cm, :decimal
    field :head_circumference_cm, :decimal
    field :place_of_childbirth, :string
    field :conducted_by, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(delivery, attrs) do
    delivery
    |> cast(attrs, [
      :pregnancy_id,
      :child_id,
      :delivery_date,
      :delivery_time,
      :duration_of_pregnancy_weeks,
      :mode_of_delivery,
      :birth_weight_grams,
      :birth_length_cm,
      :head_circumference_cm,
      :place_of_childbirth,
      :conducted_by
    ])
    |> validate_required([:pregnancy_id])
    |> foreign_key_constraint(:pregnancy_id)
    |> foreign_key_constraint(:child_id)
  end
end
