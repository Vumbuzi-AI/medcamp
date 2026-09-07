defmodule Medcamp.Repo.Migrations.AddRequisitionIdToInventoriesIssued do
  use Ecto.Migration

  def change do
    alter table(:inventories_issued) do
      add :requisition_id, references(:requisitions, on_delete: :nilify_all)
    end

    create index(:inventories_issued, [:requisition_id])
  end
end
