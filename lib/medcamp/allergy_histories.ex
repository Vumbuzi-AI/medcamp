defmodule Medcamp.AllergyHistories do
  @moduledoc """
  The AllergyHistories context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.AllergyHistories.AllergyHistory

  @doc """
  Returns the list of allergy histories for a patient, most recently recorded first.
  """
  def list_allergy_histories_for_patient(patient_id) do
    AllergyHistory
    |> where([a], a.patient_id == ^patient_id)
    |> order_by([a], desc: a.inserted_at, desc: a.id)
    |> preload(:recorded_by)
    |> Repo.all()
  end

  def get_allergy_history!(id), do: Repo.get!(AllergyHistory, id)

  def create_allergy_history(attrs \\ %{}) do
    %AllergyHistory{}
    |> AllergyHistory.changeset(attrs)
    |> Repo.audited_insert()
  end

  def update_allergy_history(%AllergyHistory{} = allergy_history, attrs) do
    allergy_history
    |> AllergyHistory.changeset(attrs)
    |> Repo.audited_update()
  end

  def delete_allergy_history(%AllergyHistory{} = allergy_history) do
    Repo.audited_delete(allergy_history)
  end

  def change_allergy_history(%AllergyHistory{} = allergy_history, attrs \\ %{}) do
    AllergyHistory.changeset(allergy_history, attrs)
  end
end
