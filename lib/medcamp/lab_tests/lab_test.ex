defmodule Medcamp.LabTests.LabTest do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lab_tests" do
    field :name, :string
    field :desription, :string
    field :price, :integer
    field :subsidized_price, :integer
    belongs_to :creator, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(lab_test, attrs) do
    lab_test
    |> cast(attrs, [:name, :desription, :price, :subsidized_price, :creator_id])
    |> validate_required([:name, :price])
    |> put_subsidized_price_if_missing()
  end

  defp put_subsidized_price_if_missing(changeset) do
    case get_field(changeset, :subsidized_price) do
      nil ->
        price = get_field(changeset, :price) || get_change(changeset, :price)

        if price && is_integer(price),
          do: put_change(changeset, :subsidized_price, round(price * 0.7)),
          else: changeset

      _ ->
        changeset
    end
  end

  @doc """
  Returns the price to use for the given payment type.
  `payment_type` is "full" or "subsidized".
  """
  def price_for_payment_type(lab_test, "subsidized") do
    lab_test.subsidized_price || (lab_test.price && round(lab_test.price * 0.7)) || 0
  end

  def price_for_payment_type(lab_test, _), do: lab_test.price || 0
end
