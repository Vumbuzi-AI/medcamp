defmodule Medcamp.Mch.DevelopmentalMilestone do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mch_developmental_milestones" do
    belongs_to :child, Medcamp.Mch.Child
    field :milestone_name, :string
    field :expected_age_range, :string
    field :age_achieved_months, :integer
    field :status, :string
    field :assessment_date, :date

    timestamps(type: :utc_datetime)
  end

  def changeset(milestone, attrs) do
    milestone
    |> cast(attrs, [
      :child_id,
      :milestone_name,
      :expected_age_range,
      :age_achieved_months,
      :status,
      :assessment_date
    ])
    |> validate_required([:child_id, :milestone_name])
    |> foreign_key_constraint(:child_id)
  end
end
