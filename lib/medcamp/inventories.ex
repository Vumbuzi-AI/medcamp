defmodule Medcamp.Inventories do
  @moduledoc """
  The Inventories context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.Inventories.GeneralInventoryItem
  alias Medcamp.Inventories.GeneralInventoryTransaction

  @doc """
  Returns the list of general_inventory_items.

  ## Examples

      iex> list_general_inventory_items()
      [%GeneralInventoryItem{}, ...]

  """

  def create_general_inventory_transaction(attrs \\ %{}) do
    %GeneralInventoryTransaction{}
    |> GeneralInventoryTransaction.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, transaction} ->
        # Update the inventory item's current_quantity based on transaction type
        update_inventory_quantity_from_transaction(transaction)
        {:ok, Repo.preload(transaction, [:general_inventory_item, :user])}

      error ->
        error
    end
  end

  defp update_inventory_quantity_from_transaction(transaction) do
    item = get_general_inventory_item!(transaction.general_inventory_item_id)

    new_quantity =
      case transaction.transaction_type do
        "received" -> Decimal.add(item.current_quantity, transaction.quantity)
        "adjustment" -> Decimal.add(item.current_quantity, transaction.quantity)
        "used" -> Decimal.sub(item.current_quantity, transaction.quantity)
        "destroyed" -> Decimal.sub(item.current_quantity, transaction.quantity)
      end

    new_quantity =
      if Decimal.compare(new_quantity, Decimal.new(0)) == :lt,
        do: Decimal.new(0),
        else: new_quantity

    item
    |> Ecto.Changeset.change(current_quantity: new_quantity)
    |> Repo.update()
  end

  # Also add this for transaction deletion
  def delete_general_inventory_transaction(%GeneralInventoryTransaction{} = transaction) do
    transaction = Repo.preload(transaction, :general_inventory_item)

    Repo.delete(transaction)
    |> case do
      {:ok, deleted_transaction} ->
        # Reverse the transaction effect on stock
        reverse_inventory_quantity_from_transaction(deleted_transaction)
        {:ok, deleted_transaction}

      error ->
        error
    end
  end

  defp reverse_inventory_quantity_from_transaction(transaction) do
    item = get_general_inventory_item!(transaction.general_inventory_item_id)

    new_quantity =
      case transaction.transaction_type do
        "received" -> Decimal.sub(item.current_quantity, transaction.quantity)
        "adjustment" -> Decimal.sub(item.current_quantity, transaction.quantity)
        "used" -> Decimal.add(item.current_quantity, transaction.quantity)
        "destroyed" -> Decimal.add(item.current_quantity, transaction.quantity)
      end

    new_quantity =
      if Decimal.compare(new_quantity, Decimal.new(0)) == :lt,
        do: Decimal.new(0),
        else: new_quantity

    item
    |> Ecto.Changeset.change(current_quantity: new_quantity)
    |> Repo.update()
  end

  def list_general_inventory_items do
    general_inventory_items_query(nil)
    |> Repo.all()
  end

  def list_general_inventory_items_paginated(search \\ nil, page \\ 1, per_page \\ 20) do
    general_inventory_items_query(search)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
  end

  def count_general_inventory_items(search \\ nil) do
    general_inventory_items_query(search)
    |> exclude(:order_by)
    |> select([i], count(i.id))
    |> Repo.one()
  end

  # Get transactions for a specific item
  def list_transactions_for_item(item_id) do
    from(t in GeneralInventoryTransaction,
      where: t.general_inventory_item_id == ^item_id,
      order_by: [desc: t.transaction_date, desc: t.inserted_at],
      preload: [:user]
    )
    |> Repo.all()
  end

  def list_transactions_for_item_paginated(item_id, page \\ 1, per_page \\ 10) do
    from(t in GeneralInventoryTransaction,
      where: t.general_inventory_item_id == ^item_id,
      order_by: [desc: t.transaction_date, desc: t.inserted_at],
      preload: [:user]
    )
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
  end

  def count_transactions_for_item(item_id) do
    from(t in GeneralInventoryTransaction, where: t.general_inventory_item_id == ^item_id)
    |> Repo.aggregate(:count, :id)
  end

  def get_general_inventory_transaction!(id) do
    Repo.get!(GeneralInventoryTransaction, id)
    |> Repo.preload([:general_inventory_item, :user])
  end

  # In lib/medcamp/inventories.ex
  @spec search_general_inventory_items(any()) :: any()
  def search_general_inventory_items(query) do
    general_inventory_items_query(query)
    |> Repo.all()
  end

  def search_general_inventory_items_paginated(query, page \\ 1, per_page \\ 20) do
    general_inventory_items_query(query)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
  end

  @doc """
  Gets a single general_inventory_item.

  Raises `Ecto.NoResultsError` if the General inventory item does not exist.

  ## Examples

      iex> get_general_inventory_item!(123)
      %GeneralInventoryItem{}

      iex> get_general_inventory_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_general_inventory_item!(id), do: Repo.get!(GeneralInventoryItem, id)

  @doc """
  Creates a general_inventory_item.

  ## Examples

      iex> create_general_inventory_item(%{field: value})
      {:ok, %GeneralInventoryItem{}}

      iex> create_general_inventory_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_general_inventory_item(attrs \\ %{}) do
    %GeneralInventoryItem{}
    |> GeneralInventoryItem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a general_inventory_item.

  ## Examples

      iex> update_general_inventory_item(general_inventory_item, %{field: new_value})
      {:ok, %GeneralInventoryItem{}}

      iex> update_general_inventory_item(general_inventory_item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_general_inventory_item(%GeneralInventoryItem{} = general_inventory_item, attrs) do
    general_inventory_item
    |> GeneralInventoryItem.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a general_inventory_item.

  ## Examples

      iex> delete_general_inventory_item(general_inventory_item)
      {:ok, %GeneralInventoryItem{}}

      iex> delete_general_inventory_item(general_inventory_item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_general_inventory_item(%GeneralInventoryItem{} = general_inventory_item) do
    Repo.delete(general_inventory_item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking general_inventory_item changes.

  ## Examples

      iex> change_general_inventory_item(general_inventory_item)
      %Ecto.Changeset{data: %GeneralInventoryItem{}}

  """
  def change_general_inventory_item(
        %GeneralInventoryItem{} = general_inventory_item,
        attrs \\ %{}
      ) do
    GeneralInventoryItem.changeset(general_inventory_item, attrs)
  end

  defp general_inventory_items_query(nil) do
    from(i in GeneralInventoryItem, order_by: [desc: i.inserted_at])
  end

  defp general_inventory_items_query(""), do: general_inventory_items_query(nil)

  defp general_inventory_items_query(query) do
    search_term = "%#{query}%"

    from(i in GeneralInventoryItem,
      where:
        ilike(i.name, ^search_term) or
          ilike(i.category, ^search_term) or
          ilike(i.supplier, ^search_term),
      order_by: [desc: i.inserted_at]
    )
  end

  @doc """
  Returns the list of general_inventory_transactions.

  ## Examples

      iex> list_general_inventory_transactions()
      [%GeneralInventoryTransaction{}, ...]

  """
  def list_general_inventory_transactions do
    Repo.all(GeneralInventoryTransaction)
    |> Repo.preload([:general_inventory_item, :user])
  end

  @doc """
  Updates a general_inventory_transaction.

  ## Examples

      iex> update_general_inventory_transaction(general_inventory_transaction, %{field: new_value})
      {:ok, %GeneralInventoryTransaction{}}

      iex> update_general_inventory_transaction(general_inventory_transaction, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_general_inventory_transaction(
        %GeneralInventoryTransaction{} = general_inventory_transaction,
        attrs
      ) do
    general_inventory_transaction
    |> GeneralInventoryTransaction.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking general_inventory_transaction changes.

  ## Examples

      iex> change_general_inventory_transaction(general_inventory_transaction)
      %Ecto.Changeset{data: %GeneralInventoryTransaction{}}

  """
  def change_general_inventory_transaction(
        %GeneralInventoryTransaction{} = general_inventory_transaction,
        attrs \\ %{}
      ) do
    GeneralInventoryTransaction.changeset(general_inventory_transaction, attrs)
  end

  @doc """
  Recalculates current_quantity for every GeneralInventoryItem by replaying
  all of its transactions from scratch (net of received/adjustment vs used/destroyed).

  Returns a list of result tuples:
    {:ok, name, old_qty, new_qty}  — item was updated
    {:skipped, name, qty}          — transactions are empty; item left unchanged
    {:error, name, reason}         — update failed

  Run from iex with:
    Medcamp.Inventories.recalculate_stock_from_transactions()
  """
  def recalculate_stock_from_transactions do
    items = list_general_inventory_items()

    Enum.map(items, fn item ->
      transactions = list_transactions_for_item(item.id)

      if Enum.empty?(transactions) do
        {:skipped, item.name, item.current_quantity}
      else
        calculated =
          Enum.reduce(transactions, Decimal.new(0), fn t, acc ->
            case t.transaction_type do
              type when type in ["received", "adjustment"] ->
                Decimal.add(acc, t.quantity)

              type when type in ["used", "destroyed"] ->
                Decimal.sub(acc, t.quantity)

              _ ->
                acc
            end
          end)

        corrected =
          if Decimal.compare(calculated, Decimal.new(0)) == :lt,
            do: Decimal.new(0),
            else: calculated

        case item |> Ecto.Changeset.change(current_quantity: corrected) |> Repo.update() do
          {:ok, _} -> {:ok, item.name, item.current_quantity, corrected}
          {:error, changeset} -> {:error, item.name, changeset.errors}
        end
      end
    end)
  end
end
