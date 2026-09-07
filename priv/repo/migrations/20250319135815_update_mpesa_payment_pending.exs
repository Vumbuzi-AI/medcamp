defmodule Medcamp.Repo.Migrations.UpdateMpesaPaymentPending do
  use Ecto.Migration

  def change do
    alter table(:mpesas) do
      add :payment_pending, :boolean, default: true
    end
  end
end
