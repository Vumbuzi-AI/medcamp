defmodule Medcamp.Repo.Migrations.AddDepartmentIdToStockTakes do
  use Ecto.Migration

  def change do
    alter table(:stock_takes) do
      add :department_id, references(:departments, on_delete: :nilify_all)
    end

    create index(:stock_takes, [:department_id])
  end
end
