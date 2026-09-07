defmodule Medcamp.Repo.Migrations.SimplifyDailyActivities do
  use Ecto.Migration

  def change do
    # Drop the old unique index that included shift
    drop unique_index(:daily_activities, [:user_id, :date, :activity_name, :shift],
           name: :daily_activities_user_date_activity_shift_index
         )

    # Remove the shift column - no longer needed
    alter table(:daily_activities) do
      remove :shift, :string
    end

    # Create new unique index - only ONE record per activity per day
    # This ensures each activity can only be done once per day (by whoever does it first)
    create unique_index(:daily_activities, [:date, :activity_name],
             name: :daily_activities_date_activity_index
           )
  end
end
