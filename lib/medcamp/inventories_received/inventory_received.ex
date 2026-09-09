defmodule Medcamp.InventoriesReceived.InventoryReceived do
  use Ecto.Schema
  use Medcamp.Tenancy.Schema
  use Medcamp.Camps.Schema
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

  @units_of_measure ~w(Tablet Capsule Sachet mL Vial Ampoule Bottle Tube
                       Drop Suppository Pessary Patch Puff Unit)

  @doc "Canonical dispensing units for the `uom` field."
  def units_of_measure, do: @units_of_measure

  schema "inventories_received" do
    tenant_field()
    camp_field()

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

  @doc """
  `opts[:strict]` adds the checks the pharmacist's "New Drug" form needs -
  a real GS1 barcode number and a `uom` from the canonical list. The plain
  form stays lenient so fixtures and internally minted codes keep working.
  """
  def changeset(inventory_received, attrs, opts \\ []) do
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
    |> validate_required([:gtin])
    |> validate_name_present()
    |> maybe_strict(opts[:strict])
    |> put_org_id()
    |> put_camp_id()
  end

  defp maybe_strict(changeset, true) do
    changeset
    |> validate_gtin_digits()
    |> validate_inclusion(:uom, @units_of_measure, message: "pick one of the listed units")
  end

  defp maybe_strict(changeset, _), do: changeset

  # A GTIN is 8/12/13/14 numeric digits with a valid GS1 check digit
  # (`Medcamp.Gtin`). Only checked when the caller supplies one - existing
  # rows and internally minted codes are left alone.
  defp validate_gtin_digits(changeset) do
    case get_change(changeset, :gtin) do
      nil ->
        changeset

      gtin ->
        case Medcamp.Gtin.validate(String.trim(to_string(gtin))) do
          {:ok, _} -> changeset
          {:error, _} -> add_error(changeset, :gtin, "is not a valid barcode number")
        end
    end
  end

  # Brand is optional (plain generics have none), but a catalogue row needs
  # at least one name to be recognisable.
  defp validate_name_present(changeset) do
    brand = get_field(changeset, :brand_name)
    generic = get_field(changeset, :generic_name)

    if blank?(brand) and blank?(generic),
      do: add_error(changeset, :generic_name, "add a generic or brand name"),
      else: changeset
  end

  defp blank?(nil), do: true
  defp blank?(value) when is_binary(value), do: String.trim(value) == ""
  defp blank?(_), do: false

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
