defmodule Medcamp.Repo.Migrations.AddPinToPatients do
  use Ecto.Migration

  def change do
    alter table(:patients) do
      add :pin, :integer
    end
  end
end
