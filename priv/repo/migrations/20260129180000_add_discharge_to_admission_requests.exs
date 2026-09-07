defmodule Medcamp.Repo.Migrations.AddDischargeToAdmissionRequests do
  use Ecto.Migration

  def change do
    alter table(:admission_requests) do
      add :discharge_date, :date
      add :discharged, :boolean, default: false, null: false
    end
  end
end
