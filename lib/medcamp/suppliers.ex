defmodule Medcamp.Suppliers do
  @moduledoc """
  The Suppliers context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.Suppliers.Supplier
  alias Medcamp.Suppliers.SupplierDocument
  alias Medcamp.Suppliers.SupplierInvoice
  alias Medcamp.Suppliers.SupplierQuote
  alias Medcamp.Suppliers.SupplierDeliveryNote
  alias Medcamp.Suppliers.SupplierAdvanceShipNotice
  alias Medcamp.Suppliers.SupplierRecall
  alias Medcamp.Batches
  alias Medcamp.Drugs

  @doc """
  Returns the list of suppliers.

  ## Examples

      iex> list_suppliers()
      [%Supplier{}, ...]

  """
  def list_suppliers do
    Repo.all(Supplier)
  end

  def list_suppliers_paginated(page \\ 1, per_page \\ 20, search \\ "") do
    Supplier
    |> apply_supplier_search(search)
    |> order_by([s], asc: s.name)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
  end

  def count_suppliers(search \\ "") do
    Supplier
    |> apply_supplier_search(search)
    |> Repo.aggregate(:count, :id)
  end

  defp apply_supplier_search(query, nil), do: query
  defp apply_supplier_search(query, ""), do: query

  defp apply_supplier_search(query, term) do
    search = "%#{term}%"

    where(
      query,
      [s],
      ilike(s.name, ^search) or ilike(s.email, ^search) or ilike(s.contact, ^search)
    )
  end

  def list_suppliers_for_select do
    Repo.all(from s in Supplier, select: s.name)
  end

  @doc """
  Returns list of {name, id} for use in select inputs.
  """
  def list_suppliers_for_selection do
    Repo.all(from s in Supplier, order_by: [asc: s.name], select: {s.name, s.id})
  end

  @doc """
  Gets a single supplier.

  Raises `Ecto.NoResultsError` if the Supplier does not exist.

  ## Examples

      iex> get_supplier!(123)
      %Supplier{}

      iex> get_supplier!(456)
      ** (Ecto.NoResultsError)

  """
  def get_supplier!(id), do: Repo.get!(Supplier, id) |> Repo.preload(:supplier_documents)

  @doc """
  Creates a supplier.

  ## Examples

      iex> create_supplier(%{field: value})
      {:ok, %Supplier{}}

      iex> create_supplier(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_supplier(attrs \\ %{}) do
    %Supplier{}
    |> Supplier.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a supplier.

  ## Examples

      iex> update_supplier(supplier, %{field: new_value})
      {:ok, %Supplier{}}

      iex> update_supplier(supplier, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_supplier(%Supplier{} = supplier, attrs) do
    supplier
    |> Supplier.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a supplier.

  ## Examples

      iex> delete_supplier(supplier)
      {:ok, %Supplier{}}

      iex> delete_supplier(supplier)
      {:error, %Ecto.Changeset{}}

  """
  def delete_supplier(%Supplier{} = supplier) do
    Repo.delete(supplier)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking supplier changes.

  ## Examples

      iex> change_supplier(supplier)
      %Ecto.Changeset{data: %Supplier{}}

  """
  def change_supplier(%Supplier{} = supplier, attrs \\ %{}) do
    Supplier.changeset(supplier, attrs)
  end

  # Supplier documents
  def list_supplier_documents(supplier_id) do
    from(sd in SupplierDocument,
      where: sd.supplier_id == ^supplier_id,
      order_by: [desc: sd.inserted_at]
    )
    |> Repo.all()
  end

  def create_supplier_document(attrs \\ %{}) do
    %SupplierDocument{}
    |> SupplierDocument.changeset(attrs)
    |> Repo.insert()
  end

  def delete_supplier_document(%SupplierDocument{} = doc), do: Repo.delete(doc)

  def get_supplier_document!(id), do: Repo.get!(SupplierDocument, id)

  # Data for supplier show page (supplier link is at batch level: batch.supplier_id)
  # Distinct inventory received items that have at least one batch from this supplier
  def list_inventories_received_for_supplier(supplier_id) do
    alias Medcamp.InventoriesReceived.InventoryReceived

    from(ir in InventoryReceived,
      inner_join: b in Medcamp.Batches.Batch,
      on: b.inventory_received_id == ir.id,
      where: b.supplier_id == ^supplier_id,
      distinct: true,
      order_by: [asc: ir.brand_name],
      preload: []
    )
    |> Repo.all()
  end

  def list_batches_for_supplier(supplier_id) do
    Batches.filter_batches(%{"supplier_id" => supplier_id})
  end

  def list_drugs_for_supplier(supplier) do
    Drugs.filter_drugs(%{"supplier" => supplier.name})
  end

  def total_remaining_quantity_for_supplier(supplier_id) do
    from(b in Medcamp.Batches.Batch,
      where: b.supplier_id == ^supplier_id,
      select: coalesce(sum(b.remaining_quantity), 0)
    )
    |> Repo.one()
  end

  @doc """
  Total quantity supplied (sum of batch.quantity for all batches from this supplier).
  """
  def total_supplied_quantity_for_supplier(supplier_id) do
    from(b in Medcamp.Batches.Batch,
      where: b.supplier_id == ^supplier_id,
      select: coalesce(sum(b.quantity), 0)
    )
    |> Repo.one()
  end

  @doc """
  Total quantity used/consumed (supplied - remaining).
  """
  def total_used_quantity_for_supplier(supplier_id) do
    supplied = total_supplied_quantity_for_supplier(supplier_id)
    remaining = total_remaining_quantity_for_supplier(supplier_id)
    max(0, supplied - remaining)
  end

  def list_nursing_allocations_for_supplier(supplier_id) do
    from(na in Medcamp.NursingAllocations.NursingAllocation,
      join: ii in assoc(na, :inventory_issued),
      join: b in assoc(ii, :batch),
      where: b.supplier_id == ^supplier_id,
      order_by: [desc: na.inserted_at],
      preload: [
        inventory_issued: [:inventory_received, batch: :inventory_received],
        allocated_to_user: [],
        allocated_by_user: []
      ]
    )
    |> Repo.all()
  end

  def list_lab_allocations_for_supplier(supplier_id) do
    from(la in Medcamp.LabAllocations.LabAllocation,
      join: ii in assoc(la, :inventory_issued),
      join: b in assoc(ii, :batch),
      where: b.supplier_id == ^supplier_id,
      order_by: [desc: la.inserted_at],
      preload: [
        inventory_issued: [:inventory_received, batch: :inventory_received],
        allocated_to_user: [],
        allocated_by_user: []
      ]
    )
    |> Repo.all()
  end

  @doc """
  Returns batches from this supplier where remaining_quantity is at or below the threshold
  (and > 0). Used for low-stock notifications to suppliers.
  """
  def list_low_stock_batches_for_supplier(supplier_id, threshold \\ 20) do
    from(b in Medcamp.Batches.Batch,
      where: b.supplier_id == ^supplier_id,
      where: b.remaining_quantity > 0 and b.remaining_quantity <= ^threshold,
      order_by: [asc: b.remaining_quantity],
      preload: [:inventory_received]
    )
    |> Repo.all()
  end

  # ---------------------------------------------------------------------------
  # Supplier Invoices
  # ---------------------------------------------------------------------------

  def list_supplier_invoices(supplier_id) do
    from(si in SupplierInvoice,
      where: si.supplier_id == ^supplier_id,
      order_by: [desc: si.inserted_at]
    )
    |> Repo.all()
  end

  def get_supplier_invoice!(id), do: Repo.get!(SupplierInvoice, id)

  def create_supplier_invoice(attrs \\ %{}) do
    %SupplierInvoice{}
    |> SupplierInvoice.changeset(attrs)
    |> Repo.insert()
  end

  def update_supplier_invoice(%SupplierInvoice{} = invoice, attrs) do
    invoice
    |> SupplierInvoice.changeset(attrs)
    |> Repo.update()
  end

  def delete_supplier_invoice(%SupplierInvoice{} = invoice), do: Repo.delete(invoice)

  def change_supplier_invoice(%SupplierInvoice{} = invoice, attrs \\ %{}) do
    SupplierInvoice.changeset(invoice, attrs)
  end

  # ---------------------------------------------------------------------------
  # Supplier Quotes
  # ---------------------------------------------------------------------------

  def list_supplier_quotes(supplier_id) do
    from(sq in SupplierQuote,
      where: sq.supplier_id == ^supplier_id,
      order_by: [desc: sq.inserted_at]
    )
    |> Repo.all()
  end

  def get_supplier_quote!(id), do: Repo.get!(SupplierQuote, id)

  def create_supplier_quote(attrs \\ %{}) do
    %SupplierQuote{}
    |> SupplierQuote.changeset(attrs)
    |> Repo.insert()
  end

  def update_supplier_quote(%SupplierQuote{} = quote, attrs) do
    quote
    |> SupplierQuote.changeset(attrs)
    |> Repo.update()
  end

  def delete_supplier_quote(%SupplierQuote{} = quote), do: Repo.delete(quote)

  def change_supplier_quote(%SupplierQuote{} = quote, attrs \\ %{}) do
    SupplierQuote.changeset(quote, attrs)
  end

  # ---------------------------------------------------------------------------
  # Supplier Delivery Notes
  # ---------------------------------------------------------------------------

  def list_supplier_delivery_notes(supplier_id) do
    from(dn in SupplierDeliveryNote,
      where: dn.supplier_id == ^supplier_id,
      order_by: [desc: dn.inserted_at]
    )
    |> Repo.all()
  end

  def get_supplier_delivery_note!(id), do: Repo.get!(SupplierDeliveryNote, id)

  def create_supplier_delivery_note(attrs \\ %{}) do
    %SupplierDeliveryNote{}
    |> SupplierDeliveryNote.changeset(attrs)
    |> Repo.insert()
  end

  def update_supplier_delivery_note(%SupplierDeliveryNote{} = dn, attrs) do
    dn
    |> SupplierDeliveryNote.changeset(attrs)
    |> Repo.update()
  end

  def delete_supplier_delivery_note(%SupplierDeliveryNote{} = dn), do: Repo.delete(dn)

  def change_supplier_delivery_note(%SupplierDeliveryNote{} = dn, attrs \\ %{}) do
    SupplierDeliveryNote.changeset(dn, attrs)
  end

  # ---------------------------------------------------------------------------
  # Supplier Advance Ship Notices
  # ---------------------------------------------------------------------------

  def list_supplier_advance_ship_notices(supplier_id) do
    from(asn in SupplierAdvanceShipNotice,
      where: asn.supplier_id == ^supplier_id,
      order_by: [desc: asn.inserted_at]
    )
    |> Repo.all()
  end

  def get_supplier_advance_ship_notice!(id), do: Repo.get!(SupplierAdvanceShipNotice, id)

  def create_supplier_advance_ship_notice(attrs \\ %{}) do
    %SupplierAdvanceShipNotice{}
    |> SupplierAdvanceShipNotice.changeset(attrs)
    |> Repo.insert()
  end

  def update_supplier_advance_ship_notice(%SupplierAdvanceShipNotice{} = asn, attrs) do
    asn
    |> SupplierAdvanceShipNotice.changeset(attrs)
    |> Repo.update()
  end

  def delete_supplier_advance_ship_notice(%SupplierAdvanceShipNotice{} = asn),
    do: Repo.delete(asn)

  def change_supplier_advance_ship_notice(%SupplierAdvanceShipNotice{} = asn, attrs \\ %{}) do
    SupplierAdvanceShipNotice.changeset(asn, attrs)
  end

  # ---------------------------------------------------------------------------
  # Supplier Recalls
  # ---------------------------------------------------------------------------

  def list_supplier_recalls(supplier_id) do
    from(r in SupplierRecall,
      where: r.supplier_id == ^supplier_id,
      order_by: [desc: r.inserted_at]
    )
    |> Repo.all()
  end

  def get_supplier_recall!(id), do: Repo.get!(SupplierRecall, id)

  def create_supplier_recall(attrs \\ %{}) do
    %SupplierRecall{}
    |> SupplierRecall.changeset(attrs)
    |> Repo.insert()
  end

  def update_supplier_recall(%SupplierRecall{} = recall, attrs) do
    recall
    |> SupplierRecall.changeset(attrs)
    |> Repo.update()
  end

  def delete_supplier_recall(%SupplierRecall{} = recall), do: Repo.delete(recall)

  def change_supplier_recall(%SupplierRecall{} = recall, attrs \\ %{}) do
    SupplierRecall.changeset(recall, attrs)
  end

  @doc """
  Returns a list of %{supplier: %Supplier{}, low_stock_batches: [%Batch{}]} for every supplier
  that has at least one batch with remaining_quantity in (0, threshold].
  """
  def list_suppliers_with_low_stock(threshold \\ 20) do
    from(b in Medcamp.Batches.Batch,
      where: not is_nil(b.supplier_id),
      where: b.remaining_quantity > 0 and b.remaining_quantity <= ^threshold,
      preload: [:supplier, :inventory_received]
    )
    |> Repo.all()
    |> Enum.group_by(fn b -> b.supplier_id end, fn b -> b end)
    |> Enum.map(fn {_supplier_id, batches} ->
      supplier = hd(batches).supplier
      %{supplier: supplier, low_stock_batches: batches}
    end)
    |> Enum.filter(fn %{supplier: s} -> s && s.email end)
  end
end
