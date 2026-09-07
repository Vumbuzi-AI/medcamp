defmodule Medcamp.Repo.Migrations.CreateCommunityHealthSurveyResponses do
  use Ecto.Migration

  def change do
    create table(:community_health_survey_responses) do
      add :surveyor_name, :string, null: false
      add :survey_date, :date, null: false
      add :house_number, :string, null: false
      add :adults_count, :integer, null: false, default: 0
      add :children_count, :integer, null: false, default: 0
      add :total_household_members, :integer, null: false, default: 0
      add :has_health_insurance, :string, null: false
      add :insurance_covers, {:array, :string}, null: false, default: []
      add :insurance_providers, {:array, :string}, null: false, default: []
      add :insurance_provider_other, :string
      add :preferred_facility_type, :string, null: false
      add :preferred_facility_other, :string
      add :preferred_facility_name, :string
      add :facility_choice_reasons, {:array, :string}, null: false, default: []
      add :visited_glocal, :string, null: false
      add :glocal_experience_rating, :string
      add :glocal_non_visit_reason, :string
      add :likely_services, {:array, :string}, null: false, default: []
      add :household_conditions, {:array, :string}, null: false, default: []
      add :interested_in_screenings, :string, null: false
      add :wants_updates, :string, null: false
      add :preferred_contact_method, :string
      add :contact_number, :string

      timestamps(type: :utc_datetime)
    end

    create index(:community_health_survey_responses, [:survey_date])
    create index(:community_health_survey_responses, [:inserted_at])
  end
end
