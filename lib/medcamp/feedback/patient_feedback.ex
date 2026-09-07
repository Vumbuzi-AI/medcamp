defmodule Medcamp.Feedback.PatientFeedback do
  use Ecto.Schema
  import Ecto.Changeset

  schema "patient_feedbacks" do
    field :name, :string
    field :age, :integer
    field :gender, :string
    field :visit_date, :date
    field :department, :string
    field :department_other, :string
    field :registration_rating, :integer
    field :staff_courtesy_rating, :integer
    field :waiting_time_rating, :integer
    field :cleanliness_rating, :integer
    field :privacy_rating, :integer
    field :diagnosis_explanation_rating, :integer
    field :medication_availability_rating, :integer
    field :lab_service_rating, :integer
    field :overall_satisfaction_rating, :integer
    field :liked_most, :string
    field :areas_to_improve, :string
    field :other_comments, :string
    field :would_recommend, :string
    field :submitted_at, :naive_datetime
    field :ip_address, :string

    field :how_did_you_know, :string

    field :how_did_you_know_other, :string

    field :satisfaction_level, :string

    field :service_quality_rating, :integer

    field :staff_helpful, :string

    field :staff_helpful_other, :string

    field :suggestions, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(patient_feedback, attrs) do
    patient_feedback
    |> cast(attrs, [
      :name,
      :age,
      :gender,
      :visit_date,
      :department,
      :department_other,
      :registration_rating,
      :staff_courtesy_rating,
      :waiting_time_rating,
      :cleanliness_rating,
      :privacy_rating,
      :diagnosis_explanation_rating,
      :medication_availability_rating,
      :lab_service_rating,
      :how_did_you_know,
      :how_did_you_know_other,
      :satisfaction_level,
      :service_quality_rating,
      :staff_helpful,
      :staff_helpful_other,
      :suggestions,
      :overall_satisfaction_rating,
      :liked_most,
      :areas_to_improve,
      :other_comments,
      :would_recommend,
      :ip_address,
      :submitted_at
    ])
    |> validate_optional_patient_info()
    |> validate_ratings()
    |> validate_department()
  end

  defp validate_optional_patient_info(changeset) do
    changeset
    |> validate_number(:age,
      greater_than: 0,
      less_than: 150,
      message: "must be between 1 and 149"
    )
    |> validate_inclusion(:gender, ["male", "female", "other"], message: "is not a valid gender")
    |> validate_length(:name, max: 255)
  end

  defp validate_ratings(changeset) do
    rating_fields = [
      :registration_rating,
      :staff_courtesy_rating,
      :waiting_time_rating,
      :cleanliness_rating,
      :privacy_rating,
      :diagnosis_explanation_rating,
      :medication_availability_rating,
      :lab_service_rating,
      :overall_satisfaction_rating
    ]

    Enum.reduce(rating_fields, changeset, fn field, acc ->
      validate_inclusion(acc, field, 1..5, message: "must be between 1 and 5")
    end)
  end

  defp validate_department(changeset) do
    valid_departments = ["opd", "inpatient", "maternity", "laboratory", "pharmacy", "radiology"]

    changeset
    |> validate_inclusion(:department, valid_departments ++ ["other"],
      message: "is not a valid department"
    )
    |> validate_department_other()
  end

  defp validate_department_other(changeset) do
    case get_field(changeset, :department) do
      "other" ->
        validate_required(changeset, [:department_other],
          message: "must be specified when 'other' is selected"
        )
        |> validate_length(:department_other, min: 2, max: 100)

      _ ->
        changeset
    end
  end
end
