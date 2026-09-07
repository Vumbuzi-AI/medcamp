defmodule Medcamp.Repo.Migrations.CreateSentryWebhookDeliveries do
  use Ecto.Migration

  def change do
    create table(:sentry_webhook_deliveries) do
      add :resource, :string
      add :action, :string
      add :remote_ip, :string
      add :headers, :map, null: false, default: %{}
      add :payload, :map, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:sentry_webhook_deliveries, [:inserted_at])
    create index(:sentry_webhook_deliveries, [:resource])
    create index(:sentry_webhook_deliveries, [:action])
  end
end
