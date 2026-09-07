defmodule Medcamp.PharmacyLogs do
  @moduledoc """
  Context for pharmacy temperature and humidity logs.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo
  alias Medcamp.PharmacyLogs.PharmacyLog

  def list_logs do
    PharmacyLog
    |> order_by([l], desc: l.year, desc: l.month)
    |> preload(:created_by)
    |> Repo.all()
  end

  def get_log!(id) do
    log =
      Repo.get!(PharmacyLog, id)
      |> Repo.preload(:created_by)

    %{log | daily_entries: log.daily_entries || %{}}
  end

  def get_log_by_month_year(log_type, month, year) do
    case Repo.get_by(PharmacyLog, log_type: log_type, month: month, year: year) do
      nil ->
        nil

      log ->
        log = Repo.preload(log, :created_by)
        %{log | daily_entries: log.daily_entries || %{}}
    end
  end

  def create_log(attrs \\ %{}) do
    %PharmacyLog{}
    |> PharmacyLog.changeset(attrs)
    |> Repo.insert()
  end

  def update_log(%PharmacyLog{} = log, attrs) do
    log
    |> PharmacyLog.changeset(attrs)
    |> Repo.update()
  end

  def get_day_entry(log, day) when is_integer(day) do
    daily_entries = log.daily_entries || %{}
    Map.get(daily_entries, Integer.to_string(day), %{})
  end

  def get_day_entry(log, day) when is_binary(day) do
    daily_entries = log.daily_entries || %{}
    Map.get(daily_entries, day, %{})
  end
end
