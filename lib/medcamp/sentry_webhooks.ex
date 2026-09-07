defmodule Medcamp.SentryWebhooks do
  @moduledoc "Persists authenticated Sentry webhook deliveries for admin inspection."

  import Ecto.Query, warn: false

  alias Medcamp.Repo
  alias Medcamp.SentryWebhooks.Delivery

  @retention_days 30

  def create_delivery(attrs) do
    result =
      %Delivery{}
      |> Delivery.changeset(attrs)
      |> Repo.insert()

    if match?({:ok, _delivery}, result), do: delete_expired_deliveries()

    result
  end

  def list_deliveries(limit \\ 100) do
    Delivery
    |> order_by([delivery], desc: delivery.inserted_at, desc: delivery.id)
    |> limit(^min(max(limit, 1), 250))
    |> Repo.all()
  end

  def get_delivery!(id), do: Repo.get!(Delivery, id)

  def delete_expired_deliveries do
    cutoff = DateTime.add(DateTime.utc_now(), -@retention_days, :day)

    Delivery
    |> where([delivery], delivery.inserted_at < ^cutoff)
    |> Repo.delete_all()
  end
end
