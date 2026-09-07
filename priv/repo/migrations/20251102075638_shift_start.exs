defmodule Medcamp.Repo.Migrations.ShiftStart do
  use Ecto.Migration

  def change do
    alter table(:shift_handovers) do
      add :shift_start, :date
    end
  end
end
