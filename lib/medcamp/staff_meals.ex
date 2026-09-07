defmodule Medcamp.StaffMeals do
  @moduledoc """
  The StaffMeals context.

  Tracks staff meals supplied by the food vendor (lunch and supper plates per
  date) so reception can sign off deliveries against the supplier and work out
  how much the supplier is owed.
  """

  import Ecto.Query, warn: false

  alias Medcamp.Repo
  alias Medcamp.StaffMeals.StaffMealSupply

  def list_staff_meal_supplies(opts \\ []) do
    StaffMealSupply
    |> join(:left, [supply], user in assoc(supply, :user))
    |> preload([_supply, user], user: user)
    |> order_by([supply], desc: supply.supplied_on, desc: supply.inserted_at)
    |> apply_filters(opts)
    |> Repo.all()
  end

  def get_staff_meal_supply!(id) do
    StaffMealSupply
    |> Repo.get!(id)
    |> Repo.preload(:user)
  end

  def create_staff_meal_supply(attrs \\ %{}) do
    %StaffMealSupply{}
    |> StaffMealSupply.changeset(attrs)
    |> Repo.insert()
  end

  def update_staff_meal_supply(%StaffMealSupply{} = supply, attrs) do
    supply
    |> StaffMealSupply.changeset(attrs)
    |> Repo.update()
  end

  def delete_staff_meal_supply(%StaffMealSupply{} = supply) do
    Repo.delete(supply)
  end

  def change_staff_meal_supply(%StaffMealSupply{} = supply, attrs \\ %{}) do
    StaffMealSupply.changeset(supply, attrs)
  end

  @doc """
  Summary totals across a list of supplies: number of deliveries, total lunch,
  supper and combined plates, and the total amount payable to the supplier.
  """
  def summarize(supplies) when is_list(supplies) do
    Enum.reduce(
      supplies,
      %{deliveries: 0, lunch_plates: 0, supper_plates: 0, total_plates: 0, amount_payable: 0},
      fn supply, acc ->
        plates = supply.plates || 0

        %{
          deliveries: acc.deliveries + 1,
          lunch_plates: acc.lunch_plates + meal_plates(supply, "lunch"),
          supper_plates: acc.supper_plates + meal_plates(supply, "supper"),
          total_plates: acc.total_plates + plates,
          amount_payable: acc.amount_payable + StaffMealSupply.amount_payable(supply)
        }
      end
    )
  end

  defp meal_plates(%{meal_type: type, plates: plates}, type), do: plates || 0
  defp meal_plates(_supply, _type), do: 0

  defp apply_filters(query, []), do: query

  defp apply_filters(query, [{:date_from, value} | rest]) do
    case parse_date(value) do
      nil -> apply_filters(query, rest)
      date -> query |> where([supply], supply.supplied_on >= ^date) |> apply_filters(rest)
    end
  end

  defp apply_filters(query, [{:date_to, value} | rest]) do
    case parse_date(value) do
      nil -> apply_filters(query, rest)
      date -> query |> where([supply], supply.supplied_on <= ^date) |> apply_filters(rest)
    end
  end

  defp apply_filters(query, [{:meal_type, value} | rest]) when value in ["lunch", "supper"] do
    query |> where([supply], supply.meal_type == ^value) |> apply_filters(rest)
  end

  defp apply_filters(query, [{:search, term} | rest]) when is_binary(term) do
    trimmed = String.trim(term)

    if trimmed == "" do
      apply_filters(query, rest)
    else
      pattern = "%#{trimmed}%"

      query
      |> where(
        [supply, user],
        ilike(supply.notes, ^pattern) or ilike(user.name, ^pattern)
      )
      |> apply_filters(rest)
    end
  end

  defp apply_filters(query, [_ | rest]), do: apply_filters(query, rest)

  defp parse_date(nil), do: nil
  defp parse_date(""), do: nil
  defp parse_date(%Date{} = date), do: date

  defp parse_date(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp parse_date(_), do: nil
end
