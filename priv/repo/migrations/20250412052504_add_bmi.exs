defmodule Medcamp.Repo.Migrations.AddBmi do
  use Ecto.Migration

  def change do
    alter table(:triages) do
      add :bmi, :float
    end
  end
end
