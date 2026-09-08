defmodule Medcamp.StockAlertsTest do
  use Medcamp.DataCase, async: true

  import Medcamp.DrugBatchesFixtures

  alias Medcamp.StockAlerts

  describe "list_below_reorder_items/0" do
    test "keeps tenant scope in parallel association preloads" do
      drug_batch = drug_batch_fixture(%{remaining_quantity: 5})

      assert [%{id: drug_id, current_quantity: 5}] = StockAlerts.list_below_reorder_items()
      assert drug_id == drug_batch.drug_id
    end
  end
end
