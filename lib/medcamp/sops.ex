defmodule Medcamp.SOPs do
  @moduledoc """
  The SOPs context.
  """

  import Ecto.Query, warn: false

  alias Medcamp.Repo
  alias Medcamp.SOPs.SOP

  def list_sops(opts \\ []) do
    SOP
    |> join(:inner, [sop], department in assoc(sop, :department))
    |> join(:inner, [sop, department], added_by in assoc(sop, :added_by))
    |> preload([_sop, department, added_by], department: department, added_by: added_by)
    |> order_by([sop], desc: sop.inserted_at)
    |> apply_filters(opts)
    |> Repo.all()
  end

  def create_sop(attrs \\ %{}, opts \\ []) do
    %SOP{}
    |> SOP.changeset(attrs)
    |> Repo.audited_insert(opts)
  end

  def update_sop(%SOP{} = sop, attrs, opts \\ []) do
    sop
    |> SOP.changeset(attrs)
    |> Repo.audited_update(opts)
  end

  def get_sop!(id) do
    SOP
    |> join(:inner, [sop], department in assoc(sop, :department))
    |> join(:inner, [sop, department], added_by in assoc(sop, :added_by))
    |> preload([_sop, department, added_by], department: department, added_by: added_by)
    |> Repo.get!(id)
  end

  def change_sop(%SOP{} = sop, attrs \\ %{}) do
    SOP.changeset(sop, attrs)
  end

  defp apply_filters(query, []), do: query

  defp apply_filters(query, [{:search, term} | rest]) when is_binary(term) do
    trimmed = String.trim(term)

    if trimmed == "" do
      apply_filters(query, rest)
    else
      pattern = "%#{trimmed}%"

      query
      |> where(
        [sop, department, added_by],
        ilike(sop.name, ^pattern) or
          ilike(sop.description, ^pattern) or
          ilike(department.name, ^pattern) or
          ilike(added_by.name, ^pattern) or
          ilike(sop.original_filename, ^pattern)
      )
      |> apply_filters(rest)
    end
  end

  defp apply_filters(query, [{:department_id, department_id} | rest])
       when department_id in [nil, ""] do
    apply_filters(query, rest)
  end

  defp apply_filters(query, [{:department_id, department_id} | rest])
       when is_integer(department_id) do
    query
    |> where([sop], sop.department_id == ^department_id)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:department_id, department_id} | rest])
       when is_binary(department_id) do
    case Integer.parse(department_id) do
      {id, _} ->
        query
        |> where([sop], sop.department_id == ^id)
        |> apply_filters(rest)

      :error ->
        apply_filters(query, rest)
    end
  end

  defp apply_filters(query, [_ | rest]), do: apply_filters(query, rest)
end
