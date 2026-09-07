defmodule Medcamp.Repo.Migrations.AddTimeToLabResults do
  use Ecto.Migration

  def change do
    alter table(:lab_results) do
      add :time, :time
    end
  end
end
