defmodule Medcamp.SeedInventory do
  alias Medcamp.Batches

  def get_contacts_list_from_csv(file_path) do
    project_root = File.cwd!()

    clean_path = String.trim_leading(file_path, "/")
    full_path = Path.join([project_root, "priv", "static", clean_path])

    full_path
    |> File.stream!()
    |> CSV.decode!(headers: true)
    |> Enum.to_list()
  end

  def insert(file_path) do
    file_path
    |> get_contacts_list_from_csv()
    |> Enum.each(fn row ->
      Medcamp.InventoriesReceived.create_inventory_received(%{
        type: row["Category name"],
        description: row["Product Description"],
        brand_name: row["Brand Name"],
        generic_name: row["Brand Name"],
        gtin: row["Barcode Number"],
        supplier: row["Supplier"],
        user_id: 1
      })
    end)
  end

  def insert_list_one(file_path) do
    file_path
    |> get_contacts_list_from_csv()
    |> Enum.each(fn row ->
      case Medcamp.InventoriesReceived.create_inventory_received(%{
             type: row["Category name"],
             description: row["Product Description"],
             brand_name: row["Brand Name"],
             generic_name: row["Brand Name"],
             gtin: row["Barcode Number"],
             supplier: row["Supplier"],
             expiry: row["Expiry Date"],
             manufacture_date: row["Manufacturing Date"],
             user_id: 1
           }) do
        {:ok, inventory_received} ->
          Batches.create_batch(%{
            gtin: row["Barcode Number"],
            batch: row["Batch Number"],
            expiry: row["Expiry Date"],
            quantity: row["Quantity in Stock"],
            remaining_quantity: row["Quantity in Stock"],
            inventory_received_id: inventory_received.id,
            inventory_manager_id: 1
          })

        {:error, changeset} ->
          IO.inspect(changeset.errors, label: "Error inserting inventory received")
      end
    end)
  end
end
