defmodule Medcamp.Repo.Migrations.AddApprovalToStockTakes do
  use Ecto.Migration

  def change do
    alter table(:stock_takes) do
      add :requested_by_id, references(:users, on_delete: :nilify_all)
      add :approved_by_id, references(:users, on_delete: :nilify_all)
      add :approved_at, :utc_datetime
    end

    create index(:stock_takes, [:requested_by_id])
    create index(:stock_takes, [:approved_by_id])

    # Requester-initiated stock takes have no admin until they are approved,
    # so admin_id can no longer be mandatory. Touch only the NOT NULL
    # constraint to leave the existing foreign key intact.
    execute(
      "ALTER TABLE stock_takes ALTER COLUMN admin_id DROP NOT NULL",
      "ALTER TABLE stock_takes ALTER COLUMN admin_id SET NOT NULL"
    )
  end
end
