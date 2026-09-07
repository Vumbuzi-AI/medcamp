defmodule Medcamp.Procurement.Suppliers do
  @moduledoc """
  Supplier registration lifecycle, compliance scoring, director/document upserts.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo
  alias Ecto.Multi

  alias Medcamp.Suppliers.Supplier
  alias Medcamp.Suppliers.SupplierDocument
  alias Medcamp.Procurement.{SupplierDirector, References, Notifications}

  @pubsub Medcamp.PubSub

  @required_document_types ~w(registration_cert pin_cert trade_licence)

  def required_document_types, do: @required_document_types

  # ---------------------------------------------------------------------------
  # Queries
  # ---------------------------------------------------------------------------

  def list_suppliers(opts \\ []) do
    status = Keyword.get(opts, :status)

    Supplier
    |> maybe_filter_status(status)
    |> order_by([s], desc: s.inserted_at)
    |> Repo.all()
  end

  def list_pending_registrations do
    from(s in Supplier,
      where: s.status in ["pending", "under_review"],
      order_by: [asc: s.inserted_at]
    )
    |> Repo.all()
  end

  def get_supplier!(id) do
    Supplier
    |> Repo.get!(id)
    |> Repo.preload([:directors, :approved_by, supplier_documents: :verified_by])
  end

  def get_supplier(id) do
    case Repo.get(Supplier, id) do
      nil ->
        nil

      supplier ->
        Repo.preload(supplier, [:directors, :approved_by, supplier_documents: :verified_by])
    end
  end

  def get_document(id) do
    case Repo.get(SupplierDocument, id) do
      nil -> nil
      document -> Repo.preload(document, [:supplier, :verified_by])
    end
  end

  defp maybe_filter_status(query, nil), do: query
  defp maybe_filter_status(query, status), do: where(query, [s], s.status == ^status)

  # ---------------------------------------------------------------------------
  # Registration CRUD
  # ---------------------------------------------------------------------------

  @doc """
  Creates a supplier registration record in pending state with a generated reference.
  """
  def create_supplier_registration(attrs \\ %{}) do
    attrs =
      attrs
      |> Map.new()
      |> Map.put_new(:reference, References.next_supplier_reference())
      |> Map.put_new(:status, "pending")

    %Supplier{}
    |> Supplier.registration_changeset(attrs)
    |> Repo.insert()
  end

  def update_registration(%Supplier{} = supplier, attrs) do
    supplier
    |> Supplier.registration_changeset(attrs)
    |> Repo.update()
  end

  def change_registration(%Supplier{} = supplier, attrs \\ %{}) do
    Supplier.registration_changeset(supplier, attrs)
  end

  # ---------------------------------------------------------------------------
  # Submission
  # ---------------------------------------------------------------------------

  @doc """
  Marks a draft/pending registration as `under_review`, recomputes compliance
  score, and broadcasts `{:registration_submitted, supplier}` on
  `"procurement:all"`.
  """
  def submit_registration(%Supplier{} = supplier) do
    supplier = Repo.preload(supplier, [:supplier_documents, :directors])
    score = compute_compliance_score(supplier)

    supplier
    |> Supplier.registration_changeset(%{status: "under_review", compliance_score: score})
    |> Repo.update()
    |> case do
      {:ok, updated} ->
        broadcast_all({:registration_submitted, updated})
        {:ok, updated}

      error ->
        error
    end
  end

  # ---------------------------------------------------------------------------
  # Approval / Rejection
  # ---------------------------------------------------------------------------

  def approve(%Supplier{} = supplier, %{id: approver_id}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    attrs = %{
      status: "approved",
      approved_by_id: approver_id,
      approved_at: now,
      rejection_reason: nil
    }

    Multi.new()
    |> Multi.update(:supplier, Supplier.registration_changeset(supplier, attrs))
    |> Multi.run(:notify, fn _repo, %{supplier: s} ->
      notify_supplier_users(s, "registration_approved", %{
        title: "Registration approved",
        body: "Your supplier registration has been approved.",
        resource_type: "supplier",
        resource_id: s.id
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{supplier: s}} ->
        broadcast_supplier(s, {:supplier_approved, s})
        broadcast_all({:supplier_approved, s})
        {:ok, s}

      {:error, _op, reason, _} ->
        {:error, reason}
    end
  end

  def reject(%Supplier{} = supplier, %{id: approver_id}, reason) when is_binary(reason) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    attrs = %{
      status: "rejected",
      approved_by_id: approver_id,
      approved_at: now,
      rejection_reason: reason
    }

    Multi.new()
    |> Multi.update(:supplier, Supplier.registration_changeset(supplier, attrs))
    |> Multi.run(:notify, fn _repo, %{supplier: s} ->
      notify_supplier_users(s, "registration_rejected", %{
        title: "Registration rejected",
        body: reason,
        resource_type: "supplier",
        resource_id: s.id
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{supplier: s}} ->
        broadcast_supplier(s, {:supplier_rejected, s})
        broadcast_all({:supplier_rejected, s})
        {:ok, s}

      {:error, _op, reason, _} ->
        {:error, reason}
    end
  end

  def request_more_info(%Supplier{} = supplier, %{id: approver_id}, note) when is_binary(note) do
    attrs = %{
      status: "pending",
      approved_by_id: approver_id,
      rejection_reason: note
    }

    Multi.new()
    |> Multi.update(:supplier, Supplier.registration_changeset(supplier, attrs))
    |> Multi.run(:notify, fn _repo, %{supplier: s} ->
      notify_supplier_users(s, "registration_rejected", %{
        title: "More information required",
        body: note,
        resource_type: "supplier",
        resource_id: s.id
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{supplier: s}} ->
        broadcast_supplier(s, {:supplier_info_requested, s})
        {:ok, s}

      {:error, _op, reason, _} ->
        {:error, reason}
    end
  end

  # ---------------------------------------------------------------------------
  # Compliance
  # ---------------------------------------------------------------------------

  @doc """
  Returns an integer 0..100. Weights:
    * 40 — all required documents present
    * 20 — documents verified
    * 20 — ≥1 director with an ID document
    * 20 — banking + KRA details provided
  """
  def compute_compliance_score(%Supplier{} = supplier) do
    supplier = Repo.preload(supplier, [:supplier_documents, :directors])

    docs_score = if documents_complete?(supplier), do: 40, else: 0

    verified_score =
      cond do
        Enum.empty?(supplier.supplier_documents) -> 0
        Enum.all?(supplier.supplier_documents, & &1.verified) -> 20
        true -> 0
      end

    director_score =
      if Enum.any?(supplier.directors, fn d -> d.id_document_path not in [nil, ""] end),
        do: 20,
        else: 0

    banking_score =
      if present?(supplier.account_number) and present?(supplier.bank_name) and
           present?(supplier.kra_pin),
         do: 20,
         else: 0

    docs_score + verified_score + director_score + banking_score
  end

  def documents_complete?(%Supplier{} = supplier) do
    supplier = Repo.preload(supplier, :supplier_documents)

    present_types =
      supplier.supplier_documents
      |> Enum.map(& &1.document_type)
      |> MapSet.new()

    Enum.all?(@required_document_types, &MapSet.member?(present_types, &1))
  end

  defp present?(nil), do: false
  defp present?(""), do: false
  defp present?(_), do: true

  # ---------------------------------------------------------------------------
  # Directors
  # ---------------------------------------------------------------------------

  def list_directors(supplier_id) do
    from(d in SupplierDirector, where: d.supplier_id == ^supplier_id, order_by: [asc: d.id])
    |> Repo.all()
  end

  def upsert_director(attrs) do
    attrs = Map.new(attrs)

    case Map.get(attrs, :id) || Map.get(attrs, "id") do
      nil ->
        %SupplierDirector{}
        |> SupplierDirector.changeset(attrs)
        |> Repo.insert()

      id ->
        SupplierDirector
        |> Repo.get!(id)
        |> SupplierDirector.changeset(attrs)
        |> Repo.update()
    end
  end

  def delete_director(%SupplierDirector{} = director), do: Repo.delete(director)

  # ---------------------------------------------------------------------------
  # Documents
  # ---------------------------------------------------------------------------

  @doc """
  Inserts or replaces the supplier document for a given `[supplier_id, document_type]` pair.
  """
  def upsert_document(attrs) do
    attrs = Map.new(attrs)
    supplier_id = Map.get(attrs, :supplier_id) || Map.get(attrs, "supplier_id")
    doc_type = Map.get(attrs, :document_type) || Map.get(attrs, "document_type")

    existing =
      if supplier_id && doc_type do
        Repo.get_by(SupplierDocument, supplier_id: supplier_id, document_type: doc_type)
      end

    case existing do
      nil ->
        %SupplierDocument{}
        |> SupplierDocument.changeset(attrs)
        |> Repo.insert()

      doc ->
        doc
        |> SupplierDocument.changeset(attrs)
        |> Repo.update()
    end
  end

  def verify_document(%SupplierDocument{} = doc, %{id: verifier_id}) do
    Multi.new()
    |> Multi.update(
      :document,
      SupplierDocument.changeset(doc, %{verified: true, verified_by_id: verifier_id})
    )
    |> Multi.run(:supplier, fn _repo, %{document: document} ->
      supplier = get_supplier!(document.supplier_id)
      score = compute_compliance_score(supplier)

      supplier
      |> Supplier.registration_changeset(%{compliance_score: score})
      |> Repo.update()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{document: document, supplier: supplier}} ->
        broadcast_supplier(supplier, {:supplier_document_verified, supplier})
        broadcast_all({:supplier_document_verified, supplier})
        {:ok, Repo.preload(document, [:verified_by])}

      {:error, :document, reason, _changes} ->
        {:error, reason}

      {:error, :supplier, reason, _changes} ->
        {:error, reason}
    end
  end

  # ---------------------------------------------------------------------------
  # PubSub helpers
  # ---------------------------------------------------------------------------

  defp broadcast_all(msg), do: Phoenix.PubSub.broadcast(@pubsub, "procurement:all", msg)

  defp broadcast_supplier(%Supplier{id: id}, msg),
    do: Phoenix.PubSub.broadcast(@pubsub, "supplier:#{id}", msg)

  defp notify_supplier_users(%Supplier{id: supplier_id}, type, attrs) do
    user_ids =
      from(u in Medcamp.Accounts.User, where: u.supplier_id == ^supplier_id, select: u.id)
      |> Repo.all()

    Enum.each(user_ids, fn uid -> Notifications.notify(uid, type, attrs) end)
    {:ok, length(user_ids)}
  end
end
