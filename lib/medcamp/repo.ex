# lib/medcamp/repo.ex
defmodule Medcamp.Repo do
  use Ecto.Repo,
    otp_app: :medcamp,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 10

  require Logger

  import Ecto.Query, only: [where: 3]

  alias Medcamp.Camps.Scope
  alias Medcamp.Tenancy

  @doc """
  Carries the current tenant through every query spawned by a repository call.

  Ecto runs independent association preloads in Task processes. Process
  dictionary values are not inherited by those tasks, but repository default
  options are passed to every preload query, so this is the boundary where the
  tenant must be captured.

  The camp filter rides along for the same reason - a preloaded association on
  a camp-scoped table has to see the same camp as the query that loaded its
  parent.
  """
  @impl true
  def default_options(_operation) do
    []
    |> put_option(:tenant_org_id, Tenancy.current_org_id())
    |> put_option(:camp_filter_id, Scope.camp_filter_id())
  end

  defp put_option(opts, _key, nil), do: opts
  defp put_option(opts, key, value), do: [{key, value} | opts]

  @doc """
  Filters every query against a tenant table by the current organisation.

  Schemas opt in with `use Medcamp.Tenancy.Schema`. For those, this is the
  single place tenant isolation is enforced on the read path - which is why
  the context modules could keep their existing `Repo.all/2` calls unchanged.

  With no organisation set, a tenant query *raises* rather than returning
  every organisation's rows. A missed scope should be a loud crash in
  development, not a silent cross-tenant leak in production.

  The handful of lookups that legitimately run before an organisation is
  known - authenticating by email, resolving a patient from a scanned GSRN,
  the superadmin console - pass `skip_org_id: true`.
  """
  @impl true
  def prepare_query(_operation, query, opts) do
    {scope_organisation(query, opts), opts}
  end

  defp scope_organisation(query, opts) do
    cond do
      opts[:skip_org_id] || opts[:schema_migration] ->
        query

      not tenant_query?(query) ->
        query

      org_id = opts[:tenant_org_id] || Tenancy.current_org_id() ->
        query |> where([t], t.organisation_id == ^org_id) |> scope_camp(opts)

      true ->
        raise """
        Query against a tenant-scoped table with no organisation set.

            #{inspect(query.from.source)}

        Set one with Medcamp.Tenancy.put_org_id/1 (the browser pipeline and the
        LiveView on_mount hook do this from the current user), or pass
        `skip_org_id: true` if this lookup genuinely runs before the
        organisation is known.
        """
    end
  end

  # The camp filter is a view, not a boundary: with none set - the default -
  # a query spans every camp, so nothing that predates camps changes
  # behaviour. Applied only to schemas that `use Medcamp.Camps.Schema`.
  defp scope_camp(query, opts) do
    camp_id =
      if opts[:skip_camp_id], do: nil, else: opts[:camp_filter_id] || Scope.camp_filter_id()

    if camp_id && camp_query?(query) do
      where(query, [t], t.camp_id == ^camp_id)
    else
      query
    end
  end

  defp tenant_query?(%{from: %{source: {_source, schema}}}) when not is_nil(schema) do
    Code.ensure_loaded?(schema) and function_exported?(schema, :__tenant__?, 0)
  end

  defp tenant_query?(_query), do: false

  defp camp_query?(%{from: %{source: {_source, schema}}}) when not is_nil(schema) do
    Code.ensure_loaded?(schema) and function_exported?(schema, :__camp_scoped__?, 0)
  end

  defp camp_query?(_query), do: false

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
    # The task starts with an empty process dictionary, so carry the acting
    # organisation across - `audit_logs` is itself a tenant table.
    org_id = Tenancy.current_org_id()

    # Run in background task to avoid slowing down requests
    Task.start(fn ->
      Tenancy.with_org(org_id, fn ->
        log_change(action, changeset_or_struct, result, user_id)
      end)
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
