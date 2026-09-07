defmodule Medcamp.Repo.Migrations.AddDepartmentIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :department_id, references(:departments, on_delete: :nilify_all)
    end

    create index(:users, [:department_id])
  end
end
