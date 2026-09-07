defmodule Medcamp.Repo.Migrations.UpdateMpesasActionables do
  use Ecto.Migration

  def change do
    alter table(:mpesas) do
      add :actionable_id, :integer
      add :actionable_type, :string
    end
  end
end
