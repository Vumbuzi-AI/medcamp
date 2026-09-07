defmodule Medcamp.Repo.Migrations.CreateRfqs do
  use Ecto.Migration

  def change do
    create table(:rfqs) do
      add :reference, :string, null: false
      add :title, :string
      add :department, :string
      add :priority, :string, default: "normal"
      add :issue_date, :date
      add :quote_deadline, :date
      add :delivery_by, :date
      add :currency, :string, default: "KES"
      add :delivery_terms, :string
      add :payment_terms, :string
      add :special_instructions, :text
      add :status, :string, default: "draft", null: false
      add :created_by_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:rfqs, [:reference])
    create index(:rfqs, [:status])
    create index(:rfqs, [:created_by_id])
  end
end
