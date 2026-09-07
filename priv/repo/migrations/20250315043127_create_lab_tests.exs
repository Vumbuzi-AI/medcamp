defmodule Medcamp.Repo.Migrations.CreateLabTests do
  use Ecto.Migration

  def change do
    create table(:lab_tests) do
      add :name, :string
      add :desription, :text
      add :price, :integer
      add :creator_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end
  end
end
