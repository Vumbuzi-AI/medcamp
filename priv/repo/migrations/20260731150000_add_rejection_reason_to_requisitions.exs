defmodule Medcamp.Repo.Migrations.AddRejectionReasonToRequisitions do
  use Ecto.Migration

  def change do
    alter table(:requisitions) do
      add :rejection_reason, :string
    end
  end
end
