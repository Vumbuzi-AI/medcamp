defmodule Elixir.Medcamp.Repo.Migrations.AddLastPeriodDate do
  use Ecto.Migration

  def change do
    alter table(:doctor_notes) do
      add :last_period_date, :date
    end
  end
end
