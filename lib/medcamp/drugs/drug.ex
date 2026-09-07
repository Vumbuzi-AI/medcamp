defmodule Medcamp.Drugs.Drug do
  use Ecto.Schema
  import Ecto.Changeset

  schema "drugs" do
    belongs_to :inventory_received, Medcamp.InventoriesReceived.InventoryReceived,
      foreign_key: :inventory_received_id

    belongs_to :inventory_manager, Medcamp.Accounts.User, foreign_key: :inventory_manager_id

    field :generic_name, :string
    field :brand_name, :string
    field :is_otc, :boolean, default: false
    field :is_dangerous_drug, :boolean, default: false
    has_many :drug_batches, Medcamp.DrugBatches.DrugBatch
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(drug, attrs) do
    drug
    |> cast(attrs, [
      :inventory_received_id,
      :inventory_manager_id,
      :generic_name,
      :brand_name,
      :is_otc,
      :is_dangerous_drug
    ])
    |> validate_required([
      :inventory_received_id,
      :inventory_manager_id
    ])
  end
end
