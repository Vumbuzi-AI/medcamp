defmodule Medcamp.Repo.Migrations.ReplaceAssignedToIdWithNameInTodos do
  use Ecto.Migration

  def change do
    alter table(:todos) do
      remove :assigned_to_id
      add :assigned_to_name, :string
    end
  end
end
