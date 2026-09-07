defmodule Medcamp.Repo.Migrations.AddIsDangerousDrugToDrugs do
  use Ecto.Migration

  def change do
    alter table(:drugs) do
      add :is_dangerous_drug, :boolean, default: false, null: false
    end
  end
end
