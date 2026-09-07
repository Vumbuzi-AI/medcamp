defmodule Medcamp.Repo.Migrations.CreateRfqInvitations do
  use Ecto.Migration

  def change do
    create table(:rfq_invitations) do
      add :rfq_id, references(:rfqs, on_delete: :delete_all), null: false
      add :supplier_id, references(:suppliers, on_delete: :delete_all), null: false
      add :sent_at, :utc_datetime
      add :viewed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:rfq_invitations, [:rfq_id, :supplier_id])
    create index(:rfq_invitations, [:supplier_id])
  end
end
