defmodule Medcamp.Repo.Migrations.CreateStaffMealSupplies do
  use Ecto.Migration

  def change do
    create table(:staff_meal_supplies) do
      add :supplied_on, :date, null: false
      add :meal_type, :string, null: false
      add :plates, :integer, null: false, default: 0
      add :price_per_plate, :integer, null: false, default: 100
      add :notes, :string
      add :user_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:staff_meal_supplies, [:supplied_on])
    create index(:staff_meal_supplies, [:meal_type])
    create index(:staff_meal_supplies, [:user_id])
  end
end
