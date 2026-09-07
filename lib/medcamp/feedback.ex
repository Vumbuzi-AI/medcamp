defmodule Medcamp.Feedback do
  @moduledoc """
  The Feedback context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.Feedback.PatientFeedback

  @doc """
  Returns the list of patient_feedbacks, optionally filtered.

  ## Options

    * `:date_from` - filter feedbacks with `inserted_at >=` this date (Date or "YYYY-MM-DD")
    * `:date_to` - filter feedbacks with `inserted_at <=` this date (Date or "YYYY-MM-DD")
    * `:satisfaction_level` - exact match (e.g. "very_satisfied", "satisfied")
    * `:staff_helpful` - exact match ("yes", "no", "other")
    * `:search` - search in name and suggestions (case-insensitive)

  ## Examples

      iex> list_patient_feedbacks()
      [%PatientFeedback{}, ...]

      iex> list_patient_feedbacks(date_from: ~D[2026-01-01], satisfaction_level: "satisfied")
      [%PatientFeedback{}, ...]

  """
  def list_patient_feedbacks(opts \\ []) do
    from(f in PatientFeedback, order_by: [desc: f.inserted_at])
    |> apply_feedback_filters(opts)
    |> Repo.all()
  end

  defp apply_feedback_filters(query, []), do: query

  defp apply_feedback_filters(query, [{:date_from, nil} | rest]),
    do: apply_feedback_filters(query, rest)

  defp apply_feedback_filters(query, [{:date_from, ""} | rest]),
    do: apply_feedback_filters(query, rest)

  defp apply_feedback_filters(query, [{:date_from, date} | rest]) do
    date = parse_date!(date)

    query
    |> where([f], f.inserted_at >= ^DateTime.new!(date, ~T[00:00:00], "Etc/UTC"))
    |> apply_feedback_filters(rest)
  end

  defp apply_feedback_filters(query, [{:date_to, nil} | rest]),
    do: apply_feedback_filters(query, rest)

  defp apply_feedback_filters(query, [{:date_to, ""} | rest]),
    do: apply_feedback_filters(query, rest)

  defp apply_feedback_filters(query, [{:date_to, date} | rest]) do
    date = parse_date!(date)

    query
    |> where([f], f.inserted_at <= ^DateTime.new!(date, ~T[23:59:59], "Etc/UTC"))
    |> apply_feedback_filters(rest)
  end

  defp apply_feedback_filters(query, [{:satisfaction_level, ""} | rest]),
    do: apply_feedback_filters(query, rest)

  defp apply_feedback_filters(query, [{:satisfaction_level, "all"} | rest]),
    do: apply_feedback_filters(query, rest)

  defp apply_feedback_filters(query, [{:satisfaction_level, level} | rest])
       when is_binary(level) and level != "" and level != "all" do
    query
    |> where([f], f.satisfaction_level == ^level)
    |> apply_feedback_filters(rest)
  end

  defp apply_feedback_filters(query, [{:satisfaction_level, _} | rest]),
    do: apply_feedback_filters(query, rest)

  defp apply_feedback_filters(query, [{:staff_helpful, ""} | rest]),
    do: apply_feedback_filters(query, rest)

  defp apply_feedback_filters(query, [{:staff_helpful, "all"} | rest]),
    do: apply_feedback_filters(query, rest)

  defp apply_feedback_filters(query, [{:staff_helpful, val} | rest])
       when is_binary(val) and val != "" and val != "all" do
    query
    |> where([f], f.staff_helpful == ^val)
    |> apply_feedback_filters(rest)
  end

  defp apply_feedback_filters(query, [{:staff_helpful, _} | rest]),
    do: apply_feedback_filters(query, rest)

  defp apply_feedback_filters(query, [{:search, ""} | rest]),
    do: apply_feedback_filters(query, rest)

  defp apply_feedback_filters(query, [{:search, term} | rest])
       when is_binary(term) and byte_size(term) > 0 do
    term =
      term
      |> String.replace("%", "\\%")
      |> String.replace("_", "\\_")
      |> then(&"%#{&1}%")

    query
    |> where(
      [f],
      ilike(f.name, ^term) or ilike(f.suggestions, ^term) or
        ilike(f.how_did_you_know, ^term)
    )
    |> apply_feedback_filters(rest)
  end

  defp apply_feedback_filters(query, [{:search, _} | rest]),
    do: apply_feedback_filters(query, rest)

  defp apply_feedback_filters(query, [_ | rest]), do: apply_feedback_filters(query, rest)

  defp parse_date!(%Date{} = d), do: d

  defp parse_date!(bin) when is_binary(bin) do
    case Date.from_iso8601(bin) do
      {:ok, d} -> d
      {:error, _} -> raise ArgumentError, "invalid date: #{inspect(bin)}"
    end
  end

  def get_feedback_stats do
    from(f in PatientFeedback,
      select: %{
        total_responses: count(f.id),
        avg_overall_satisfaction: avg(f.overall_satisfaction_rating),
        recommendation_breakdown: fragment("
        JSON_OBJECT(
          'yes', SUM(CASE WHEN would_recommend = 'yes' THEN 1 ELSE 0 END),
          'no', SUM(CASE WHEN would_recommend = 'no' THEN 1 ELSE 0 END),
          'maybe', SUM(CASE WHEN would_recommend = 'maybe' THEN 1 ELSE 0 END)
        )
      ")
      }
    )
    |> Repo.one()
  end

  def get_department_ratings do
    from(f in PatientFeedback,
      where: not is_nil(f.department),
      group_by: f.department,
      select: %{
        department: f.department,
        count: count(f.id),
        avg_rating: avg(f.overall_satisfaction_rating)
      }
    )
    |> Repo.all()
  end

  @doc """
  Gets a single patient_feedback.

  Raises `Ecto.NoResultsError` if the Patient feedback does not exist.

  ## Examples

      iex> get_patient_feedback!(123)
      %PatientFeedback{}

      iex> get_patient_feedback!(456)
      ** (Ecto.NoResultsError)

  """
  def get_patient_feedback!(id), do: Repo.get!(PatientFeedback, id)

  @doc """
  Creates a patient_feedback.

  ## Examples

      iex> create_patient_feedback(%{field: value})
      {:ok, %PatientFeedback{}}

      iex> create_patient_feedback(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_patient_feedback(attrs \\ %{}) do
    %PatientFeedback{}
    |> PatientFeedback.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a patient_feedback.

  ## Examples

      iex> update_patient_feedback(patient_feedback, %{field: new_value})
      {:ok, %PatientFeedback{}}

      iex> update_patient_feedback(patient_feedback, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_patient_feedback(%PatientFeedback{} = patient_feedback, attrs) do
    patient_feedback
    |> PatientFeedback.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a patient_feedback.

  ## Examples

      iex> delete_patient_feedback(patient_feedback)
      {:ok, %PatientFeedback{}}

      iex> delete_patient_feedback(patient_feedback)
      {:error, %Ecto.Changeset{}}

  """
  def delete_patient_feedback(%PatientFeedback{} = patient_feedback) do
    Repo.delete(patient_feedback)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking patient_feedback changes.

  ## Examples

      iex> change_patient_feedback(patient_feedback)
      %Ecto.Changeset{data: %PatientFeedback{}}

  """
  def change_patient_feedback(%PatientFeedback{} = patient_feedback, attrs \\ %{}) do
    PatientFeedback.changeset(patient_feedback, attrs)
  end
end
