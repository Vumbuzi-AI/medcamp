defmodule Medcamp.Repo.Migrations.CreateAllergyHistories do
  use Ecto.Migration

  def change do
    create table(:allergy_histories) do
      add :substance_name, :string, null: false
      add :substance_code, :string
      add :substance_code_system, :string
      add :category, :string, null: false
      add :type, :string, null: false
      add :clinical_status, :string, null: false, default: "active"
      add :verification_status, :string, null: false, default: "unconfirmed"
      add :criticality, :string, null: false
      add :reaction_manifestation, :string
      add :reaction_severity, :string
      add :onset_date, :date
      add :notes, :string
      add :patient_id, references(:patients, on_delete: :delete_all), null: false
      add :recorded_by_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:allergy_histories, [:patient_id])
  end
end
