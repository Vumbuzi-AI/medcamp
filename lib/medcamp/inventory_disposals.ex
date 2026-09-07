defmodule Medcamp.InventoryDisposals do
  @moduledoc """
  Approval workflow for inventory leaving stock because of donation or expiry.
  """

  import Ecto.Query, warn: false

  alias Medcamp.AuditLog
  alias Medcamp.Batches.Batch
  alias Medcamp.DrugBatches.DrugBatch
  alias Medcamp.InventoryDisposals.{InventoryDisposal, InventoryDisposalItem}
  alias Medcamp.LabAllocations.LabAllocation
  alias Medcamp.NursingAllocations.NursingAllocation
  alias Medcamp.Repo
  alias Medcamp.StockTakes

  def list_disposals(kind) when kind in ["donation", "expiry"] do
    from(d in InventoryDisposal,
      where: d.kind == ^kind,
      order_by: [desc: d.inserted_at],
      preload: [:requested_by, :approved_by, :items]
    )
    |> Repo.all()
  end

  def get_disposal!(id) do
    InventoryDisposal
    |> preload([:requested_by, :approved_by, :items])
    |> Repo.get!(id)
  end

  @doc """
  Disposal requests (donations and expiry) raised by a specific requester,
  newest first.
  """
  def list_requester_disposals(requested_by_id) do
    from(d in InventoryDisposal,
      where: d.requested_by_id == ^requested_by_id,
      order_by: [desc: d.inserted_at],
      preload: [:requested_by, :approved_by, :items]
    )
    |> Repo.all()
  end

  def change_disposal(disposal, attrs \\ %{}),
    do: InventoryDisposal.changeset(disposal, attrs)

  def create_disposal(attrs),
    do: %InventoryDisposal{} |> InventoryDisposal.changeset(attrs) |> Repo.insert()

  def create_item(attrs),
    do: %InventoryDisposalItem{} |> InventoryDisposalItem.changeset(attrs) |> Repo.insert()

  @doc """
  Attaches (or replaces) the supporting document on a draft disposal. Donations
  need this before they can be submitted, but it is collected while building the
  request rather than up front.
  """
  def attach_supporting_document(%InventoryDisposal{status: "draft"} = disposal, attrs),
    do: disposal |> InventoryDisposal.changeset(attrs) |> Repo.update()

  def attach_supporting_document(_disposal, _attrs), do: {:error, :not_draft}

  @doc """
  Clears a wrongly-attached document so a draft donation can be re-attached.
  Leaves the old file on disk, matching attach_supporting_document/2.
  """
  def remove_supporting_document(%InventoryDisposal{status: "draft"} = disposal) do
    disposal
    |> InventoryDisposal.changeset(%{
      supporting_document_path: nil,
      supporting_document_name: nil
    })
    |> Repo.update()
  end

  def remove_supporting_document(_disposal), do: {:error, :not_draft}

  def update_item(%InventoryDisposalItem{} = item, attrs),
    do: item |> InventoryDisposalItem.changeset(attrs) |> Repo.update()

  @doc """
  Deletes a disposal request that has not been approved yet. Items cascade with
  the parent row. Approved requests have already moved stock, so they stay as
  the audit record of that movement and can never be deleted.
  """
  def delete_disposal(%InventoryDisposal{status: status} = disposal)
      when status in ["draft", "pending", "rejected"] do
    items = if is_list(disposal.items), do: disposal.items, else: []

    if Enum.any?(items, & &1.has_been_applied) do
      {:error, :already_applied}
    else
      Repo.delete(disposal)
    end
  end

  def delete_disposal(%InventoryDisposal{}), do: {:error, :not_deletable}

  def delete_item(%InventoryDisposalItem{} = item), do: Repo.delete(item)
  def get_item!(id), do: Repo.get!(InventoryDisposalItem, id)

  def search_sources(type, query) do
    results =
      case type do
        "drug_batch" -> StockTakes.search_drug_batches(query)
        "lab_allocation" -> StockTakes.search_lab_allocations(query)
        "nursing_allocation" -> StockTakes.search_nursing_allocations(query)
        "inventory_received" -> StockTakes.search_inventory_received(query)
        _ -> []
      end

    Enum.filter(results, &(source_quantity(type, &1) > 0))
  end

  def source_attributes("drug_batch", source) do
    %{
      entity_type: "drug_batch",
      entity_id: source.id,
      entity_name: StockTakes.drug_batch_display_name(source),
      category: source.drug.inventory_received.category || "Pharmacy",
      available_quantity: source.remaining_quantity || 0,
      uom: source.batch && source.batch.uom
    }
  end

  def source_attributes("lab_allocation", source) do
    %{
      entity_type: "lab_allocation",
      entity_id: source.id,
      entity_name:
        with_batch(
          StockTakes.lab_allocation_display_name(source),
          source_batch("lab_allocation", source)
        ),
      category: "Lab",
      available_quantity: source.remaining_quantity || 0,
      uom: source.uom
    }
  end

  def source_attributes("nursing_allocation", source) do
    %{
      entity_type: "nursing_allocation",
      entity_id: source.id,
      entity_name:
        with_batch(
          StockTakes.nursing_allocation_display_name(source),
          source_batch("nursing_allocation", source)
        ),
      category: "Nursing",
      available_quantity: source.remaining_quantity || 0,
      uom: source.uom
    }
  end

  def source_attributes("inventory_received", source) do
    %{
      entity_type: "inventory_received",
      entity_id: source.id,
      entity_name: StockTakes.inventory_received_display_name(source),
      category: (source.inventory_received && source.inventory_received.category) || "Inventory",
      available_quantity: source.remaining_quantity || 0,
      uom: source.uom
    }
  end

  def source_batch("drug_batch", source), do: batch_identifier(source.batch)

  def source_batch(type, source) when type in ["lab_allocation", "nursing_allocation"] do
    batch = source.inventory_issued && source.inventory_issued.batch
    batch_identifier(batch)
  end

  def source_batch("inventory_received", source), do: batch_identifier(source)
  def source_batch(_, _), do: "—"

  @doc """
  Expiry for a searchable source. Returns a `Date` when it can be parsed, the
  raw string when it cannot, or `nil` when none is recorded. Batches store
  expiry as a string, allocations store a real date.
  """
  def source_expiry("drug_batch", source),
    do: normalize_expiry(source.batch && source.batch.expiry)

  def source_expiry(type, source) when type in ["lab_allocation", "nursing_allocation"],
    do: normalize_expiry(source.expiry_date)

  def source_expiry("inventory_received", source), do: normalize_expiry(source.expiry)
  def source_expiry(_, _), do: nil

  defp normalize_expiry(nil), do: nil
  defp normalize_expiry(%Date{} = date), do: date

  defp normalize_expiry(value) when is_binary(value) do
    case String.trim(value) do
      "" ->
        nil

      trimmed ->
        case Date.from_iso8601(trimmed) do
          {:ok, date} -> date
          _ -> trimmed
        end
    end
  end

  defp normalize_expiry(_), do: nil

  def submit(%InventoryDisposal{status: "draft"} = disposal) do
    disposal = get_disposal!(disposal.id)

    cond do
      disposal.items == [] ->
        {:error, :no_items}

      true ->
        # Stock can have moved since each item was added, so re-check every
        # requested quantity against what the source holds right now — better to
        # stop it here than to have an admin's approval fail at deduction time.
        case Enum.find(disposal.items, &exceeds_current_stock?/1) do
          nil ->
            disposal
            |> InventoryDisposal.changeset(%{status: "pending"})
            |> Repo.update()

          item ->
            {:error, {:insufficient_stock, item.entity_name, current_quantity(item)}}
        end
    end
  end

  def submit(_), do: {:error, :invalid_status}

  defp exceeds_current_stock?(item), do: item.quantity > current_quantity(item)

  @doc """
  The quantity the item's source record holds right now, which may differ from
  the `available_quantity` snapshotted when the item was added to the request.
  """
  def current_quantity(item) do
    case source_record(item) do
      nil -> 0
      record -> record.remaining_quantity || 0
    end
  end

  defp source_record(%{entity_type: "drug_batch", entity_id: id}), do: Repo.get(DrugBatch, id)

  defp source_record(%{entity_type: "lab_allocation", entity_id: id}),
    do: Repo.get(LabAllocation, id)

  defp source_record(%{entity_type: "nursing_allocation", entity_id: id}),
    do: Repo.get(NursingAllocation, id)

  defp source_record(%{entity_type: "inventory_received", entity_id: id}), do: Repo.get(Batch, id)
  defp source_record(_), do: nil

  def reject(%InventoryDisposal{} = disposal, approver_id) do
    Repo.transaction(fn ->
      locked = lock_disposal(disposal.id)
      if locked.status != "pending", do: Repo.rollback(:invalid_status)

      locked
      |> InventoryDisposal.changeset(%{
        status: "rejected",
        approved_by_id: approver_id,
        approved_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      |> Repo.update!()
    end)
  end

  def approve(%InventoryDisposal{} = disposal, approver_id) do
    Repo.transaction(fn ->
      locked = disposal.id |> lock_disposal() |> Repo.preload(:items)

      if locked.status != "pending", do: Repo.rollback(:invalid_status)
      if locked.items == [], do: Repo.rollback(:no_items)

      Enum.each(locked.items, &deduct_item(&1, locked, approver_id))

      locked
      |> InventoryDisposal.changeset(%{
        status: "approved",
        approved_by_id: approver_id,
        approved_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      |> Repo.update!()
    end)
  end

  defp deduct_item(item, disposal, approver_id) do
    {record, changeset_fun, table_name} = lock_source(item)
    available = record.remaining_quantity || 0

    if item.has_been_applied, do: Repo.rollback({:already_applied, item.id})

    if item.quantity > available,
      do: Repo.rollback({:insufficient_stock, item.entity_name, available})

    new_quantity = available - item.quantity

    record
    |> changeset_fun.(%{remaining_quantity: new_quantity})
    |> Repo.update!()

    %AuditLog{}
    |> AuditLog.changeset(%{
      user_id: approver_id,
      action: "#{disposal.kind}_inventory",
      table_name: table_name,
      record_id: record.id,
      previous_state: %{"remaining_quantity" => available},
      new_state: %{
        "remaining_quantity" => new_quantity,
        "quantity_removed" => item.quantity,
        "inventory_disposal_id" => disposal.id
      },
      changed_fields: ["remaining_quantity"]
    })
    |> Repo.insert!()

    item
    |> InventoryDisposalItem.changeset(%{has_been_applied: true})
    |> Repo.update!()
  end

  defp lock_source(%{entity_type: "drug_batch", entity_id: id}) do
    {lock_record(DrugBatch, id), &DrugBatch.changeset/2, "drug_batches"}
  end

  defp lock_source(%{entity_type: "lab_allocation", entity_id: id}) do
    {lock_record(LabAllocation, id), &LabAllocation.changeset/2, "lab_allocations"}
  end

  defp lock_source(%{entity_type: "nursing_allocation", entity_id: id}) do
    {lock_record(NursingAllocation, id), &NursingAllocation.changeset/2, "nursing_allocations"}
  end

  defp lock_source(%{entity_type: "inventory_received", entity_id: id}) do
    {lock_record(Batch, id), &Batch.changeset/2, "batches"}
  end

  defp lock_record(schema, id) do
    from(r in schema, where: r.id == ^id, lock: "FOR UPDATE")
    |> Repo.one()
    |> case do
      nil -> Repo.rollback({:source_not_found, id})
      record -> record
    end
  end

  defp lock_disposal(id) do
    from(d in InventoryDisposal, where: d.id == ^id, lock: "FOR UPDATE")
    |> Repo.one!()
  end

  defp source_quantity(_, source), do: source.remaining_quantity || 0

  defp batch_identifier(nil), do: "—"

  defp batch_identifier(batch),
    do: batch.batch || batch.serial || batch.gtin || "Batch ##{batch.id}"

  defp with_batch(name, "—"), do: name
  defp with_batch(name, batch), do: "#{name} — Batch: #{batch}"
end
