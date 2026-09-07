defmodule Medcamp.Repo.Migrations.CreateDailyActivities do
  use Ecto.Migration

  def change do
    create table(:daily_activities) do
      add :date, :date, null: false
      add :activity_name, :string, null: false
      # "Do", "ne", "By"
      add :shift, :string, null: false
      add :completed, :boolean, default: false, null: false
      add :completed_at, :utc_datetime
      add :notes, :text
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    # Unique index to prevent duplicate entries
    create unique_index(:daily_activities, [:user_id, :date, :activity_name, :shift],
             name: :daily_activities_user_date_activity_shift_index
           )

    # Index for querying by date range
    create index(:daily_activities, [:date])

    # Index for querying by user
    create index(:daily_activities, [:user_id])

    # Composite index for common queries
    create index(:daily_activities, [:user_id, :date])
  end
end
