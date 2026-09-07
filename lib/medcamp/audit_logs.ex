defmodule Medcamp.Audit do
  @moduledoc """
  Context for managing and querying audit logs.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo
  alias Medcamp.AuditLog

  require Logger

  @read_timeout 60_000
  @connection_retry_delay 250

  @doc """
  Returns the list of audit_logs with optional filters, supporting simple pagination.

  Supported options:
    * `:filters` - keyword list of filter options (table_name, user_id, action, date_from, date_to, search)
    * `:page` - 1-based page number (default: 1)
    * `:page_size` - number of records per page (default: 50)
  """
  def list_audit_logs(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])
    page = Keyword.get(opts, :page, 1)
    page_size = Keyword.get(opts, :page_size, 50)

    offset = max(page - 1, 0) * page_size

    AuditLog
    |> apply_filters(filters)
    |> order_by([a], desc: a.inserted_at)
    |> offset(^offset)
    |> limit(^page_size)
    |> preload(:user)
    |> repo_all()
  end

  @doc """
  Returns the total count of audit logs for the given filters.
  """
  def count_audit_logs(filters \\ []) do
    AuditLog
    |> apply_filters(filters)
    |> select([a], count(a.id))
    |> repo_one()
  end

  @doc """
  Gets a single audit_log.
  """
  def get_audit_log!(id), do: Repo.get!(AuditLog, id) |> Repo.preload(:user)

  @doc """
  Returns audit logs for a specific record.
  """
  def list_changes_for_record(table_name, record_id) do
    AuditLog
    |> where([a], a.table_name == ^table_name and a.record_id == ^record_id)
    |> order_by([a], desc: a.inserted_at)
    |> preload(:user)
    |> repo_all()
  end

  @doc """
  Returns audit logs by a specific user.
  """
  def list_changes_by_user(user_id, limit \\ 100) do
    AuditLog
    |> where([a], a.user_id == ^user_id)
    |> order_by([a], desc: a.inserted_at)
    |> limit(^limit)
    |> preload(:user)
    |> repo_all()
  end

  @doc """
  Returns audit logs for a specific table.
  """
  def list_changes_by_table(table_name, limit \\ 100) do
    AuditLog
    |> where([a], a.table_name == ^table_name)
    |> order_by([a], desc: a.inserted_at)
    |> limit(^limit)
    |> preload(:user)
    |> repo_all()
  end

  @doc """
  Returns audit logs by action type.
  """
  def list_changes_by_action(action, limit \\ 100) do
    AuditLog
    |> where([a], a.action == ^action)
    |> order_by([a], desc: a.inserted_at)
    |> limit(^limit)
    |> preload(:user)
    |> repo_all()
  end

  @doc """
  Search audit logs by various criteria.
  """
  def search_audit_logs(query, opts \\ []) do
    list_audit_logs(
      filters: [search: query],
      page: Keyword.get(opts, :page, 1),
      page_size: Keyword.get(opts, :page_size, 100)
    )
  end

  @doc """
  Get list of unique tables that have audit logs.
  """
  def list_audited_tables do
    AuditLog
    |> select([a], a.table_name)
    |> distinct(true)
    |> order_by([a], a.table_name)
    |> repo_all()
  end

  @doc """
  Get list of users who have made changes.
  """
  def list_audit_users do
    AuditLog
    |> join(:inner, [a], user in assoc(a, :user))
    |> where([_a, user], user.is_active == true)
    |> select([_a, user], user)
    |> distinct(true)
    |> repo_all()
  end

  @doc """
  Get audit statistics.
  """
  def get_audit_stats do
    by_action =
      AuditLog
      |> group_by([a], a.action)
      |> select([a], {a.action, count(a.id)})
      |> repo_all()
      |> Map.new()

    %{
      total: by_action |> Map.values() |> Enum.sum(),
      by_action: by_action,
      top_tables: []
    }
  end

  # Private helper to apply filters
  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:table_name, table_name}, query when not is_nil(table_name) and table_name != "all" ->
        where(query, [a], a.table_name == ^table_name)

      {:user_id, user_id}, query when not is_nil(user_id) and user_id != "all" ->
        where(query, [a], a.user_id == ^user_id)

      {:action, action}, query when not is_nil(action) and action != "all" ->
        where(query, [a], a.action == ^action)

      {:date_from, date}, query when not is_nil(date) ->
        {:ok, datetime} = NaiveDateTime.new(date, ~T[00:00:00])
        where(query, [a], a.inserted_at >= ^datetime)

      {:date_to, date}, query when not is_nil(date) ->
        {:ok, datetime} = NaiveDateTime.new(date, ~T[23:59:59])
        where(query, [a], a.inserted_at <= ^datetime)

      {:search, search}, query when is_binary(search) and search != "" ->
        search_pattern = "%#{search}%"

        where(
          query,
          [a],
          ilike(a.table_name, ^search_pattern) or
            fragment("CAST(? AS TEXT) ILIKE ?", a.record_id, ^search_pattern)
        )

      _, query ->
        query
    end)
  end

  # Audit pages are read-only, so retrying once is safe when a stale pooled
  # PostgreSQL connection is closed between checkout and the first query.
  defp repo_all(query), do: retry_connection(fn -> Repo.all(query, timeout: @read_timeout) end)
  defp repo_one(query), do: retry_connection(fn -> Repo.one(query, timeout: @read_timeout) end)

  defp retry_connection(operation, retries_left \\ 1)

  defp retry_connection(operation, retries_left) do
    operation.()
  rescue
    error in DBConnection.ConnectionError ->
      if retries_left > 0 do
        Logger.warning("Audit read lost its database connection; retrying once")
        Process.sleep(@connection_retry_delay)
        retry_connection(operation, retries_left - 1)
      else
        reraise error, __STACKTRACE__
      end
  end
end
