defmodule Medcamp.Requisitions do
  @moduledoc """
  The Requisitions context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.Requisitions.Requisition

  alias Medcamp.Accounts

  @doc """
  Returns the list of requisitions.
  """
  def list_requisitions do
    Requisition
    |> order_by([r], desc: r.inserted_at)
    |> preload([
      :requested_by,
      :requested_from,
      :to_department,
      :inventory_received,
      :general_inventory_item
    ])
    |> Repo.all()
  end

  @doc """
  Returns requisitions visible to the given user.
  - Admins see all requisitions.
  - Procurement officers see all requisitions.
  - Others see requisitions sent TO their department or sent BY their department.
  - If user has no department_id, falls back to requested_by or requested_from (legacy).
  """
  def list_requisitions_for_user(%{role: "admin"}), do: list_requisitions()
  def list_requisitions_for_user(%{role: "procurement_officer"}), do: list_requisitions()

  def list_requisitions_for_user(%{department_id: nil} = user) do
    user_id = user.id

    Requisition
    |> where([r], r.requested_by_id == ^user_id or r.requested_from_id == ^user_id)
    |> order_by([r], desc: r.inserted_at)
    |> preload([
      :requested_by,
      :requested_from,
      :to_department,
      :inventory_received,
      :general_inventory_item
    ])
    |> Repo.all()
  end

  def list_requisitions_for_user(%{department_id: dept_id} = _user) when not is_nil(dept_id) do
    Requisition
    |> join(:left, [r], rb in assoc(r, :requested_by))
    |> where(
      [r, rb],
      r.to_department_id == ^dept_id or rb.department_id == ^dept_id
    )
    |> order_by([r], desc: r.inserted_at)
    |> preload([
      :requested_by,
      :requested_from,
      :to_department,
      :inventory_received,
      :general_inventory_item
    ])
    |> Repo.all()
  end

  def paginate_requisitions_for_user(
        user,
        status \\ "all",
        search_term \\ "",
        department_id \\ "",
        date_from \\ "",
        date_to \\ "",
        page \\ 1,
        per_page \\ 20
      ) do
    user
    |> requisitions_query(status, search_term, department_id, date_from, date_to)
    |> Repo.paginate(page: page, page_size: per_page)
    |> preload_requisition_page()
  end

  @doc """
  Returns requisitions for a user, optionally filtered by status.
  """
  def list_requisitions_for_user(user, status)
      when status in ["pending", "approved", "rejected"] do
    user
    |> list_requisitions_for_user()
    |> Enum.filter(&(&1.status == status))
  end

  def list_requisitions_for_user(user, _status), do: list_requisitions_for_user(user)

  @doc """
  Returns requisitions requested by a specific user.
  """
  def list_requisitions_by_user(user_id) do
    Requisition
    |> where([r], r.requested_by_id == ^user_id)
    |> order_by([r], desc: r.inserted_at)
    |> preload([
      :requested_by,
      :requested_from,
      :to_department,
      :inventory_received,
      :general_inventory_item
    ])
    |> Repo.all()
  end

  @doc """
  Returns requisitions pending for a user's department (sent to their department).
  """
  def list_pending_requisitions_for_user(user_id) do
    user = Accounts.get_user!(user_id)

    if user.department_id do
      Requisition
      |> where([r], r.to_department_id == ^user.department_id and r.status == "pending")
      |> order_by([r], desc: r.inserted_at)
      |> preload([
        :requested_by,
        :requested_from,
        :to_department,
        :inventory_received,
        :general_inventory_item
      ])
      |> Repo.all()
    else
      Requisition
      |> where([r], r.requested_from_id == ^user_id and r.status == "pending")
      |> order_by([r], desc: r.inserted_at)
      |> preload([
        :requested_by,
        :requested_from,
        :to_department,
        :inventory_received,
        :general_inventory_item
      ])
      |> Repo.all()
    end
  end

  @doc """
  Returns requisitions by status.
  """
  def list_requisitions_by_status(status) do
    Requisition
    |> where([r], r.status == ^status)
    |> order_by([r], desc: r.inserted_at)
    |> preload([
      :requested_by,
      :requested_from,
      :to_department,
      :inventory_received,
      :general_inventory_item
    ])
    |> Repo.all()
  end

  @doc """
  Returns requisitions by ids, preloaded for procurement and UI workflows.
  """
  def list_requisitions_by_ids(ids) when is_list(ids) do
    ids = Enum.map(ids, &normalize_id/1) |> Enum.reject(&is_nil/1)

    if ids == [] do
      []
    else
      Requisition
      |> where([r], r.id in ^ids)
      |> order_by([r], desc: r.inserted_at)
      |> preload([
        :requested_by,
        :requested_from,
        :to_department,
        :inventory_received,
        :general_inventory_item
      ])
      |> Repo.all()
    end
  end

  @doc """
  Gets a single requisition.
  """
  def get_requisition!(id) do
    Requisition
    |> Repo.get!(id)
    |> Repo.preload([
      :requested_by,
      :requested_from,
      :to_department,
      :inventory_received,
      :general_inventory_item,
      requested_by: :department
    ])
  end

  @doc """
  Creates a requisition.
  """
  def create_requisition(attrs \\ %{}) do
    %Requisition{}
    |> Requisition.changeset(ensure_requested_at(attrs))
    |> Repo.insert()
  end

  @doc """
  Updates a requisition.
  """
  def update_requisition(%Requisition{} = requisition, attrs) do
    attrs =
      if attrs["status"] && attrs["status"] != "pending" && is_nil(requisition.responded_at) do
        Map.put(attrs, "responded_at", DateTime.utc_now())
      else
        attrs
      end

    requisition
    |> Requisition.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a requisition.
  """
  def delete_requisition(%Requisition{} = requisition) do
    Repo.delete(requisition)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking requisition changes.
  """
  def change_requisition(%Requisition{} = requisition, attrs \\ %{}) do
    Requisition.changeset(requisition, attrs)
  end

  @doc """
  Searches requisitions for a user by title, description, requester name, or department name.
  """
  def search_requisitions_for_user(user, search_term) when is_binary(search_term) do
    term = String.downcase(String.trim(search_term))

    user
    |> list_requisitions_for_user()
    |> Enum.filter(fn r ->
      String.contains?(String.downcase(r.title || ""), term) ||
        String.contains?(String.downcase(r.description || ""), term) ||
        String.contains?(
          String.downcase(get_in(r, [Access.key(:requested_by), Access.key(:name)]) || ""),
          term
        ) ||
        String.contains?(
          String.downcase(get_in(r, [Access.key(:to_department), Access.key(:name)]) || ""),
          term
        )
    end)
  end

  defp requisitions_query(
         %{role: "admin"},
         status,
         search_term,
         department_id,
         date_from,
         date_to
       ) do
    requisitions_base_query()
    |> maybe_filter_status(status)
    |> maybe_filter_search(search_term)
    |> maybe_filter_department(department_id)
    |> maybe_filter_requested_date(date_from, date_to)
  end

  defp requisitions_query(
         %{role: "procurement_officer"},
         status,
         search_term,
         department_id,
         date_from,
         date_to
       ) do
    requisitions_base_query()
    |> maybe_filter_status(status)
    |> maybe_filter_search(search_term)
    |> maybe_filter_department(department_id)
    |> maybe_filter_requested_date(date_from, date_to)
  end

  defp requisitions_query(
         %{department_id: nil} = user,
         status,
         search_term,
         department_id,
         date_from,
         date_to
       ) do
    user_id = user.id

    requisitions_base_query()
    |> where([r, rb, _td], r.requested_by_id == ^user_id or r.requested_from_id == ^user_id)
    |> maybe_filter_status(status)
    |> maybe_filter_search(search_term)
    |> maybe_filter_department(department_id)
    |> maybe_filter_requested_date(date_from, date_to)
  end

  defp requisitions_query(
         %{department_id: dept_id},
         status,
         search_term,
         department_id,
         date_from,
         date_to
       ) do
    requisitions_base_query()
    |> where([r, rb, _td], r.to_department_id == ^dept_id or rb.department_id == ^dept_id)
    |> maybe_filter_status(status)
    |> maybe_filter_search(search_term)
    |> maybe_filter_department(department_id)
    |> maybe_filter_requested_date(date_from, date_to)
  end

  defp requisitions_base_query do
    Requisition
    |> join(:left, [r], rb in assoc(r, :requested_by))
    |> join(:left, [r, _rb], td in assoc(r, :to_department))
    |> order_by([r, _rb, _td], desc: r.inserted_at)
  end

  defp maybe_filter_status(query, "all"), do: query
  defp maybe_filter_status(query, ""), do: query
  defp maybe_filter_status(query, nil), do: query
  defp maybe_filter_status(query, status), do: where(query, [r, _rb, _td], r.status == ^status)

  defp maybe_filter_search(query, nil), do: query
  defp maybe_filter_search(query, ""), do: query

  defp maybe_filter_search(query, term) when is_binary(term) do
    term = String.trim(term)

    if term == "" do
      query
    else
      pattern = "%#{term}%"

      where(
        query,
        [r, rb, td],
        ilike(r.title, ^pattern) or
          ilike(r.description, ^pattern) or
          ilike(rb.name, ^pattern) or
          ilike(td.name, ^pattern)
      )
    end
  end

  defp maybe_filter_search(query, _), do: query

  defp maybe_filter_department(query, nil), do: query
  defp maybe_filter_department(query, ""), do: query

  defp maybe_filter_department(query, department_id) do
    case Integer.parse(to_string(department_id)) do
      {id, ""} -> where(query, [r, _rb, _td], r.to_department_id == ^id)
      _ -> query
    end
  end

  defp maybe_filter_requested_date(query, nil, nil), do: query

  defp maybe_filter_requested_date(query, date_from, date_to) do
    from_date = parse_filter_date(date_from)
    to_date = parse_filter_date(date_to)

    query =
      if from_date do
        where(
          query,
          [r, _rb, _td],
          fragment("DATE(COALESCE(?, ?))", r.requested_at, r.inserted_at) >= ^from_date
        )
      else
        query
      end

    if to_date do
      where(
        query,
        [r, _rb, _td],
        fragment("DATE(COALESCE(?, ?))", r.requested_at, r.inserted_at) <= ^to_date
      )
    else
      query
    end
  end

  defp parse_filter_date(nil), do: nil
  defp parse_filter_date(""), do: nil

  defp parse_filter_date(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp parse_filter_date(_value), do: nil

  defp preload_requisition_page(%Scrivener.Page{} = page) do
    %{
      page
      | entries:
          Repo.preload(page.entries, [
            :requested_by,
            :requested_from,
            :to_department,
            :inventory_received,
            :general_inventory_item
          ])
    }
  end

  defp normalize_id(id) when is_integer(id), do: id

  defp normalize_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {int, ""} -> int
      _ -> nil
    end
  end

  defp normalize_id(_), do: nil

  defp ensure_requested_at(attrs) when is_map(attrs) do
    cond do
      Map.has_key?(attrs, "requested_at") ->
        attrs

      Map.has_key?(attrs, :requested_at) ->
        attrs

      true ->
        Map.put(attrs, "requested_at", DateTime.utc_now())
    end
  end
end
