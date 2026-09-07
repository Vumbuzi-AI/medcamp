defmodule Medcamp.Repo.Migrations.AddFullyPaidToAdmissionRequests do
  use Ecto.Migration

  def change do
    alter table(:admission_requests) do
      add :fully_paid, :boolean, default: false, null: false
    end
  end
end
