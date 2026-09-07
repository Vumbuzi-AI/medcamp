defmodule Medcamp.Repo.Migrations.CreateMchChildHealthTables do
  use Ecto.Migration

  def change do
    create table(:mch_growth_measurements) do
      add :child_id, references(:mch_children, on_delete: :delete_all), null: false
      add :measurement_date, :date
      add :age_months, :integer
      add :weight_kg, :decimal
      add :length_height_cm, :decimal
      add :head_circumference_cm, :decimal
      add :muac_cm, :decimal
      add :nutritional_status, :string
      add :next_visit_date, :date

      timestamps(type: :utc_datetime)
    end

    create table(:mch_immunizations) do
      add :child_id, references(:mch_children, on_delete: :delete_all), null: false
      add :vaccine_name, :string
      add :dose_number, :integer
      add :scheduled_age, :string
      add :date_given, :date
      add :batch_number, :string
      add :next_visit_date, :date

      timestamps(type: :utc_datetime)
    end

    create table(:mch_vitamin_a_supplements) do
      add :child_id, references(:mch_children, on_delete: :delete_all), null: false
      add :dose_iu, :integer
      add :age_months, :integer
      add :date_given, :date

      timestamps(type: :utc_datetime)
    end

    create table(:mch_child_deworming) do
      add :child_id, references(:mch_children, on_delete: :delete_all), null: false
      add :age_months, :integer
      add :medication, :string
      add :dosage_mg, :integer
      add :date_given, :date

      timestamps(type: :utc_datetime)
    end

    create index(:mch_growth_measurements, [:child_id])
    create index(:mch_immunizations, [:child_id])
    create index(:mch_vitamin_a_supplements, [:child_id])
    create index(:mch_child_deworming, [:child_id])
  end
end
