defmodule Medcamp.Repo.Migrations.CreateSops do
  use Ecto.Migration

  def change do
    create table(:sops) do
      add :name, :string, null: false
      add :description, :text, null: false
      add :valid_for_days, :integer, null: false
      add :pdf_path, :string, null: false
      add :original_filename, :string, null: false
      add :department_id, references(:departments, on_delete: :restrict), null: false
      add :added_by_id, references(:users, on_delete: :restrict), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:sops, [:department_id])
    create index(:sops, [:added_by_id])
    create index(:sops, [:inserted_at])
  end
end
