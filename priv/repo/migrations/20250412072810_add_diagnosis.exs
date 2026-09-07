defmodule Medcamp.Repo.Migrations.AddDiagnosis do
  use Ecto.Migration

  def change do
    alter table(:doctor_notes) do
      add :diagnosis, :text
      add :investigations, :text
      add :past_medical_history, :text
      add :time, :time
    end
  end
end
