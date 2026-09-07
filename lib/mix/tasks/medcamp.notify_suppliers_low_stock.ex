defmodule Mix.Tasks.Medcamp.NotifySuppliersLowStock do
  @shortdoc "Sends low-stock alert emails to suppliers whose batches are at or below the threshold"
  @moduledoc """
  Checks all batches linked to suppliers. For each supplier that has at least one
  batch with remaining_quantity in (0, threshold], sends one email to the
  supplier's email address listing those low-stock batches.

  Usage:
    mix medcamp.notify_suppliers_low_stock              # threshold 20 (default)
    mix medcamp.notify_suppliers_low_stock --threshold 30

  Schedule with cron (e.g. daily at 8:00):
    0 8 * * * cd /path/to/medcamp && mix medcamp.notify_suppliers_low_stock
  """

  use Mix.Task

  @requirements ["app.config"]

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [threshold: :integer])
    threshold = Keyword.get(opts, :threshold, 20)

    Mix.Task.run("app.start")

    case Medcamp.SupplierStockNotifications.notify_all_suppliers(threshold: threshold) do
      {:ok, %{sent: sent, errors: errs}} ->
        Mix.shell().info("Supplier low-stock notifications: #{sent} email(s) sent.")

        for {_id, email, reason} <- errs do
          Mix.shell().error("  Failed to send to #{email}: #{inspect(reason)}")
        end
    end
  end
end
