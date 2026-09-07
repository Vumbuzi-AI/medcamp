defmodule Medcamp.Repo.Migrations.AddShiftHandover do
  use Ecto.Migration

  def change do
    alter table(:shift_handovers) do
      add :daily_coldchain_temperature_log, :text
      add :dangerous_drug_register, :text
      add :equipment_maintenance_log, :text
    end
  end
end
