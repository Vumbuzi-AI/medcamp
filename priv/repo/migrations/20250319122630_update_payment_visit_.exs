defmodule Medcamp.Repo.Migrations.UpdatePaymentVisit do
  use Ecto.Migration

  def change do
    alter table(:patient_visits) do
      add :has_paid, :boolean, default: false
    end
  end
end
