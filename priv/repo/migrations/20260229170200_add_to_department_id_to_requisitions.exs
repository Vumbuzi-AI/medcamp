defmodule Medcamp.Repo.Migrations.AddToDepartmentIdToRequisitions do
  use Ecto.Migration

  def change do
    alter table(:requisitions) do
      add :to_department_id, references(:departments, on_delete: :nilify_all)
    end

    create index(:requisitions, [:to_department_id])
  end
end
