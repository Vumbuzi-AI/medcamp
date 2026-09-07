defmodule Medcamp.Repo.Migrations.AddPaymentType do
  use Ecto.Migration

  def change do
    alter table(:patient_visits) do
      add :payment_type, :string
    end
  end
end
