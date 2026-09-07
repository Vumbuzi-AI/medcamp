defmodule Medcamp.DailyActivities do
  @moduledoc """
  The DailyActivities context for managing housekeeping checklist items.
  Each activity is done ONCE per day - records WHO did it.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo
  alias Medcamp.DailyActivities.DailyActivity

  # Add this function to your existing Medcamp.DailyActivities module

  @doc """
  Gets a summary of activities completed by each staff member in a date range.
  Returns a map of user_name => count.
  """
  def get_staff_summary(start_date, end_date) do
    DailyActivity
    |> where([a], a.date >= ^start_date and a.date <= ^end_date)
    |> join(:left, [a], u in Medcamp.Accounts.User, on: a.user_id == u.id)
    |> group_by([a, u], u.name)
    |> select([a, u], {u.name, count(a.id)})
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  Returns all activities within a date range as a map.
  Map key: {date_iso, activity_name}
  Map value: %{user_id: id, user_name: name, completed_at: datetime, id: record_id}
  """
  def list_all_activities(start_date, end_date) do
    DailyActivity
    |> where([a], a.date >= ^start_date and a.date <= ^end_date)
    |> join(:left, [a], u in Medcamp.Accounts.User, on: a.user_id == u.id)
    |> select([a, u], %{
      id: a.id,
      date: a.date,
      activity_name: a.activity_name,
      user_id: a.user_id,
      user_name: u.name,
      completed_at: a.completed_at
    })
    |> Repo.all()
    |> activities_to_map()
  end

  @doc """
  Marks an activity as done by a user.
  Returns {:ok, activity} or {:error, changeset}
  """
  def mark_activity_done(user_id, date, activity_name) do
    %DailyActivity{}
    |> DailyActivity.changeset(%{
      user_id: user_id,
      date: date,
      activity_name: activity_name,
      completed: true,
      completed_at: DateTime.utc_now()
    })
    |> Repo.insert()
  end

  @doc """
  Undoes/deletes an activity record by ID.
  """
  def undo_activity(activity_id) do
    case Repo.get(DailyActivity, activity_id) do
      nil -> {:error, :not_found}
      activity -> Repo.delete(activity)
    end
  end

  @doc """
  Gets a single activity by date and activity name (since each activity is done once per day).
  """
  def get_activity(date, activity_name) do
    DailyActivity
    |> where([a], a.date == ^date)
    |> where([a], a.activity_name == ^activity_name)
    |> Repo.one()
  end

  @doc """
  Gets completion statistics for a specific date.
  """
  def get_daily_stats(date) do
    DailyActivity
    |> where([a], a.date == ^date)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets completion statistics over a date range grouped by date.
  Returns a map of date => count.
  """
  def get_stats_for_range(start_date, end_date) do
    DailyActivity
    |> where([a], a.date >= ^start_date and a.date <= ^end_date)
    |> group_by([a], a.date)
    |> select([a], {a.date, count(a.id)})
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  Gets activities completed by a specific user in a date range.
  """
  def get_user_activities(user_id, start_date, end_date) do
    DailyActivity
    |> where([a], a.user_id == ^user_id)
    |> where([a], a.date >= ^start_date and a.date <= ^end_date)
    |> Repo.all()
  end

  @doc """
  Gets a summary of who did what activities today.
  """
  def get_today_summary(date \\ Date.utc_today()) do
    DailyActivity
    |> where([a], a.date == ^date)
    |> join(:left, [a], u in Medcamp.Accounts.User, on: a.user_id == u.id)
    |> select([a, u], %{
      activity_name: a.activity_name,
      user_name: u.name,
      completed_at: a.completed_at
    })
    |> order_by([a], asc: a.activity_name)
    |> Repo.all()
  end

  # Private helpers

  defp activities_to_map(activities) do
    activities
    |> Enum.reduce(%{}, fn activity, acc ->
      key = {Date.to_iso8601(activity.date), activity.activity_name}

      Map.put(acc, key, %{
        id: activity.id,
        user_id: activity.user_id,
        user_name: activity.user_name,
        completed_at: activity.completed_at
      })
    end)
  end

  def delete_all_activities do
    Repo.delete_all(DailyActivity)
  end
end
