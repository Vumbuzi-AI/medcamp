defmodule Medcamp.Repo.Migrations.AddUrgencyToRequisitions do
  use Ecto.Migration

  def change do
    alter table(:requisitions) do
      add :urgency, :string, default: "normal"
      add :needs_reorder, :boolean, default: false
    end
  end
end
