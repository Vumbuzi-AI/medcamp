defmodule Medcamp.Repo.Migrations.CreateDangerousDrugRegisters do
  use Ecto.Migration

  def change do
    create table(:dangerous_drug_registers) do
      add :drug_id, references(:drugs, on_delete: :delete_all), null: false
      add :month, :integer, null: false
      add :year, :integer, null: false
      add :entries, :map, default: %{}, null: false
      add :last_entry_number, :integer, default: 0, null: false
      add :created_by_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:dangerous_drug_registers, [:drug_id])
    create index(:dangerous_drug_registers, [:created_by_id])

    create unique_index(:dangerous_drug_registers, [:drug_id, :month, :year],
             name: :unique_dangerous_drug_register_per_month
           )
  end
end
