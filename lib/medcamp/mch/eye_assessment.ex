defmodule Medcamp.Mch.EyeAssessment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mch_eye_assessments" do
    belongs_to :child, Medcamp.Mch.Child
    field :assessment_date, :date
    field :age_at_assessment, :string
    field :teo_given, :boolean
    field :pupil_color, :string
    field :follows_objects, :boolean
    field :has_squint, :boolean
    field :other_problems, :boolean
    field :other_problems_description, :string
    field :referred, :boolean

    timestamps(type: :utc_datetime)
  end

  def changeset(assessment, attrs) do
    assessment
    |> cast(attrs, [
      :child_id,
      :assessment_date,
      :age_at_assessment,
      :teo_given,
      :pupil_color,
      :follows_objects,
      :has_squint,
      :other_problems,
      :other_problems_description,
      :referred
    ])
    |> validate_required([:child_id])
    |> foreign_key_constraint(:child_id)
  end
end
