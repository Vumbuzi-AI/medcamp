defmodule Medcamp.StockTakes do
  @moduledoc """
  Context for stock take sessions.
  A stock take groups physical count entries, lets the admin review differences,
  then applies all changes to the actual records and writes audit trail entries.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo
  alias Medcamp.StockTakes.StockTake
  alias Medcamp.StockTakes.StockTakeEntry
  alias Medcamp.DrugBatches.DrugBatch
  alias Medcamp.LabAllocations.LabAllocation
  alias Medcamp.NursingAllocations.NursingAllocation
  alias Medcamp.Batches.Batch
  alias Medcamp.AuditLog

  # ── Stock Take CRUD ────────────────────────────────────────────────────────

  def list_stock_takes do
    StockTake
    |> order_by([s], desc: s.inserted_at)
    |> preload([:admin, :requested_by, :approved_by, :department, :entries])
    |> Repo.all()
  end

  def list_stock_takes_paginated(page \\ 1, per_page \\ 10, department_id \\ nil) do
    department_id = normalize_department_id(department_id)

    query =
      StockTake
      |> order_by([s], desc: s.inserted_at)
      |> preload([:admin, :requested_by, :approved_by, :department, :entries])

    query =
      if department_id do
        from(s in query, where: s.department_id == ^department_id)
      else
        query
      end

    query
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
  end

  def count_stock_takes(department_id \\ nil) do
    department_id = normalize_department_id(department_id)
    query = StockTake

    query =
      if department_id do
        from(s in query, where: s.department_id == ^department_id)
      else
        query
      end

    Repo.aggregate(query, :count, :id)
  end

  defp normalize_department_id(nil), do: nil
  defp normalize_department_id(""), do: nil

  defp normalize_department_id(department_id) when is_integer(department_id) do
    department_id
  end

  defp normalize_department_id(department_id) when is_binary(department_id) do
    case Integer.parse(department_id) do
      {id, ""} -> id
      _ -> nil
    end
  end

  defp normalize_department_id(_department_id), do: nil

  @doc """
  Stock takes raised by a specific requester (bucket user), newest first.
  """
  def list_requester_stock_takes(requested_by_id) do
    from(s in StockTake,
      where: s.requested_by_id == ^requested_by_id,
      order_by: [desc: s.inserted_at],
      preload: [:admin, :requested_by, :approved_by, :department, :entries]
    )
    |> Repo.all()
  end

  def get_stock_take!(id) do
    StockTake
    |> preload([:admin, :requested_by, :approved_by, :department, entries: []])
    |> Repo.get!(id)
  end

  def create_stock_take(attrs) do
    attrs = maybe_auto_fill_department_id(attrs)

    %StockTake{}
    |> StockTake.changeset(attrs)
    |> Repo.insert()
  end

  def update_stock_take(%StockTake{} = stock_take, attrs) do
    stock_take
    |> StockTake.changeset(attrs)
    |> Repo.update()
  end

  def change_stock_take(%StockTake{} = stock_take, attrs \\ %{}) do
    attrs = maybe_auto_fill_department_id(attrs)
    StockTake.changeset(stock_take, attrs)
  end

  defp maybe_auto_fill_department_id(attrs) do
    dept_key_present? =
      Map.has_key?(attrs, "department_id") || Map.has_key?(attrs, :department_id)

    cond do
      dept_key_present? ->
        attrs

      true ->
        raw_user_id = Map.get(attrs, "requested_by_id") || Map.get(attrs, :requested_by_id)

        case normalize_user_id(raw_user_id) do
          user_id when is_integer(user_id) ->
            case Repo.get(Medcamp.Accounts.User, user_id) do
              %Medcamp.Accounts.User{department_id: user_dept_id} when not is_nil(user_dept_id) ->
                if Map.has_key?(attrs, :requested_by_id) do
                  Map.put(attrs, :department_id, user_dept_id)
                else
                  Map.put(attrs, "department_id", user_dept_id)
                end

              _ ->
                attrs
            end

          _ ->
            attrs
        end
    end
  end

  defp normalize_user_id(id) when is_integer(id), do: id

  defp normalize_user_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {parsed, ""} -> parsed
      _ -> nil
    end
  end

  defp normalize_user_id(_), do: nil

  def delete_stock_take(%StockTake{} = stock_take) do
    Repo.delete(stock_take)
  end

  @doc """
  Deletes a stock take that has not been approved yet. Entries cascade with the
  parent row. Approved/completed stock takes have already adjusted stock, so
  they stay as the audit record of that adjustment.
  """
  def delete_requester_stock_take(%StockTake{status: status} = stock_take)
      when status in ["draft", "pending", "rejected"],
      do: Repo.delete(stock_take)

  def delete_requester_stock_take(%StockTake{}), do: {:error, :not_deletable}

  # ── Stock Take Entry CRUD ──────────────────────────────────────────────────

  def create_entry(attrs) do
    %StockTakeEntry{}
    |> StockTakeEntry.changeset(attrs)
    |> Repo.insert()
  end

  def update_entry(%StockTakeEntry{} = entry, attrs) do
    entry
    |> StockTakeEntry.changeset(attrs)
    |> Repo.update()
  end

  def delete_entry(%StockTakeEntry{} = entry) do
    Repo.delete(entry)
  end

  def get_entry!(id), do: Repo.get!(StockTakeEntry, id)

  def change_entry(%StockTakeEntry{} = entry, attrs \\ %{}) do
    StockTakeEntry.changeset(entry, attrs)
  end

  # ── Searchable Items ───────────────────────────────────────────────────────

  @doc """
  Search drug batches by drug name, generic name or batch serial.
  Returns a list ready to be added as stock take entries.

  `limit` caps the rows returned; pass a larger one when the caller narrows the
  results further in memory (e.g. by expiry) and would otherwise filter a
  too-small candidate set down to nothing.
  """
  def search_drug_batches(query, limit \\ 20) do
    term = "%#{query}%"

    from(db in DrugBatch,
      join: d in assoc(db, :drug),
      join: ir in assoc(d, :inventory_received),
      join: b in assoc(db, :batch),
      where:
        db.is_active == true and
          (ilike(ir.brand_name, ^term) or
             ilike(ir.generic_name, ^term) or
             ilike(b.batch, ^term) or
             ilike(b.serial, ^term) or
             ilike(b.gtin, ^term)),
      order_by: [asc: ir.brand_name],
      limit: ^limit,
      preload: [drug: :inventory_received, batch: []]
    )
    |> Repo.all()
  end

  @doc """
  List all active drug batches (including those with 0 remaining quantity).
  """
  def list_drug_batches_for_stock_take do
    from(db in DrugBatch,
      join: d in assoc(db, :drug),
      join: ir in assoc(d, :inventory_received),
      join: b in assoc(db, :batch),
      where: db.is_active == true,
      order_by: [asc: ir.brand_name, asc: b.batch],
      preload: [drug: :inventory_received, batch: []]
    )
    |> Repo.all()
  end

  @doc """
  Search lab allocations by brand name, generic name, or GTIN of the linked inventory received.
  """
  def search_lab_allocations(query, limit \\ 20) do
    term = "%#{query}%"

    from(la in LabAllocation,
      join: ii in assoc(la, :inventory_issued),
      join: ir in assoc(ii, :inventory_received),
      left_join: b in assoc(ii, :batch),
      where:
        not is_nil(la.remaining_quantity) and
          (ilike(ir.brand_name, ^term) or
             ilike(ir.generic_name, ^term) or
             ilike(ir.gtin, ^term) or
             ilike(b.batch, ^term) or
             ilike(b.serial, ^term) or
             ilike(b.gtin, ^term)),
      order_by: [asc: ir.brand_name],
      limit: ^limit,
      preload: [
        :allocated_by_user,
        :allocated_to_user,
        inventory_issued: [:inventory_received, :batch]
      ]
    )
    |> Repo.all()
  end

  @doc """
  Search nursing allocations by brand name, generic name, or GTIN of the linked inventory received.
  """
  def search_nursing_allocations(query, limit \\ 20) do
    term = "%#{query}%"

    from(na in NursingAllocation,
      join: ii in assoc(na, :inventory_issued),
      join: ir in assoc(ii, :inventory_received),
      left_join: b in assoc(ii, :batch),
      where:
        not is_nil(na.remaining_quantity) and
          (ilike(ir.brand_name, ^term) or
             ilike(ir.generic_name, ^term) or
             ilike(ir.gtin, ^term) or
             ilike(b.batch, ^term) or
             ilike(b.serial, ^term) or
             ilike(b.gtin, ^term)),
      order_by: [asc: ir.brand_name],
      limit: ^limit,
      preload: [
        :allocated_by_user,
        :allocated_to_user,
        inventory_issued: [:inventory_received, :batch]
      ]
    )
    |> Repo.all()
  end

  @doc """
  Search inventory received batches by brand name, generic name, or GTIN.
  Returns Batch records linked to a matching InventoryReceived.
  """
  def search_inventory_received(query, limit \\ 20) do
    term = "%#{query}%"

    from(b in Batch,
      join: ir in assoc(b, :inventory_received),
      where:
        ilike(ir.brand_name, ^term) or
          ilike(ir.generic_name, ^term) or
          ilike(ir.gtin, ^term) or
          ilike(b.gtin, ^term) or
          ilike(b.batch, ^term) or
          ilike(b.serial, ^term),
      order_by: [asc: ir.brand_name, asc: b.batch],
      limit: ^limit,
      preload: [:inventory_received]
    )
    |> Repo.all()
  end

  # ── Approval workflow (requester-raised stock takes) ────────────────────────

  @doc """
  Moves a requester's draft stock take to `pending` so an admin can review it.
  Requires at least one entry with a recorded count.
  """
  def submit_stock_take(%StockTake{status: "draft"} = stock_take) do
    stock_take = get_stock_take!(stock_take.id)

    if Enum.any?(stock_take.entries, &(&1.counted_quantity != nil)) do
      stock_take
      |> StockTake.changeset(%{status: "pending"})
      |> Repo.update()
    else
      {:error, :no_counts}
    end
  end

  def submit_stock_take(_), do: {:error, :invalid_status}

  @doc """
  Admin approval of a pending stock take: applies every counted entry to the
  underlying records (identical to a direct admin stock take), records the
  approver, and marks the session `completed`.
  """
  def approve_stock_take(%StockTake{} = stock_take, approver_id) do
    Repo.transaction(fn ->
      locked = lock_stock_take(stock_take.id)
      if locked.status != "pending", do: Repo.rollback(:invalid_status)

      countable_entries(stock_take.id)
      |> Enum.each(&apply_entry(&1, approver_id))

      locked
      |> StockTake.changeset(%{
        status: "completed",
        admin_id: locked.admin_id || approver_id,
        approved_by_id: approver_id,
        approved_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      |> Repo.update!()
    end)
  end

  @doc """
  Admin rejection of a pending stock take. No stock is changed.
  """
  def reject_stock_take(%StockTake{} = stock_take, approver_id) do
    Repo.transaction(fn ->
      locked = lock_stock_take(stock_take.id)
      if locked.status != "pending", do: Repo.rollback(:invalid_status)

      locked
      |> StockTake.changeset(%{
        status: "rejected",
        approved_by_id: approver_id,
        approved_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      |> Repo.update!()
    end)
  end

  defp lock_stock_take(id) do
    from(s in StockTake, where: s.id == ^id, lock: "FOR UPDATE")
    |> Repo.one!()
  end

  defp countable_entries(stock_take_id) do
    from(e in StockTakeEntry,
      where:
        e.stock_take_id == ^stock_take_id and e.has_been_applied == false and
          not is_nil(e.counted_quantity)
    )
    |> Repo.all()
  end

  # ── Apply Stock Take ───────────────────────────────────────────────────────

  @doc """
  Applies all entries in a stock take session:
  - Updates each referenced record's remaining_quantity to the counted_quantity
  - Creates an AuditLog entry for every change
  - Marks the stock take as "completed"
  Returns {:ok, stock_take} | {:error, reason}
  """
  def apply_stock_take(%StockTake{} = stock_take, admin_id) do
    entries = countable_entries(stock_take.id)

    Repo.transaction(fn ->
      Enum.each(entries, fn entry ->
        apply_entry(entry, admin_id)
      end)

      stock_take
      |> StockTake.changeset(%{status: "completed"})
      |> Repo.update!()
    end)
  end

  defp apply_entry(%StockTakeEntry{entity_type: "drug_batch"} = entry, admin_id) do
    drug_batch = Repo.get!(DrugBatch, entry.entity_id) |> Repo.preload(:batch)
    uom = effective_uom(entry.uom, drug_batch.batch && drug_batch.batch.uom)

    previous_state = %{
      "remaining_quantity" => drug_batch.remaining_quantity,
      "uom" => drug_batch.batch && drug_batch.batch.uom
    }

    new_state = %{
      "remaining_quantity" => entry.counted_quantity,
      "uom" => uom
    }

    drug_batch
    |> DrugBatch.changeset(%{remaining_quantity: entry.counted_quantity})
    |> Repo.update!()

    update_batch_uom(drug_batch.batch_id, uom)

    %AuditLog{}
    |> AuditLog.changeset(%{
      user_id: admin_id,
      action: "stock_take_adjustment",
      table_name: "drug_batches",
      record_id: drug_batch.id,
      previous_state: previous_state,
      new_state: new_state,
      changed_fields: changed_stock_take_fields(previous_state, new_state)
    })
    |> Repo.insert!()

    entry
    |> StockTakeEntry.changeset(%{has_been_applied: true})
    |> Repo.update!()
  end

  defp apply_entry(%StockTakeEntry{entity_type: "lab_allocation"} = entry, admin_id) do
    lab_allocation = Repo.get!(LabAllocation, entry.entity_id)
    uom = effective_uom(entry.uom, lab_allocation.uom)
    new_allocated_quantity = resolved_allocated_quantity(entry, lab_allocation.allocated_quantity)

    previous_state = %{
      "remaining_quantity" => lab_allocation.remaining_quantity,
      "allocated_quantity" => lab_allocation.allocated_quantity,
      "uom" => lab_allocation.uom
    }

    new_state = %{
      "remaining_quantity" => entry.counted_quantity,
      "allocated_quantity" => new_allocated_quantity,
      "uom" => uom
    }

    lab_allocation
    |> LabAllocation.changeset(%{
      remaining_quantity: entry.counted_quantity,
      allocated_quantity: new_allocated_quantity,
      uom: uom
    })
    |> Repo.update!()

    %AuditLog{}
    |> AuditLog.changeset(%{
      user_id: admin_id,
      action: "stock_take_adjustment",
      table_name: "lab_allocations",
      record_id: lab_allocation.id,
      previous_state: previous_state,
      new_state: new_state,
      changed_fields: changed_stock_take_fields(previous_state, new_state)
    })
    |> Repo.insert!()

    entry
    |> StockTakeEntry.changeset(%{has_been_applied: true})
    |> Repo.update!()
  end

  defp apply_entry(%StockTakeEntry{entity_type: "nursing_allocation"} = entry, admin_id) do
    nursing_allocation = Repo.get!(NursingAllocation, entry.entity_id)
    uom = effective_uom(entry.uom, nursing_allocation.uom)
    surplus = surplus_quantity(entry)

    previous_state = %{
      "remaining_quantity" => nursing_allocation.remaining_quantity,
      "allocated_quantity" => nursing_allocation.allocated_quantity,
      "uom" => nursing_allocation.uom
    }

    new_state = %{
      "remaining_quantity" => entry.counted_quantity,
      "allocated_quantity" => nursing_allocation.allocated_quantity + surplus,
      "uom" => uom
    }

    nursing_allocation
    |> NursingAllocation.changeset(%{
      remaining_quantity: entry.counted_quantity,
      allocated_quantity: nursing_allocation.allocated_quantity + surplus,
      uom: uom
    })
    |> Repo.update!()

    %AuditLog{}
    |> AuditLog.changeset(%{
      user_id: admin_id,
      action: "stock_take_adjustment",
      table_name: "nursing_allocations",
      record_id: nursing_allocation.id,
      previous_state: previous_state,
      new_state: new_state,
      changed_fields: changed_stock_take_fields(previous_state, new_state)
    })
    |> Repo.insert!()

    entry
    |> StockTakeEntry.changeset(%{has_been_applied: true})
    |> Repo.update!()
  end

  defp apply_entry(%StockTakeEntry{entity_type: "inventory_received"} = entry, admin_id) do
    batch = Repo.get!(Batch, entry.entity_id)
    uom = effective_uom(entry.uom, batch.uom)

    previous_state = %{"remaining_quantity" => batch.remaining_quantity, "uom" => batch.uom}
    new_state = %{"remaining_quantity" => entry.counted_quantity, "uom" => uom}

    batch
    |> Batch.changeset(%{remaining_quantity: entry.counted_quantity, uom: uom})
    |> Repo.update!()

    %AuditLog{}
    |> AuditLog.changeset(%{
      user_id: admin_id,
      action: "stock_take_adjustment",
      table_name: "batches",
      record_id: batch.id,
      previous_state: previous_state,
      new_state: new_state,
      changed_fields: changed_stock_take_fields(previous_state, new_state)
    })
    |> Repo.insert!()

    entry
    |> StockTakeEntry.changeset(%{has_been_applied: true})
    |> Repo.update!()
  end

  defp apply_entry(entry, _admin_id) do
    entry
    |> StockTakeEntry.changeset(%{has_been_applied: true})
    |> Repo.update!()
  end

  defp update_batch_uom(_batch_id, uom) when uom in [nil, ""], do: :ok
  defp update_batch_uom(nil, _uom), do: :ok

  defp update_batch_uom(batch_id, uom) do
    Batch
    |> Repo.get!(batch_id)
    |> Batch.changeset(%{uom: uom})
    |> Repo.update!()
  end

  defp changed_stock_take_fields(previous_state, new_state) do
    ["remaining_quantity", "allocated_quantity", "uom"]
    |> Enum.filter(&(Map.get(previous_state, &1) != Map.get(new_state, &1)))
    |> case do
      [] -> ["remaining_quantity"]
      fields -> fields
    end
  end

  @doc false
  # A stock take surplus (counted > previous remaining) means untracked stock
  # entered the system, so it grows allocated_quantity to keep the ledger
  # (allocated = consumed + remaining) consistent. Shortages are shrinkage/loss
  # and do not reduce allocated_quantity.
  defp surplus_quantity(%StockTakeEntry{difference: difference})
       when is_integer(difference) and difference > 0,
       do: difference

  defp surplus_quantity(_entry), do: 0

  # If the admin manually entered an allocated quantity on the entry, that
  # value wins over the automatic surplus bump.
  defp resolved_allocated_quantity(
         %StockTakeEntry{counted_allocated_quantity: quantity},
         _current
       )
       when is_integer(quantity),
       do: quantity

  defp resolved_allocated_quantity(entry, current), do: current + surplus_quantity(entry)

  defp effective_uom(nil, fallback), do: fallback
  defp effective_uom("", fallback), do: fallback
  defp effective_uom(uom, _fallback), do: uom

  # ── Helpers ────────────────────────────────────────────────────────────────

  def drug_batch_display_name(drug_batch) do
    brand = drug_batch.drug.inventory_received.brand_name
    strength = drug_batch.drug.inventory_received.strength
    batch_no = drug_batch.batch.batch

    [strength, brand, "(Batch: #{batch_no})"]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  def lab_allocation_display_name(la) do
    ir = la.inventory_issued && la.inventory_issued.inventory_received
    name = (ir && (ir.brand_name || ir.generic_name)) || la.uom || "Unknown Item"
    to_name = la.allocated_to_user && la.allocated_to_user.name
    "#{name}#{if to_name, do: " → #{to_name}", else: ""} (Lab)"
  end

  def nursing_allocation_display_name(na) do
    ir = na.inventory_issued && na.inventory_issued.inventory_received
    name = (ir && (ir.brand_name || ir.generic_name)) || na.uom || "Unknown Item"
    to_name = na.allocated_to_user && na.allocated_to_user.name
    "#{name}#{if to_name, do: " → #{to_name}", else: ""} (Nursing)"
  end

  def inventory_received_display_name(batch) do
    ir = batch.inventory_received
    name = (ir && (ir.brand_name || ir.generic_name)) || "Unknown Item"
    batch_no = batch.batch || batch.serial || "Batch ##{batch.id}"
    "#{name} — #{batch_no}"
  end

  @doc """
  Returns {brand_name, generic_name, batch_number} for a stock take entry by
  looking up the underlying entity. Returns {nil, nil, nil} if not found.
  """
  def lookup_entry_names(%StockTakeEntry{entity_type: "drug_batch", entity_id: id}) do
    case Repo.get(DrugBatch, id)
         |> then(&if(&1, do: Repo.preload(&1, [:batch, drug: :inventory_received]))) do
      nil ->
        {nil, nil, nil}

      db ->
        ir = db.drug && db.drug.inventory_received
        batch_no = db.batch && db.batch.batch
        {ir && ir.brand_name, ir && ir.generic_name, batch_no}
    end
  end

  def lookup_entry_names(%StockTakeEntry{entity_type: type, entity_id: id})
      when type in ["lab_allocation", "nursing_allocation"] do
    module = if type == "lab_allocation", do: LabAllocation, else: NursingAllocation

    case Repo.get(module, id)
         |> then(&if(&1, do: Repo.preload(&1, inventory_issued: [:inventory_received, :batch]))) do
      nil ->
        {nil, nil, nil}

      alloc ->
        ir = alloc.inventory_issued && alloc.inventory_issued.inventory_received
        batch = alloc.inventory_issued && alloc.inventory_issued.batch
        batch_no = batch && (batch.batch || batch.serial)
        {ir && ir.brand_name, ir && ir.generic_name, batch_no}
    end
  end

  def lookup_entry_names(%StockTakeEntry{entity_type: "inventory_received", entity_id: id}) do
    case Repo.get(Batch, id) |> then(&if(&1, do: Repo.preload(&1, :inventory_received))) do
      nil ->
        {nil, nil, nil}

      batch ->
        ir = batch.inventory_received
        batch_no = batch.batch || batch.serial
        {ir && ir.brand_name, ir && ir.generic_name, batch_no}
    end
  end

  def lookup_entry_names(_), do: {nil, nil, nil}

  def lookup_entry_uom(%StockTakeEntry{uom: uom}) when uom not in [nil, ""], do: uom

  def lookup_entry_uom(%StockTakeEntry{entity_type: "drug_batch", entity_id: id}) do
    case Repo.get(DrugBatch, id) |> then(&if(&1, do: Repo.preload(&1, :batch))) do
      nil -> nil
      db -> db.batch && db.batch.uom
    end
  end

  def lookup_entry_uom(%StockTakeEntry{entity_type: "lab_allocation", entity_id: id}) do
    case Repo.get(LabAllocation, id) do
      nil -> nil
      allocation -> allocation.uom
    end
  end

  def lookup_entry_uom(%StockTakeEntry{entity_type: "nursing_allocation", entity_id: id}) do
    case Repo.get(NursingAllocation, id) do
      nil -> nil
      allocation -> allocation.uom
    end
  end

  def lookup_entry_uom(%StockTakeEntry{entity_type: "inventory_received", entity_id: id}) do
    case Repo.get(Batch, id) do
      nil -> nil
      batch -> batch.uom
    end
  end

  def lookup_entry_uom(_), do: nil

  def entry_already_in_stock_take?(stock_take_id, entity_type, entity_id) do
    Repo.exists?(
      from e in StockTakeEntry,
        where:
          e.stock_take_id == ^stock_take_id and
            e.entity_type == ^entity_type and
            e.entity_id == ^entity_id
    )
  end

  def stock_take_summary(%StockTake{} = stock_take) do
    entries = Repo.all(from e in StockTakeEntry, where: e.stock_take_id == ^stock_take.id)

    with_counts = Enum.filter(entries, &(&1.counted_quantity != nil))
    discrepancies = Enum.filter(with_counts, &((&1.difference || 0) != 0))
    total_diff = discrepancies |> Enum.map(&(&1.difference || 0)) |> Enum.sum()

    %{
      total_entries: length(entries),
      counted: length(with_counts),
      discrepancies: length(discrepancies),
      total_difference: total_diff
    }
  end
end
