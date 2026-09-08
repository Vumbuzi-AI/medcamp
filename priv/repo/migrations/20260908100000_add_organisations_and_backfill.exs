defmodule Medcamp.Repo.Migrations.AddOrganisationsAndBackfill do
  @moduledoc """
  Makes the camp system multi-tenant.

  Every clinical and operational table gains an `organisation_id`. The column
  is added nullable, backfilled to a single "Default Organisation" that owns
  all pre-existing data, and only then made `NOT NULL` - so an existing camp
  database migrates forward without losing a row.

  `mix ecto.drop`/`ecto.reset` are deliberately blocked on this project, so
  this is written to be forward-only-safe against live data.
  """

  use Ecto.Migration

  # Tables whose rows belong to exactly one organisation.
  #
  # Not listed, deliberately: `permissions` and `role_permissions` are the
  # global panel catalogue that `Medcamp.Authorization.PanelSync` maintains
  # and every tenant shares; `user_permissions` and `users_tokens` are only
  # ever reachable through a `user_id` that is itself scoped.
  @tenant_tables ~w(
    users
    user_login_sessions
    permission_reviews
    audit_logs
    patients
    patient_documents
    allergy_histories
    patient_visits
    triages
    doctor_notes
    lab_tests
    lab_test_categories
    lab_test_templates
    lab_results
    lab_test_entries
    inventories_received
    drugs
    batches
    drug_batches
    drug_allocations
    drugs_given
  )a

  def up do
    create table(:organisations) do
      add :name, :string, null: false
      add :slug, :citext, null: false
      add :email, :string
      add :phone_number, :string
      add :location, :string
      add :logo, :string
      add :primary_color, :string, null: false, default: "#373896"
      add :accent_color, :string, null: false, default: "#6667ab"
      add :is_active, :boolean, null: false, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organisations, [:slug])

    flush()

    # The organisation every existing row is handed to.
    execute """
    INSERT INTO organisations
      (name, slug, location, logo, primary_color, accent_color, is_active, inserted_at, updated_at)
    VALUES
      ('GHC Excellence', 'default', 'Kenya', '/images/logo.png',
       '#373896', '#6667ab', true, NOW(), NOW())
    """

    for table <- @tenant_tables do
      alter table(table) do
        add :organisation_id, references(:organisations, on_delete: :restrict)
      end
    end

    flush()

    for table <- @tenant_tables do
      execute """
      UPDATE #{table}
      SET organisation_id = (SELECT id FROM organisations WHERE slug = 'default')
      WHERE organisation_id IS NULL
      """
    end

    flush()

    for table <- @tenant_tables do
      alter table(table) do
        modify :organisation_id, :bigint, null: false
      end

      create index(table, [:organisation_id])
    end

    # These three were globally unique when there was only one tenant. They
    # are properly unique per organisation: two camps may both stock the same
    # GTIN and both define a "Full Haemogram".
    drop unique_index(:lab_tests, [:name])
    create unique_index(:lab_tests, [:organisation_id, :name])

    drop unique_index(:lab_test_categories, [:name])
    create unique_index(:lab_test_categories, [:organisation_id, :name])

    drop unique_index(:inventories_received, [:gtin])
    create unique_index(:inventories_received, [:organisation_id, :gtin])

    # Login happens before we know the organisation, so `users.email`,
    # `users.gsrn` and `patients.gsrn` stay globally unique on purpose.

    alter table(:users) do
      add :is_superadmin, :boolean, null: false, default: false
    end
  end

  def down do
    alter table(:users) do
      remove :is_superadmin
    end

    drop unique_index(:inventories_received, [:organisation_id, :gtin])
    create unique_index(:inventories_received, [:gtin])

    drop unique_index(:lab_test_categories, [:organisation_id, :name])
    create unique_index(:lab_test_categories, [:name])

    drop unique_index(:lab_tests, [:organisation_id, :name])
    create unique_index(:lab_tests, [:name])

    for table <- @tenant_tables do
      drop index(table, [:organisation_id])

      alter table(table) do
        remove :organisation_id
      end
    end

    drop table(:organisations)
  end
end
