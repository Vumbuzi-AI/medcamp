defmodule Medcamp.Repo.Migrations.AddIsConfirmed do
  use Ecto.Migration

  def change do
    alter table(:drug_batches) do
      add :is_confirmed, :boolean, default: true
      add :confirmed_by, references(:users, on_delete: :nothing), null: true
    end
  end
end
