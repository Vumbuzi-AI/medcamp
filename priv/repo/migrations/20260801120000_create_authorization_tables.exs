defmodule Medcamp.Repo.Migrations.CreateAuthorizationTables do
  use Ecto.Migration

  def change do
    create table(:permissions) do
      add :slug, :string, null: false
      add :description, :string
      add :resource_area, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:permissions, [:slug])

    create table(:role_permissions) do
      add :role, :string, null: false
      add :permission_id, references(:permissions, on_delete: :delete_all), null: false
      add :granted_by_id, references(:users, on_delete: :nilify_all)
      add :granted_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:role_permissions, [:role, :permission_id])

    create table(:user_permissions) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :permission_id, references(:permissions, on_delete: :delete_all), null: false
      add :effect, :string, null: false
      add :granted_by_id, references(:users, on_delete: :nilify_all)
      add :granted_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_permissions, [:user_id, :permission_id])

    create table(:permission_reviews) do
      add :role, :string, null: false
      add :reviewer_id, references(:users, on_delete: :nilify_all)
      add :reviewed_at, :utc_datetime, null: false
      add :notes, :string

      timestamps(type: :utc_datetime)
    end

    create index(:permission_reviews, [:role])
  end
end
