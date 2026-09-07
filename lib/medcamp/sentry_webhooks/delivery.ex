defmodule Medcamp.SentryWebhooks.Delivery do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sentry_webhook_deliveries" do
    field :resource, :string
    field :action, :string
    field :remote_ip, :string
    field :headers, :map, default: %{}
    field :payload, :map

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(delivery, attrs) do
    delivery
    |> cast(attrs, [:resource, :action, :remote_ip, :headers, :payload])
    |> validate_required([:headers, :payload])
  end
end
