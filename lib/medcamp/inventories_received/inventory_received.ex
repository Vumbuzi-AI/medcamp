defmodule Medcamp.InventoriesReceived.InventoryReceived do
  use Ecto.Schema
  use Medcamp.Tenancy.Schema
  import Ecto.Changeset
  alias Medcamp.Repo
  import Ecto.Query

  @moduledoc """
  The pharmacy item master: one row per distinct product the camp stocks,
  keyed by GTIN and carrying its brand/generic name, strength, category and
  unit of measure.

  Despite the legacy `inventories_received` name this is a catalogue, not a
  goods-receipt document - the camp has no procurement chain. It is the
  identity a prescription and a dispense are recorded against
  (`inventory_received_id` flows through drug allocations and drugs given),
  which is why it survived the trim while the surrounding stores workflow
  did not.
  """

  schema "inventories_received" do
    tenant_field()

    field :type, :string
    field :description, :string
    field :image, :string
    field :brand_name, :string
    field :generic_name, :string
    field :gtin, :string
    field :supplier, :string
    field :weight, :integer
    field :uom, :string
    field :category, :string
    field :strength, :string
    belongs_to :user, Medcamp.Accounts.User
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(inventory_received, attrs) do
    inventory_received
    |> cast(attrs, [
      :brand_name,
      :description,
      :category,
      :gtin,
      :image,
      :weight,
      :uom,
      :strength,
      :generic_name,
      :supplier,
      :type,
      :user_id
    ])
    |> validate_required([:gtin, :brand_name])
    |> put_org_id()
  end

  def unique_gtin_checker(changeset) do
    changeset
    |> validate_gtin_uniqueness()
  end

  defp validate_gtin_uniqueness(changeset) do
    case get_change(changeset, :gtin) do
      nil ->
        changeset

      gtin ->
        if gtin_exists?(gtin) do
          add_error(changeset, :gtin, "GTIN already exists in inventory")
        else
          changeset
        end
    end
  end

  def gtin_exists?(gtin) do
    Repo.exists?(from i in __MODULE__, where: i.gtin == ^gtin)
  end
end
