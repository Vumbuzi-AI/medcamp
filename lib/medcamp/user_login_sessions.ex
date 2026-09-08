defmodule Medcamp.UserLoginSessions do
  import Ecto.Query, warn: false

  alias Medcamp.Repo
  alias Medcamp.UserLoginSessions.UserLoginSession

  @doc "Creates a login record for a user."
  def create_login(user_id) do
    %UserLoginSession{}
    |> UserLoginSession.changeset(%{
      user_id: user_id,
      logged_in_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.insert()
  end

  @doc "Records logout on the most recent open session for a user."
  def record_logout(user_id) do
    session =
      UserLoginSession
      |> where([s], s.user_id == ^user_id and is_nil(s.logged_out_at))
      |> order_by([s], desc: s.logged_in_at)
      |> limit(1)
      |> Repo.one()

    if session do
      session
      |> UserLoginSession.changeset(%{
        logged_out_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      |> Repo.update()
    end
  end

  @doc "Lists all login sessions with user preloaded, newest first."
  def list_sessions do
    sessions_query(%{})
    |> Repo.all()
  end

  def list_sessions_paginated(filters \\ %{}, page \\ 1, per_page \\ 20) do
    sessions_query(filters)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
  end

  def count_sessions(filters \\ %{}) do
    sessions_base_query(filters)
    |> exclude(:order_by)
    |> select([s, _u], count(s.id))
    |> Repo.one()
  end

  @doc "Filters sessions by name, email, or active status."
  def list_sessions(filters) when is_map(filters) do
    sessions_query(filters)
    |> Repo.all()
  end

  defp sessions_query(filters) do
    sessions_base_query(filters)
    |> preload([_s, u], user: u)
  end

  defp sessions_base_query(filters) do
    query =
      UserLoginSession
      |> join(:inner, [s], u in assoc(s, :user))
      |> order_by([s], desc: s.logged_in_at)

    query =
      case filters[:search] do
        term when is_binary(term) and term != "" ->
          like = "%#{term}%"
          where(query, [_s, u], ilike(u.name, ^like) or ilike(u.email, ^like))

        _ ->
          query
      end

    case filters[:active] do
      "active" -> where(query, [s], is_nil(s.logged_out_at))
      "inactive" -> where(query, [s], not is_nil(s.logged_out_at))
      _ -> query
    end
  end
end
