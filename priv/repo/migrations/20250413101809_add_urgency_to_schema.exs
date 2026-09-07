defmodule Medcamp.Repo.Migrations.AddUrgencyToSchema do
  use Ecto.Migration

  def change do
    alter table(:radiology_results) do
      add :urgency, :string
    end
  end
end
