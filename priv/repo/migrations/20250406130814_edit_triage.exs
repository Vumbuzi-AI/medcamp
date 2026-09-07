defmodule Medcamp.Repo.Migrations.EditTriage do
  use Ecto.Migration

  def change do
    alter table(:triages) do
      add :time, :time
      add :allergies, :text
      add :emergency_scale, :string
      modify :blood_pressure, :string
      add :alert, :boolean, default: true
      add :verbal, :boolean, default: true
      add :pain, :boolean, default: true
      add :unresponsive, :boolean, default: true
    end
  end
end
