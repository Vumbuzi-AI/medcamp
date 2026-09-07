defmodule Medcamp.Repo.Migrations.AddMchChildMonitoringRecords do
  use Ecto.Migration

  def change do
    alter table(:mch_immunizations) do
      add :adverse_event, :boolean
      add :adverse_event_description, :text
    end

    create table(:mch_developmental_milestones) do
      add :child_id, references(:mch_children, on_delete: :delete_all), null: false
      add :milestone_name, :string
      add :expected_age_range, :string
      add :age_achieved_months, :integer
      add :status, :string
      add :assessment_date, :date

      timestamps(type: :utc_datetime)
    end

    create table(:mch_eye_assessments) do
      add :child_id, references(:mch_children, on_delete: :delete_all), null: false
      add :assessment_date, :date
      add :age_at_assessment, :string
      add :teo_given, :boolean
      add :pupil_color, :string
      add :follows_objects, :boolean
      add :has_squint, :boolean
      add :other_problems, :boolean
      add :other_problems_description, :text
      add :referred, :boolean

      timestamps(type: :utc_datetime)
    end

    create index(:mch_developmental_milestones, [:child_id])
    create index(:mch_eye_assessments, [:child_id])
  end
end
