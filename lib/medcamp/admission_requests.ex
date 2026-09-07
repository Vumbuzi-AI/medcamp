defmodule Medcamp.AdmissionRequests do
  @moduledoc """
  The AdmissionRequests context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.AdmissionRequests.AdmissionRequest
  alias Medcamp.AdmissionRequests.LineItem

  @doc """
  Returns the list of admission_requests.

  ## Examples

      iex> list_admission_requests()
      [%AdmissionRequest{}, ...]

  """
  def list_admission_requests do
    Repo.all(AdmissionRequest)
  end

  def list_admission_requests_by_patient_id(patient_id) do
    AdmissionRequest
    |> where([a], a.patient_id == ^patient_id)
    |> order_by([a], desc: a.date, desc: a.inserted_at)
    |> Repo.all()
    |> Repo.preload([:doctor_note, :patient, :doctor, :nurse, :line_items])
  end

  def list_admission_requests_by_patient_id_paginated(patient_id, page \\ 1, per_page \\ 10) do
    AdmissionRequest
    |> where([a], a.patient_id == ^patient_id)
    |> order_by([a], desc: a.date, desc: a.inserted_at)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([:doctor_note, :patient, :doctor, :nurse, :line_items])
  end

  def count_admission_requests_by_patient_id(patient_id) do
    AdmissionRequest
    |> where([a], a.patient_id == ^patient_id)
    |> Repo.aggregate(:count, :id)
  end

  def list_admission_requests_by_doctor_note_id(doctor_note_id) do
    AdmissionRequest
    |> where([a], a.doctor_note_id == ^doctor_note_id)
    |> order_by([a], desc: a.date, desc: a.inserted_at)
    |> Repo.all()
    |> Repo.preload([:doctor_note, :patient, :doctor, :line_items])
  end

  @doc """
  Gets a single admission_request.

  Raises `Ecto.NoResultsError` if the Admission request does not exist.

  ## Examples

      iex> get_admission_request!(123)
      %AdmissionRequest{}

      iex> get_admission_request!(456)
      ** (Ecto.NoResultsError)

  """
  def get_admission_request!(id), do: Repo.get!(AdmissionRequest, id)

  def get_admission_request_with_line_items!(id) do
    Repo.get!(AdmissionRequest, id) |> Repo.preload([:line_items, :patient, :doctor])
  end

  @doc """
  Creates a admission_request.

  ## Examples

      iex> create_admission_request(%{field: value})
      {:ok, %AdmissionRequest{}}

      iex> create_admission_request(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_admission_request(attrs \\ %{}) do
    %AdmissionRequest{}
    |> AdmissionRequest.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a admission_request.

  ## Examples

      iex> update_admission_request(admission_request, %{field: new_value})
      {:ok, %AdmissionRequest{}}

      iex> update_admission_request(admission_request, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_admission_request(%AdmissionRequest{} = admission_request, attrs) do
    admission_request
    |> AdmissionRequest.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a admission_request.

  ## Examples

      iex> delete_admission_request(admission_request)
      {:ok, %AdmissionRequest{}}

      iex> delete_admission_request(admission_request)
      {:error, %Ecto.Changeset{}}

  """
  def delete_admission_request(%AdmissionRequest{} = admission_request) do
    Repo.delete(admission_request)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking admission_request changes.

  ## Examples

      iex> change_admission_request(admission_request)
      %Ecto.Changeset{data: %AdmissionRequest{}}

  """
  def change_admission_request(%AdmissionRequest{} = admission_request, attrs \\ %{}) do
    AdmissionRequest.changeset(admission_request, attrs)
  end

  # Line items

  def list_line_items_for_admission_request(admission_request_id) do
    from(li in LineItem,
      where: li.admission_request_id == ^admission_request_id,
      order_by: [asc: li.inserted_at]
    )
    |> Repo.all()
  end

  def total_line_items_amount(admission_request_id) do
    from(li in LineItem,
      where: li.admission_request_id == ^admission_request_id,
      select: coalesce(sum(li.price), 0)
    )
    |> Repo.one()
    |> then(fn
      nil -> 0
      %Decimal{} = d -> Decimal.to_integer(d)
      n when is_integer(n) -> n
    end)
  end

  def create_line_item(attrs \\ %{}) do
    %LineItem{}
    |> LineItem.changeset(attrs)
    |> Repo.insert()
  end

  def update_line_item(%LineItem{} = line_item, attrs) do
    line_item
    |> LineItem.changeset(attrs)
    |> Repo.update()
  end

  def delete_line_item(%LineItem{} = line_item) do
    Repo.delete(line_item)
  end

  def get_line_item!(id), do: Repo.get!(LineItem, id)

  def get_line_item_with_admission!(id) do
    Repo.get!(LineItem, id) |> Repo.preload(admission_request: [:patient])
  end

  def change_line_item(%LineItem{} = line_item, attrs \\ %{}) do
    LineItem.changeset(line_item, attrs)
  end

  @doc """
  Records payment for a line item and updates the admission's total_amount_paid / fully_paid.
  """
  def add_line_item_payment(line_item_id, amount) do
    line_item = get_line_item_with_admission!(line_item_id)
    admission = line_item.admission_request
    new_line_paid = (line_item.amount_paid || 0) + amount

    Repo.transaction(fn ->
      {:ok, _} =
        update_line_item(line_item, %{"amount_paid" => new_line_paid})

      total_due = total_line_items_amount(admission.id)
      prev = admission.total_amount_paid || 0
      new_total = prev + amount
      fully = total_due == 0 or new_total >= total_due

      update_admission_request(admission, %{
        "has_paid" => true,
        "total_amount_paid" => new_total,
        "fully_paid" => fully
      })
    end)
  end
end
