defmodule Medcamp.Repo.Migrations.CreateMpesas do
  use Ecto.Migration

  def change do
    create table(:mpesas) do
      add :account_number, :string
      add :amount, :integer
      add :description, :string

      add :phone, :string
      add :receipt, :string
      add :transactiondate, :string
      add :reason, :string
      add :patient_id, references(:patients, on_delete: :nothing)
      add :prompter_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:mpesas, [:patient_id])
    create index(:mpesas, [:prompter_id])
  end
end
