# lib/medcamp/repo.ex
defmodule Medcamp.Repo do
  use Ecto.Repo,
    otp_app: :medcamp,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 10

  require Logger

  # Store audit user in process dictionary
  def put_audit_user(user_id) do
    Process.put(:audit_user_id, user_id)
  end

  def get_audit_user do
    Process.get(:audit_user_id)
  end

  # Audited wrapper functions
  def audited_insert(changeset_or_struct, opts \\ []) do
    user_id = get_user_id(opts)

    # Use __MODULE__
    case __MODULE__.insert(changeset_or_struct, opts) do
      {:ok, result} = success ->
        log_change_async(:insert, changeset_or_struct, result, user_id)
        success

      error ->
        error
    end
  end

  def audited_insert!(changeset_or_struct, opts \\ []) do
    user_id = get_user_id(opts)
    # Use __MODULE__
    result = __MODULE__.insert!(changeset_or_struct, opts)
    log_change_async(:insert, changeset_or_struct, result, user_id)
    result
  end

  @spec audited_update(Ecto.Changeset.t()) :: any()
  def audited_update(changeset_or_struct, opts \\ []) do
    user_id = get_user_id(opts)

    # Use __MODULE__
    case __MODULE__.update(changeset_or_struct, opts) do
      {:ok, result} = success ->
        log_change_async(:update, changeset_or_struct, result, user_id)
        success

      error ->
        error
    end
  end

  def audited_update!(changeset_or_struct, opts \\ []) do
    user_id = get_user_id(opts)
    # Use __MODULE__
    result = __MODULE__.update!(changeset_or_struct, opts)
    log_change_async(:update, changeset_or_struct, result, user_id)
    result
  end

  def audited_delete(struct, opts \\ []) do
    user_id = get_user_id(opts)

    # Use __MODULE__
    case __MODULE__.delete(struct, opts) do
      {:ok, result} = success ->
        log_change_async(:delete, struct, result, user_id)
        success

      error ->
        error
    end
  end

  def audited_delete!(struct, opts \\ []) do
    user_id = get_user_id(opts)
    # Use __MODULE__
    result = __MODULE__.delete!(struct, opts)
    log_change_async(:delete, struct, result, user_id)
    result
  end

  # Private helper functions

  defp get_user_id(opts) do
    Keyword.get(opts, :audit_user_id) || get_audit_user()
  end

  defp log_change_async(action, changeset_or_struct, result, user_id) do
    # Run in background task to avoid slowing down requests
    Task.start(fn ->
      log_change(action, changeset_or_struct, result, user_id)
    end)
  end

  defp log_change(_action, _changeset, _result, nil), do: :ok

  defp log_change(:update, %Ecto.Changeset{} = changeset, result, user_id) do
    # Only log if there were actual changes
    if changeset.changes != %{} do
      previous_state =
        changeset.data
        |> Map.from_struct()
        |> sanitize_state()

      new_state =
        result
        |> Map.from_struct()
        |> sanitize_state()

      attrs = %{
        user_id: user_id,
        action: "update",
        table_name: table_name(result),
        record_id: get_record_id(result),
        previous_state: previous_state,
        new_state: new_state,
        changed_fields: Map.keys(changeset.changes) |> Enum.map(&to_string/1)
      }

      %Medcamp.AuditLog{}
      |> Medcamp.AuditLog.changeset(attrs)
      # Use __MODULE__
      |> __MODULE__.insert()
    end
  rescue
    e ->
      Logger.error("Failed to create audit log: #{inspect(e)}")
      :ok
  end

  defp log_change(:delete, struct, _result, user_id) do
    previous_state =
      struct
      |> Map.from_struct()
      |> sanitize_state()

    attrs = %{
      user_id: user_id,
      action: "delete",
      table_name: table_name(struct),
      record_id: get_record_id(struct),
      previous_state: previous_state,
      new_state: nil,
      changed_fields: []
    }

    %Medcamp.AuditLog{}
    |> Medcamp.AuditLog.changeset(attrs)
    # Use __MODULE__
    |> __MODULE__.insert()
  rescue
    e ->
      Logger.error("Failed to create audit log: #{inspect(e)}")
      :ok
  end

  defp log_change(:insert, _changeset, result, user_id) do
    new_state =
      result
      |> Map.from_struct()
      |> sanitize_state()

    attrs = %{
      user_id: user_id,
      action: "insert",
      table_name: table_name(result),
      record_id: get_record_id(result),
      previous_state: nil,
      new_state: new_state,
      changed_fields: []
    }

    %Medcamp.AuditLog{}
    |> Medcamp.AuditLog.changeset(attrs)
    # Use __MODULE__
    |> __MODULE__.insert()
  rescue
    e ->
      Logger.error("Failed to create audit log: #{inspect(e)}")
      :ok
  end

  defp table_name(%module{}), do: module.__schema__(:source)

  defp get_record_id(%{id: id}), do: id
  defp get_record_id(_), do: nil
  # Remove metadata and associations from state
  defp sanitize_state(state) do
    state
    |> Map.drop([:__meta__, :__struct__])
    |> Enum.reject(fn {_k, v} -> is_struct(v, Ecto.Association.NotLoaded) end)
    |> Enum.map(fn {k, v} -> {k, sanitize_value(v)} end)
    |> Map.new()
  end

  # Convert special types to JSON-safe values
  defp sanitize_value(%Decimal{} = decimal), do: Decimal.to_string(decimal)
  defp sanitize_value(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp sanitize_value(%NaiveDateTime{} = ndt), do: NaiveDateTime.to_iso8601(ndt)
  defp sanitize_value(%Date{} = date), do: Date.to_iso8601(date)
  defp sanitize_value(%Time{} = time), do: Time.to_iso8601(time)
  defp sanitize_value(%Ecto.Association.NotLoaded{}), do: nil

  defp sanitize_value(value) when is_struct(value) do
    if function_exported?(value.__struct__, :__schema__, 1) do
      value |> Map.from_struct() |> sanitize_state()
    else
      nil
    end
  end

  defp sanitize_value(value), do: value
end
