defmodule Medcamp.Repo.Migrations.CreateAuditLogs do
  use Ecto.Migration

  def change do
    create table(:audit_logs) do
      add :user_id, references(:users, on_delete: :nilify_all)
      add :action, :string, null: false
      add :table_name, :string, null: false
      add :record_id, :integer, null: false
      add :previous_state, :map
      add :new_state, :map
      add :changed_fields, {:array, :string}

      timestamps(updated_at: false)
    end

    create index(:audit_logs, [:user_id])
    create index(:audit_logs, [:table_name, :record_id])
    create index(:audit_logs, [:inserted_at])
    create index(:audit_logs, [:action])
  end
end
