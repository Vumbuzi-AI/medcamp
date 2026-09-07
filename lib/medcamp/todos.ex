defmodule Medcamp.Todos do
  @moduledoc """
  Context for todos.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo
  alias Medcamp.Todos.Todo

  @doc """
  Lists todos created by the given user, optionally filtered by status.
  """
  def list_todos_for_user(user, filter \\ "all", search \\ "") do
    base =
      from t in Todo,
        where: t.created_by_id == ^user.id,
        order_by: [asc: t.due_date, desc: t.inserted_at],
        preload: [:created_by]

    base =
      case filter do
        "all" -> base
        status -> from(t in base, where: t.status == ^status)
      end

    base
    |> apply_todo_search(search)
    |> Repo.all()
  end

  defp apply_todo_search(query, nil), do: query
  defp apply_todo_search(query, ""), do: query

  defp apply_todo_search(query, term) do
    term = String.trim(term)

    if term == "" do
      query
    else
      pattern = "%#{term}%"
      from(t in query, where: ilike(t.title, ^pattern) or ilike(t.description, ^pattern))
    end
  end

  def get_todo!(id) do
    Todo
    |> Repo.get!(id)
    |> Repo.preload([:created_by])
  end

  def create_todo(attrs \\ %{}) do
    %Todo{}
    |> Todo.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, todo} -> {:ok, Repo.preload(todo, [:created_by])}
      error -> error
    end
  end

  def update_todo(%Todo{} = todo, attrs) do
    todo
    |> Todo.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated} -> {:ok, Repo.preload(updated, [:created_by], force: true)}
      error -> error
    end
  end

  def delete_todo(%Todo{} = todo), do: Repo.delete(todo)

  def change_todo(%Todo{} = todo, attrs \\ %{}) do
    Todo.changeset(todo, attrs)
  end
end
