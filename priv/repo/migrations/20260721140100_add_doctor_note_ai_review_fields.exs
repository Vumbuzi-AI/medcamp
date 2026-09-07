defmodule Medcamp.Repo.Migrations.AddDoctorNoteAiReviewFields do
  use Ecto.Migration

  def change do
    alter table(:doctor_notes) do
      add :ai_review_payload, :map, null: false, default: %{}
      add :ai_review_status, :string, null: false, default: "pending"
      add :ai_review_generated_at, :utc_datetime
    end
  end
end
