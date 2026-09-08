defmodule Medcamp.Repo.Migrations.CreateCampBaseline do
  @moduledoc """
  The whole camp schema in one migration.

  This replaces the 234 incremental migrations the system carried as a
  hospital HMIS. A camp is stood up from an empty database, so there is no
  history worth replaying - and squashing means the surviving tables are
  described once, in their final shape, instead of being assembled from
  dozens of add/rename/drop steps for features that no longer exist.
  """

  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", "DROP EXTENSION IF EXISTS citext"

    ## Accounts ------------------------------------------------------------

    create table(:users) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :utc_datetime
      add :name, :string
      add :image, :string
      add :otp, :string
      add :otp_expires_at, :utc_datetime
      add :experience, :string
      add :phone_number, :string
      add :id_number, :string
      add :license_number, :string
      add :role, :string, default: "doctor"
      add :is_active, :boolean, default: true, null: false
      add :is_for_medical_camp, :boolean, default: false, null: false
      add :last_logged_in_at, :utc_datetime
      add :last_logged_out_at, :utc_datetime
      add :gsrn, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:gsrn])
    create unique_index(:users, [:otp])
    create index(:users, [:role])

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])

    create table(:user_login_sessions) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :logged_in_at, :utc_datetime
      add :logged_out_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:user_login_sessions, [:user_id])

    ## Authorization -------------------------------------------------------

    create table(:permissions) do
      add :slug, :string, null: false
      add :description, :string
      add :resource_area, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:permissions, [:slug])

    create table(:role_permissions) do
      add :role, :string, null: false
      add :permission_id, references(:permissions, on_delete: :delete_all), null: false
      add :granted_by_id, references(:users, on_delete: :nilify_all)
      add :granted_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:role_permissions, [:role, :permission_id])

    create table(:user_permissions) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :permission_id, references(:permissions, on_delete: :delete_all), null: false
      add :effect, :string, null: false
      add :granted_by_id, references(:users, on_delete: :nilify_all)
      add :granted_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_permissions, [:user_id, :permission_id])

    create table(:permission_reviews) do
      add :role, :string, null: false
      add :reviewer_id, references(:users, on_delete: :nilify_all)
      add :reviewed_at, :utc_datetime
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:permission_reviews, [:role])

    create table(:audit_logs) do
      add :user_id, references(:users, on_delete: :nilify_all)
      add :action, :string
      add :table_name, :string
      add :record_id, :integer
      add :previous_state, :map
      add :new_state, :map
      add :changed_fields, {:array, :string}

      timestamps(updated_at: false)
    end

    create index(:audit_logs, [:user_id])
    create index(:audit_logs, [:table_name, :record_id])

    ## Patients ------------------------------------------------------------

    create table(:patients) do
      add :first_name, :string
      add :middle_name, :string
      add :last_name, :string
      add :email, :string
      add :phone_number, :string
      add :national_id, :string
      add :national_id_document, :string
      add :birth_certificate_number, :string
      add :birth_certificate_document, :string
      add :date_of_birth, :date
      add :gender, :string
      add :gsrn, :string
      add :pin, :integer
      add :consent_agreement, :boolean, default: false, null: false
      add :insurance_scheme, :string
      add :insurance_number, :string
      add :insurance_cover_limit, :integer
      add :insurance_company, :string
      add :has_insurance, :boolean, default: false, null: false
      add :is_for_medical_camp, :boolean, default: false, null: false
      add :medical_camp_name, :string
      add :patient_type, :string
      add :home_address, :string
      add :emergency_contact_relationship, :string
      add :emergency_contact_phone_number, :string
      add :emergency_contact_name, :string
      add :creator_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:patients, [:gsrn])
    create index(:patients, [:creator_id])
    create index(:patients, [:phone_number])
    create index(:patients, [:national_id])

    create table(:patient_documents) do
      add :patient_id, references(:patients, on_delete: :delete_all), null: false
      add :document_name, :string
      add :document_type, :string
      add :file_path, :string
      add :content_type, :string

      timestamps(type: :utc_datetime)
    end

    create index(:patient_documents, [:patient_id])

    create table(:allergy_histories) do
      add :patient_id, references(:patients, on_delete: :delete_all), null: false
      add :recorded_by_id, references(:users, on_delete: :nilify_all)
      add :substance_name, :string
      add :substance_code, :string
      add :substance_code_system, :string
      add :category, :string
      add :type, :string
      add :clinical_status, :string, default: "active"
      add :verification_status, :string, default: "unconfirmed"
      add :criticality, :string
      add :reaction_manifestation, :text
      add :reaction_severity, :string
      add :onset_date, :date
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:allergy_histories, [:patient_id])

    ## Visits and triage ---------------------------------------------------

    create table(:patient_visits) do
      add :patient_id, references(:patients, on_delete: :delete_all), null: false
      add :creator_id, references(:users, on_delete: :nilify_all)
      add :doctor_id, references(:users, on_delete: :nilify_all)
      add :reason, :text
      add :date, :date
      add :time, :time
      add :visit_type, :string
      add :status, :string, default: "triage_pending", null: false

      timestamps(type: :utc_datetime)
    end

    create index(:patient_visits, [:patient_id])
    # Every role queue is "today's visits at status X", so this is the index
    # the whole camp floor reads through.
    create index(:patient_visits, [:date, :status])

    create table(:triages) do
      add :patient_id, references(:patients, on_delete: :delete_all), null: false
      add :creator_id, references(:users, on_delete: :nilify_all)
      add :date, :date
      add :time, :time
      add :temperature, :float
      add :blood_pressure, :string
      add :pulse_rate, :float
      add :oxygen_saturation, :float
      add :height, :float
      add :bmi, :float
      add :weight, :float
      add :allergies, :text
      add :emergency_scale, :string
      add :alert, :boolean, default: true
      add :verbal, :boolean, default: true
      add :pain, :boolean, default: false
      add :unresponsive, :boolean, default: false
      add :triage_notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:triages, [:patient_id])
    create index(:triages, [:date])

    ## Doctor notes --------------------------------------------------------

    create table(:doctor_notes) do
      add :patient_id, references(:patients, on_delete: :delete_all), null: false
      add :doctor_id, references(:users, on_delete: :nilify_all)
      add :patient_visit_id, references(:patient_visits, on_delete: :nilify_all)
      add :parent_id, references(:doctor_notes, on_delete: :nilify_all)
      add :date, :date
      add :time, :time
      add :reason_for_consulatation, :text
      add :symptoms, :text
      add :prescribed_medication, :text
      add :lifestyle_recommendations, :text
      add :diagnosis, :text
      add :diagnosis_icd_code, :string
      add :last_period_date, :date
      add :investigations, :text
      add :impression, :text
      add :management, :text
      add :clinical_notes, :text
      add :past_medical_history, :text
      add :lab_imaging_request, :text
      add :ai_review_payload, :map, default: %{}
      add :ai_review_status, :string, default: "pending"
      add :ai_review_generated_at, :utc_datetime
      add :doctor_signature, :text
      add :signed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:doctor_notes, [:patient_id])
    create index(:doctor_notes, [:doctor_id])
    create index(:doctor_notes, [:patient_visit_id])
    create index(:doctor_notes, [:parent_id])
    create index(:doctor_notes, [:date])

    ## Laboratory ----------------------------------------------------------

    create table(:lab_tests) do
      add :name, :string, null: false
      add :desription, :text
      add :price, :integer
      add :subsidized_price, :integer
      add :creator_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:lab_tests, [:name])

    create table(:lab_test_categories) do
      add :name, :string, null: false
      add :description, :text
      add :display_order, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:lab_test_categories, [:name])

    create table(:lab_test_templates) do
      add :category_id, references(:lab_test_categories, on_delete: :nilify_all)
      add :name, :string, null: false
      add :short_name, :string
      add :description, :text
      add :is_active, :boolean, default: true
      add :display_order, :integer, default: 0
      add :field_definitions, {:array, :map}, default: []

      timestamps(type: :utc_datetime)
    end

    create index(:lab_test_templates, [:category_id])

    create table(:lab_results) do
      add :patient_id, references(:patients, on_delete: :delete_all), null: false
      add :doctor_note_id, references(:doctor_notes, on_delete: :nilify_all)
      add :doctor_id, references(:users, on_delete: :nilify_all)
      add :lab_technician_id, references(:users, on_delete: :nilify_all)
      add :name, :string
      add :description, :text
      add :date_of_test, :date
      add :time, :time
      add :urgency, :string
      add :lab_report, :text
      add :test_findings, :text
      add :sample_collection_date, :date
      add :sample_collection_description, :text
      add :technician_name, :string
      add :report_complete, :boolean, default: false
      add :interpretation_payload, :map, default: %{}
      add :interpretation_status, :string, default: "pending"
      add :interpretation_generated_at, :utc_datetime
      add :tests, :map

      timestamps(type: :utc_datetime)
    end

    create index(:lab_results, [:patient_id])
    create index(:lab_results, [:doctor_note_id])
    create index(:lab_results, [:report_complete])

    create table(:lab_test_entries) do
      add :lab_result_id, references(:lab_results, on_delete: :delete_all), null: false
      add :template_id, references(:lab_test_templates, on_delete: :nilify_all)
      add :performed_by_id, references(:users, on_delete: :nilify_all)
      add :verified_by_id, references(:users, on_delete: :nilify_all)
      add :results, :map, default: %{}
      add :remarks, :text
      add :sample_collected_on, :date
      add :test_performed_on, :date
      add :verified_at, :utc_datetime
      add :status, :string, default: "pending"

      timestamps(type: :utc_datetime)
    end

    create index(:lab_test_entries, [:lab_result_id])
    create index(:lab_test_entries, [:template_id])

    ## Pharmacy ------------------------------------------------------------

    # The pharmacy item master: one row per distinct product, keyed by GTIN.
    # The legacy name is kept because the prescribe/dispense pipeline records
    # against `inventory_received_id`.
    create table(:inventories_received) do
      add :user_id, references(:users, on_delete: :nilify_all)
      add :type, :string
      add :description, :text
      add :image, :string
      add :brand_name, :string
      add :generic_name, :string
      add :gtin, :string
      add :supplier, :string
      add :weight, :integer
      add :uom, :string
      add :category, :string
      add :strength, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:inventories_received, [:gtin])

    create table(:drugs) do
      add :inventory_received_id, references(:inventories_received, on_delete: :delete_all)
      add :inventory_manager_id, references(:users, on_delete: :nilify_all)
      add :generic_name, :string
      add :brand_name, :string
      add :is_otc, :boolean, default: false
      add :is_dangerous_drug, :boolean, default: false

      timestamps(type: :utc_datetime)
    end

    create index(:drugs, [:inventory_received_id])

    create table(:batches) do
      add :inventory_received_id, references(:inventories_received, on_delete: :nilify_all)
      add :inventory_manager_id, references(:users, on_delete: :nilify_all)
      add :serial, :string
      add :gtin, :string
      add :batch, :string
      add :expiry, :string
      add :manufacturer, :string
      add :uom, :string
      add :weight, :float
      add :received_date, :date
      add :manufacture_date, :date
      add :quantity, :integer
      add :remaining_quantity, :integer

      timestamps(type: :utc_datetime)
    end

    # A DataMatrix scan resolves a pack by GTIN + batch, so that pair is the
    # lookup the pharmacy floor hits on every scan-in and scan-out.
    create index(:batches, [:gtin, :batch])

    create table(:drug_batches) do
      add :drug_id, references(:drugs, on_delete: :delete_all), null: false
      add :batch_id, references(:batches, on_delete: :delete_all), null: false
      add :inventory_received_id, references(:inventories_received, on_delete: :nilify_all)
      add :inventory_manager_id, references(:users, on_delete: :nilify_all)
      add :confirmed_by, references(:users, on_delete: :nilify_all)
      add :remaining_quantity, :integer
      add :is_confirmed, :boolean, default: false
      add :is_active, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    create index(:drug_batches, [:drug_id])
    create index(:drug_batches, [:batch_id])
    create index(:drug_batches, [:is_confirmed])

    create table(:drug_allocations) do
      add :patient_id, references(:patients, on_delete: :delete_all), null: false
      add :doctor_note_id, references(:doctor_notes, on_delete: :nilify_all)
      add :doctor_id, references(:users, on_delete: :nilify_all)
      add :pharmacist_id, references(:users, on_delete: :nilify_all)
      add :quantity, :integer
      add :prescription, :text
      add :has_been_assigned, :boolean, default: false
      add :if_prompted_by_pharmacist, :boolean, default: false
      add :drugs_assigned, :map

      timestamps(type: :utc_datetime)
    end

    create index(:drug_allocations, [:patient_id])
    create index(:drug_allocations, [:doctor_note_id])
    create index(:drug_allocations, [:has_been_assigned])

    create table(:drugs_given) do
      add :drug_allocation_id, references(:drug_allocations, on_delete: :delete_all), null: false
      add :drug_id, references(:drugs, on_delete: :nilify_all)
      add :pharmacist_id, references(:users, on_delete: :nilify_all)
      add :quantity, :integer
      add :price, :integer
      add :batch_allocations, :map

      timestamps(type: :utc_datetime)
    end

    create index(:drugs_given, [:drug_allocation_id])
    create index(:drugs_given, [:drug_id])
  end
end
