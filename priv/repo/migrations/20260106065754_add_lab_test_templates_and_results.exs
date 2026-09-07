defmodule Medcamp.Repo.Migrations.CreateLabTestTemplatesAndResults do
  use Ecto.Migration

  def change do
    # =========================================================================
    # LAB TEST CATEGORIES (e.g., Blood Tests, Urine Tests, etc.)
    # =========================================================================
    create table(:lab_test_categories) do
      add :name, :string, null: false
      add :description, :text
      add :display_order, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:lab_test_categories, [:name])

    # =========================================================================
    # LAB TEST TEMPLATES (defines each test type and its structure)
    # =========================================================================
    create table(:lab_test_templates) do
      # e.g., "Full Haemogram Test (FBC)"
      add :name, :string, null: false
      # e.g., "FBC"
      add :short_name, :string
      add :description, :text
      add :category_id, references(:lab_test_categories, on_delete: :restrict)
      add :is_active, :boolean, default: true
      add :display_order, :integer, default: 0

      # Template structure - defines what fields this test has
      add :field_definitions, :jsonb, null: false, default: "[]"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:lab_test_templates, [:name])
    create index(:lab_test_templates, [:category_id])
    create index(:lab_test_templates, [:is_active])

    # =========================================================================
    # LAB TEST ENTRIES (actual patient results for each test)
    # =========================================================================
    create table(:lab_test_entries) do
      add :lab_result_id, references(:lab_results, on_delete: :delete_all), null: false
      add :template_id, references(:lab_test_templates, on_delete: :restrict), null: false

      # The actual results stored as JSON
      add :results, :jsonb, null: false, default: "{}"

      add :remarks, :text
      add :sample_collected_on, :date
      add :test_performed_on, :date
      add :performed_by_id, references(:users, on_delete: :nilify_all)
      add :verified_by_id, references(:users, on_delete: :nilify_all)
      add :verified_at, :utc_datetime
      # pending, completed, verified
      add :status, :string, default: "pending"

      timestamps(type: :utc_datetime)
    end

    create index(:lab_test_entries, [:lab_result_id])
    create index(:lab_test_entries, [:template_id])
    create index(:lab_test_entries, [:status])

    create unique_index(:lab_test_entries, [:lab_result_id, :template_id],
             name: :lab_test_entries_unique_test_per_request
           )
  end
end
