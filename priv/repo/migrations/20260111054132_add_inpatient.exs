defmodule Medcamp.Repo.Migrations.AddInpatientTables do
  use Ecto.Migration

  def change do
    drop_if_exists table(:discharge_summaries)
    drop_if_exists table(:vital_records)
    drop_if_exists table(:treatment_sheets)
    drop_if_exists table(:continuation_notes)
    drop_if_exists table(:admission_notes)
    # 1. Admission Notes
    create table(:admission_notes) do
      add :admission_date, :date, null: false
      add :admission_time, :time, null: false
      add :complaints, :text
      add :history_of_presenting_illness, :text
      add :physical_examination, :text
      add :management_plan, :text
      add :ward, :string
      add :bed_number, :string

      # Vital signs at admission
      add :blood_pressure, :string
      add :pulse_rate, :integer
      add :temperature, :decimal, precision: 4, scale: 1
      add :spo2, :integer
      add :respiratory_rate, :integer

      add :patient_id, references(:patients, on_delete: :delete_all), null: false
      add :doctor_id, references(:users, on_delete: :nilify_all), null: false
      add :doctor_note_id, references(:doctor_notes, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:admission_notes, [:patient_id])
    create index(:admission_notes, [:doctor_id])
    create index(:admission_notes, [:doctor_note_id])
    create index(:admission_notes, [:admission_date])

    # 2. Continuation Notes
    create table(:continuation_notes) do
      add :review_date, :date, null: false
      add :review_time, :time, null: false
      add :review_type, :string, null: false
      add :complaints, :text
      add :physical_examination, :text
      add :management_plan, :text

      # Vital signs at review
      add :blood_pressure, :string
      add :pulse_rate, :integer
      add :temperature, :decimal, precision: 4, scale: 1
      add :spo2, :integer
      add :respiratory_rate, :integer

      add :admission_note_id, references(:admission_notes, on_delete: :delete_all), null: false
      add :doctor_id, references(:users, on_delete: :nilify_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:continuation_notes, [:admission_note_id])
    create index(:continuation_notes, [:doctor_id])
    create index(:continuation_notes, [:review_date])

    # 3. Treatment Sheets
    create table(:treatment_sheets) do
      add :prescription_date, :date, null: false
      add :prescription_time, :time
      add :prescription_type, :string, default: "Regular"
      add :drug_name, :string, null: false
      add :route, :string, null: false
      add :dose, :string, null: false
      add :units, :string
      add :frequency, :string, null: false
      add :duration_days, :integer
      add :notes, :text

      # Embedded JSON for administrations
      add :administrations, :map, default: "[]"

      add :admission_note_id, references(:admission_notes, on_delete: :delete_all), null: false
      add :prescriber_id, references(:users, on_delete: :nilify_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:treatment_sheets, [:admission_note_id])
    create index(:treatment_sheets, [:prescriber_id])
    create index(:treatment_sheets, [:prescription_date])

    # 4. Vital Records
    create table(:vital_records) do
      add :recorded_date, :date, null: false
      add :recorded_time, :time, null: false
      add :blood_pressure, :string
      add :pulse_rate, :integer
      add :temperature, :decimal, precision: 4, scale: 1
      add :spo2, :integer
      add :respiratory_rate, :integer
      add :remarks, :text

      add :admission_note_id, references(:admission_notes, on_delete: :delete_all), null: false
      add :recorded_by_id, references(:users, on_delete: :nilify_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:vital_records, [:admission_note_id])
    create index(:vital_records, [:recorded_by_id])
    create index(:vital_records, [:recorded_date, :recorded_time])

    # 5. Discharge Summaries
    create table(:discharge_summaries) do
      add :discharge_date, :date, null: false
      add :admission_diagnosis, :text
      add :discharge_diagnosis, :text, null: false
      add :clinical_history, :text
      add :physical_examination, :text
      add :procedures_done, :text
      add :lab_investigations, :text
      add :drugs_given, :text
      add :discharge_drugs, :text
      add :follow_up_date, :date
      add :follow_up_clinic, :string
      add :doctor_notes, :text

      add :admission_note_id, references(:admission_notes, on_delete: :delete_all), null: false
      add :doctor_id, references(:users, on_delete: :nilify_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:discharge_summaries, [:admission_note_id])
    create index(:discharge_summaries, [:doctor_id])
    create index(:discharge_summaries, [:discharge_date])
  end
end
