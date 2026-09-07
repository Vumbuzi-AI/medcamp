defmodule Medcamp.Repo.Migrations.MakeCommunityHealthSurveyorNameOptional do
  use Ecto.Migration

  def change do
    alter table(:community_health_survey_responses) do
      modify :surveyor_name, :string, null: true
    end
  end
end
