defmodule Medcamp.Repo.Migrations.AddDrugsGiven do
  use Ecto.Migration

  def change do
    alter table(:drug_allocations) do
      add :drugs_given, :jsonb, default: "[]"
    end
  end
end
