defmodule Medcamp.Repo.Migrations.CreateQualityAssuranceCharts do
  use Ecto.Migration

  def change do
    create table(:quality_assurance_charts) do
      add :chart_type, :string, null: false
      add :month, :integer, null: false
      add :year, :integer, null: false
      add :created_by_id, references(:users, on_delete: :nothing)

      # JSONB field to store daily entries flexibly
      # For temperature charts: {day: {morning: {temp, status, tech_initials}, afternoon: {temp, status, tech_initials}}}
      # For maintenance charts: {day: {task_name: status, tech_initials: initials}}
      add :daily_entries, :jsonb, default: "{}"

      timestamps(type: :utc_datetime)
    end

    create index(:quality_assurance_charts, [:chart_type, :month, :year])
    create index(:quality_assurance_charts, [:created_by_id])

    create unique_index(:quality_assurance_charts, [:chart_type, :month, :year],
             name: :unique_chart_per_month
           )
  end
end
