defmodule Medcamp.SupplierStockNotifications do
  @moduledoc """
  Sends automated low-stock email notifications to suppliers.

  When batches from a supplier have remaining_quantity at or below the threshold
  (default 20), the supplier's email receives a single digest listing those batches.

  Run manually: `mix medcamp.notify_suppliers_low_stock`
  Or schedule via cron (e.g. daily): `0 8 * * * cd /path/to/app && mix medcamp.notify_suppliers_low_stock`
  """

  alias Medcamp.Suppliers
  alias Medcamp.Postal

  @doc """
  Checks all suppliers for low-stock batches and sends one email per supplier
  that has at least one batch with 0 < remaining_quantity <= threshold.

  Options:
  - :threshold - integer (default 20). Batches with remaining_quantity in (0, threshold] are considered low.

  Returns {:ok, %{sent: count, errors: [term]}}.
  """
  def notify_all_suppliers(opts \\ []) do
    threshold = Keyword.get(opts, :threshold, 20)
    suppliers_with_low = Suppliers.list_suppliers_with_low_stock(threshold)

    {sent, errors} =
      Enum.reduce(suppliers_with_low, {0, []}, fn %{
                                                    supplier: supplier,
                                                    low_stock_batches: batches
                                                  },
                                                  {s, errs} ->
        case Postal.send_supplier_low_stock_email(
               supplier.email,
               supplier.name,
               batches,
               threshold
             ) do
          {:ok, _, _response} ->
            {s + 1, errs}

          {:error, reason} ->
            {s, [{supplier.id, supplier.email, reason} | errs]}
        end
      end)

    {:ok, %{sent: sent, errors: Enum.reverse(errors)}}
  end
end
