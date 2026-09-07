defmodule Medcamp.Repo.Migrations.AddStartEndTimeToAdmissionRequests do
  use Ecto.Migration

  def change do
    alter table(:admission_requests) do
      add :start_time, :time
      add :end_time, :time
    end
  end
end
