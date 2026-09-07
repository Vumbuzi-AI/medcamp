defmodule Medcamp.Repo.Migrations.CreateSupplierDirectors do
  use Ecto.Migration

  def change do
    create table(:supplier_directors) do
      add :supplier_id, references(:suppliers, on_delete: :delete_all), null: false
      add :first_name, :string
      add :last_name, :string
      add :middle_name, :string
      add :id_number, :string
      add :telephone, :string
      add :email, :string
      add :id_document_path, :string

      timestamps(type: :utc_datetime)
    end

    create index(:supplier_directors, [:supplier_id])
  end
end
