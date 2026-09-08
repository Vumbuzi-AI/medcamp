defmodule Medcamp.Tenancy do
  @moduledoc """
  Holds the organisation the current process is acting for.

  Every tenant-scoped query is filtered by this value automatically, in
  `Medcamp.Repo.prepare_query/3` - which is why the ~200 existing context
  functions did not each have to grow an `organisation_id` argument.

  The value lives in the process dictionary, the same way `Repo.put_audit_user/1`
  carries the acting user. That works because a web request and a LiveView each
  own a process for their whole lifetime. It does *not* cross into a process you
  spawn: anything running in a `Task` or under the scheduler must re-establish
  the organisation with `with_org/2`.
  """

  @key :current_organisation_id

  @doc "Sets the organisation for the current process."
  def put_org_id(nil), do: nil
  def put_org_id(org_id) when is_integer(org_id), do: Process.put(@key, org_id)

  @doc "The current process's organisation id, or `nil` if none is set."
  def current_org_id, do: Process.get(@key)

  @doc "Clears the organisation. Mainly useful in tests."
  def clear_org_id, do: Process.delete(@key)

  @doc """
  The current organisation id, raising when there isn't one.

  Used on the write path: inserting a tenant row without an organisation is
  never something we want to let through quietly.
  """
  def require_org_id! do
    current_org_id() ||
      raise """
      No organisation is set for this process.

      A tenant-scoped record cannot be written without one. If this is running
      in a spawned task or a scheduled job, wrap it in Medcamp.Tenancy.with_org/2.
      """
  end

  @doc """
  Runs `fun` with `org_id` as the current organisation, restoring whatever was
  set before. Use this in tasks and scheduled jobs, which start with an empty
  process dictionary.
  """
  def with_org(org_id, fun) when is_function(fun, 0) do
    previous = current_org_id()
    put_org_id(org_id)

    try do
      fun.()
    after
      if previous, do: put_org_id(previous), else: clear_org_id()
    end
  end
end
