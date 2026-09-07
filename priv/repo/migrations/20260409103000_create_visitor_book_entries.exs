defmodule Medcamp.Repo.Migrations.CreateVisitorBookEntries do
  use Ecto.Migration

  def change do
    create table(:visitor_book_entries) do
      add :visitor_name, :string, null: false
      add :phone_number, :string
      add :person_to_see, :string
      add :purpose, :string
      add :message, :text, null: false
      add :visited_on, :date, null: false
      add :visited_at, :time, null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:visitor_book_entries, [:visited_on])
    create index(:visitor_book_entries, [:user_id])
    create index(:visitor_book_entries, [:visited_on, :visited_at])
  end
end
