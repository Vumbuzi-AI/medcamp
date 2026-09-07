defmodule Medcamp.Repo.Migrations.CreateSuppliers do
  use Ecto.Migration

  def change do
    create table(:suppliers) do
      add :name, :string
      add :description, :text
      add :email, :string
      add :contact, :string
      add :location, :string
      add :inventory_manager_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:suppliers, [:inventory_manager_id])
  end
end
