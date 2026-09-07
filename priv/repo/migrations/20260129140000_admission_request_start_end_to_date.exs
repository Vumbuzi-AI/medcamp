defmodule Medcamp.Repo.Migrations.AdmissionRequestStartEndToDate do
  use Ecto.Migration

  def change do
    alter table(:admission_requests) do
      add :date, :date
    end

    create index(:admission_requests, [:date])
  end
end
