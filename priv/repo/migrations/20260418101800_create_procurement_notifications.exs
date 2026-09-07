defmodule Medcamp.Repo.Migrations.CreateProcurementNotifications do
  use Ecto.Migration

  def change do
    create table(:procurement_notifications) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :type, :string, null: false
      add :title, :string
      add :body, :text
      add :resource_type, :string
      add :resource_id, :integer
      add :read, :boolean, default: false, null: false
      add :read_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:procurement_notifications, [:user_id, :read])
  end
end
