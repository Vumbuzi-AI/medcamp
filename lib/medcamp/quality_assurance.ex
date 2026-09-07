defmodule Medcamp.QualityAssurance do
  @moduledoc """
  The QualityAssurance context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.QualityAssurance.Chart

  @doc """
  Returns the list of charts.
  """
  def list_charts do
    Chart
    |> order_by([c], desc: c.year, desc: c.month)
    |> preload(:created_by)
    |> Repo.all()
  end

  def list_charts_by_type(chart_type) do
    Chart
    |> where([c], c.chart_type == ^chart_type)
    |> order_by([c], desc: c.year, desc: c.month)
    |> preload(:created_by)
    |> Repo.all()
  end

  def count_charts do
    Repo.aggregate(Chart, :count, :id)
  end

  @doc """
  Gets a single chart.

  Raises `Ecto.NoResultsError` if the Chart does not exist.
  """
  def get_chart!(id) do
    chart =
      Repo.get!(Chart, id)
      |> Repo.preload(:created_by)

    # Ensure daily_entries is always a map, not nil
    %{chart | daily_entries: chart.daily_entries || %{}}
  end

  def get_chart_by_month_year(chart_type, month, year) do
    case Repo.get_by(Chart, chart_type: chart_type, month: month, year: year) do
      nil ->
        nil

      chart ->
        chart = Repo.preload(chart, :created_by)
        # Ensure daily_entries is always a map, not nil
        %{chart | daily_entries: chart.daily_entries || %{}}
    end
  end

  @doc """
  Creates a chart.
  """
  def create_chart(attrs \\ %{}) do
    %Chart{}
    |> Chart.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a chart.
  """
  def update_chart(%Chart{} = chart, attrs) do
    chart
    |> Chart.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a chart.
  """
  def delete_chart(%Chart{} = chart) do
    Repo.delete(chart)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking chart changes.
  """
  def change_chart(%Chart{} = chart, attrs \\ %{}) do
    Chart.changeset(chart, attrs)
  end

  @doc """
  Updates a daily entry for a chart.
  """
  def update_daily_entry(chart, day, entry_data) when is_integer(day) and day in 1..31 do
    current_entries = chart.daily_entries || %{}
    updated_entries = Map.put(current_entries, Integer.to_string(day), entry_data)

    update_chart(chart, %{daily_entries: updated_entries})
  end

  @doc """
  Gets the entry for a specific day.
  """
  def get_day_entry(chart, day) when is_integer(day) do
    daily_entries = chart.daily_entries || %{}
    Map.get(daily_entries, Integer.to_string(day), %{})
  end

  def get_day_entry(chart, day) when is_binary(day) do
    daily_entries = chart.daily_entries || %{}
    Map.get(daily_entries, day, %{})
  end
end
