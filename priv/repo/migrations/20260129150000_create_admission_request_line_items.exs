defmodule Medcamp.Repo.Migrations.CreateAdmissionRequestLineItems do
  use Ecto.Migration

  def change do
    create table(:admission_request_line_items) do
      add :admission_request_id, references(:admission_requests, on_delete: :delete_all),
        null: false

      add :item_type, :string, null: false
      add :price, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:admission_request_line_items, [:admission_request_id])
  end
end
