defmodule Medcamp.Repo.Migrations.CreatePatientFeedbacks do
  use Ecto.Migration

  def change do
    create table(:patient_feedbacks) do
      add :name, :string
      add :age, :integer
      add :gender, :string
      add :visit_date, :date
      add :department, :string
      add :department_other, :string
      add :registration_rating, :integer
      add :staff_courtesy_rating, :integer
      add :waiting_time_rating, :integer
      add :cleanliness_rating, :integer
      add :privacy_rating, :integer
      add :diagnosis_explanation_rating, :integer
      add :medication_availability_rating, :integer
      add :lab_service_rating, :integer
      add :overall_satisfaction_rating, :integer
      add :liked_most, :text
      add :areas_to_improve, :text
      add :other_comments, :text
      add :would_recommend, :string

      add :ip_address, :string
      add :submitted_at, :naive_datetime, default: fragment("NOW()")

      timestamps(type: :utc_datetime)
    end

    create index(:patient_feedbacks, [:visit_date])
    create index(:patient_feedbacks, [:department])
    create index(:patient_feedbacks, [:would_recommend])
    create index(:patient_feedbacks, [:overall_satisfaction_rating])
    create index(:patient_feedbacks, [:submitted_at])
  end
end
