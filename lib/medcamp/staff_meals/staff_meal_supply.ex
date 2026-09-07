defmodule Medcamp.StaffMeals.StaffMealSupply do
  use Ecto.Schema
  import Ecto.Changeset

  @meal_types ~w(lunch supper)

  schema "staff_meal_supplies" do
    field :supplied_on, :date
    field :meal_type, :string
    field :plates, :integer, default: 0
    field :price_per_plate, :integer, default: 100
    field :notes, :string

    belongs_to :user, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @required_fields [:supplied_on, :meal_type, :plates, :price_per_plate]
  @optional_fields [:notes, :user_id]

  def changeset(staff_meal_supply, attrs) do
    staff_meal_supply
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:meal_type, @meal_types)
    |> validate_number(:plates, greater_than: 0)
    |> validate_number(:price_per_plate, greater_than_or_equal_to: 0)
    |> validate_length(:notes, max: 2_000)
    |> foreign_key_constraint(:user_id)
  end

  @doc "Allowed meal types as `{label, value}` tuples for select inputs."
  def meal_type_options, do: [{"Lunch", "lunch"}, {"Supper", "supper"}]

  @doc "Human label for a meal type value."
  def meal_type_label("lunch"), do: "Lunch"
  def meal_type_label("supper"), do: "Supper"
  def meal_type_label(other), do: other

  @doc "Amount payable to the supplier for a record (plates x price per plate)."
  def amount_payable(%__MODULE__{plates: plates, price_per_plate: price}) do
    (plates || 0) * (price || 0)
  end

  @doc "Defaults for a new entry, prefilled with today's date and lunch."
  def current_supply_defaults do
    %{"supplied_on" => Date.utc_today() |> Date.to_string(), "meal_type" => "lunch"}
  end
end
