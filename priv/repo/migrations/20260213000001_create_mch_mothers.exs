defmodule Medcamp.Repo.Migrations.CreateMchMothers do
  use Ecto.Migration

  def change do
    create table(:mch_mothers) do
      add :patient_id, references(:patients, on_delete: :nothing), null: false
      add :gravida, :integer
      add :parity, :integer
      add :height_cm, :decimal
      add :lmp, :date
      add :edd, :date
      add :marital_status, :string
      add :education_level, :string
      add :county, :string
      add :subcounty, :string
      add :ward, :string
      add :town_village, :string
      add :physical_address, :string
      add :next_of_kin_name, :string
      add :next_of_kin_relationship, :string
      add :next_of_kin_phone, :string
      add :health_facility_name, :string
      add :kmhfl_code, :string
      add :anc_number, :string
      add :pnc_number, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:mch_mothers, [:patient_id])
  end
end
