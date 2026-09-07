defmodule Medcamp.Repo.Migrations.AddPat do
  use Ecto.Migration

  def change do
    alter table(:patient_feedbacks) do
      add :how_did_you_know, :text
      add :how_did_you_know_other, :string
      add :satisfaction_level, :string
      add :service_quality_rating, :integer
      add :staff_helpful, :string
      add :staff_helpful_other, :string
      add :suggestions, :text
    end
  end
end
