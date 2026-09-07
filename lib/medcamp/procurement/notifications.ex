defmodule Medcamp.Procurement.Notifications do
  @moduledoc """
  Create and query procurement notifications and mirror them to email.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.Accounts.User
  alias Medcamp.Procurement.ProcurementNotification
  alias Medcamp.Postal

  @pubsub Medcamp.PubSub

  @doc """
  Create a notification, broadcast it on the user's notifications topic, and
  send an email to the same user when an email address is available.
  """
  def notify(user_id, type, attrs, mailer \\ Postal)
      when is_integer(user_id) and is_binary(type) do
    params =
      attrs
      |> Map.new()
      |> Map.merge(%{user_id: user_id, type: type})

    %ProcurementNotification{}
    |> ProcurementNotification.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, notif} ->
        Phoenix.PubSub.broadcast(@pubsub, "user:#{user_id}:notifications", {:notification, notif})
        maybe_send_email(user_id, notif, mailer)
        {:ok, notif}

      error ->
        error
    end
  end

  def list_for_user(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    from(n in ProcurementNotification,
      where: n.user_id == ^user_id,
      order_by: [desc: n.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  def unread_count(user_id) do
    from(n in ProcurementNotification,
      where: n.user_id == ^user_id and n.read == false
    )
    |> Repo.aggregate(:count, :id)
  end

  def mark_read(%ProcurementNotification{} = notification) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    notification
    |> ProcurementNotification.changeset(%{read: true, read_at: now})
    |> Repo.update()
  end

  def mark_read(id) when is_integer(id) or is_binary(id) do
    case Repo.get(ProcurementNotification, id) do
      nil -> {:error, :not_found}
      notif -> mark_read(notif)
    end
  end

  def mark_all_read(user_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    {count, _} =
      from(n in ProcurementNotification,
        where: n.user_id == ^user_id and n.read == false
      )
      |> Repo.update_all(set: [read: true, read_at: now])

    {:ok, count}
  end

  defp maybe_send_email(user_id, %ProcurementNotification{} = notif, mailer) do
    case Repo.get(User, user_id) do
      %User{email: email} when is_binary(email) ->
        if String.trim(email) != "" do
          subject = notif.title || humanize_type(notif.type)
          body = email_body(notif)
          _ = mailer.deliver(email, subject, body)
        end

        :ok

      _ ->
        :ok
    end
  end

  defp email_body(%ProcurementNotification{} = notif) do
    [
      notif.title,
      "",
      notif.body,
      resource_line(notif),
      "",
      "Open Medcamp to review the full details."
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end

  defp resource_line(%ProcurementNotification{
         resource_type: resource_type,
         resource_id: resource_id
       })
       when is_binary(resource_type) and not is_nil(resource_id) do
    "Reference: #{resource_type} ##{resource_id}"
  end

  defp resource_line(_), do: nil

  defp humanize_type(type) when is_binary(type) do
    type
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
