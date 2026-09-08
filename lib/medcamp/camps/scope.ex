defmodule Medcamp.Camps.Scope do
  @moduledoc """
  Holds two separate camp values for the current process.

  **The active camp** is the organisation's own state, read from the database:
  the camp new records are stamped with. There is one of it, everyone in the
  organisation writes into it, and a user cannot choose it.

  **The camp filter** is one viewer's temporary lens: when set, camp-scoped
  reads return only that camp's rows. `nil` means "all camps" and is the
  default, which is why every existing query keeps working unchanged.

  Both live in the process dictionary alongside `Medcamp.Tenancy`'s
  organisation, and carry the same caveat: a process you spawn starts without
  them. Use `with_camp_filter/2` inside a `Task`.
  """

  @filter_key :current_camp_filter_id
  @active_key :active_camp_id

  @doc "Sets the camp new records will be stamped with."
  def put_active_camp_id(nil), do: Process.delete(@active_key)
  def put_active_camp_id(camp_id) when is_integer(camp_id), do: Process.put(@active_key, camp_id)

  @doc "The camp new records are stamped with, or `nil` if none is active."
  def active_camp_id, do: Process.get(@active_key)

  @doc """
  Restricts camp-scoped reads to one camp. `nil` clears the filter, showing
  every camp's rows.
  """
  def put_camp_filter(nil), do: Process.delete(@filter_key)
  def put_camp_filter(camp_id) when is_integer(camp_id), do: Process.put(@filter_key, camp_id)

  def put_camp_filter(camp_id) when is_binary(camp_id) do
    case Integer.parse(camp_id) do
      {id, ""} -> put_camp_filter(id)
      _ -> put_camp_filter(nil)
    end
  end

  @doc "The camp reads are currently restricted to, or `nil` for all camps."
  def camp_filter_id, do: Process.get(@filter_key)

  @doc "Clears both values. Mainly useful in tests."
  def clear do
    Process.delete(@filter_key)
    Process.delete(@active_key)
  end

  @doc """
  Runs `fun` with reads restricted to `camp_id`, restoring the previous
  filter afterwards.
  """
  def with_camp_filter(camp_id, fun) when is_function(fun, 0) do
    previous = camp_filter_id()
    put_camp_filter(camp_id)

    try do
      fun.()
    after
      put_camp_filter(previous)
    end
  end

  @doc """
  Runs `fun` with reads spanning every camp, whatever filter is in effect.

  Used by the write path and by lookups that must not miss a record because
  the viewer happens to be looking at one camp - resolving the batch a
  scanned drug came from, say, when that batch was received at a previous
  camp.
  """
  def across_camps(fun) when is_function(fun, 0), do: with_camp_filter(nil, fun)
end
