defmodule Medcamp.Repo.Migrations.CreateTodos do
  use Ecto.Migration

  def change do
    create table(:todos) do
      add :title, :string, null: false
      add :description, :text
      add :due_date, :date
      add :status, :string, default: "pending", null: false
      add :priority, :string, default: "medium", null: false
      add :assigned_to_id, references(:users, on_delete: :nilify_all)
      add :created_by_id, references(:users, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:todos, [:assigned_to_id])
    create index(:todos, [:created_by_id])
    create index(:todos, [:status])
    create index(:todos, [:due_date])
  end
end
