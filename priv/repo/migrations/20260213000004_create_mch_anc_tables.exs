defmodule Medcamp.Repo.Migrations.CreateMchAncTables do
  use Ecto.Migration

  def change do
    create table(:mch_antenatal_profiles) do
      add :pregnancy_id, references(:mch_pregnancies, on_delete: :delete_all), null: false
      add :haemoglobin_hb, :decimal
      add :blood_group, :string
      add :rhesus_factor, :string
      add :urinalysis, :string
      add :blood_rbs, :decimal
      add :tb_screening_date, :date
      add :tb_screening_outcome, :string
      add :triple_test_date, :date
      add :hiv_status, :string
      add :syphilis_status, :string
      add :hepatitis_b_status, :string

      timestamps(type: :utc_datetime)
    end

    create table(:mch_physical_examinations) do
      add :pregnancy_id, references(:mch_pregnancies, on_delete: :delete_all), null: false
      add :examination_date, :date
      add :bp_systolic, :integer
      add :bp_diastolic, :integer
      add :pulse_rate, :integer
      add :cvs_notes, :string
      add :respiratory_notes, :string
      add :breasts_notes, :string
      add :abdomen_notes, :string

      timestamps(type: :utc_datetime)
    end

    create table(:mch_anc_visits) do
      add :pregnancy_id, references(:mch_pregnancies, on_delete: :delete_all), null: false
      add :contact_number, :integer
      add :visit_date, :date
      add :urine_test, :string
      add :muac_cm, :decimal
      add :bp_systolic, :integer
      add :bp_diastolic, :integer
      add :haemoglobin, :decimal
      add :pallor, :boolean
      add :gestation_weeks, :integer
      add :fundal_height, :decimal
      add :presentation, :string
      add :lie, :string
      add :foetal_heart_rate, :integer
      add :foetal_movement, :string
      add :next_visit_date, :date
      add :weight_kg, :decimal

      timestamps(type: :utc_datetime)
    end

    create table(:mch_td_vaccinations) do
      add :mother_id, references(:mch_mothers, on_delete: :delete_all), null: false
      add :dose_number, :integer
      add :date_given, :date
      add :next_visit, :date

      timestamps(type: :utc_datetime)
    end

    create table(:mch_malaria_prophylaxis) do
      add :pregnancy_id, references(:mch_pregnancies, on_delete: :delete_all), null: false
      add :dose_number, :integer
      add :date_given, :date

      timestamps(type: :utc_datetime)
    end

    create table(:mch_ifas_supplements) do
      add :pregnancy_id, references(:mch_pregnancies, on_delete: :delete_all), null: false
      add :contact_number, :integer
      add :gestation_weeks, :integer
      add :tablets_issued, :integer
      add :date_given, :date

      timestamps(type: :utc_datetime)
    end

    create table(:mch_deworming_maternal) do
      add :pregnancy_id, references(:mch_pregnancies, on_delete: :delete_all), null: false
      add :date_given, :date
      add :medication, :string, default: "Mebendazole 500mg"

      timestamps(type: :utc_datetime)
    end

    create index(:mch_antenatal_profiles, [:pregnancy_id])
    create index(:mch_physical_examinations, [:pregnancy_id])
    create index(:mch_anc_visits, [:pregnancy_id])
    create index(:mch_td_vaccinations, [:mother_id])
    create index(:mch_malaria_prophylaxis, [:pregnancy_id])
    create index(:mch_ifas_supplements, [:pregnancy_id])
    create index(:mch_deworming_maternal, [:pregnancy_id])
  end
end
