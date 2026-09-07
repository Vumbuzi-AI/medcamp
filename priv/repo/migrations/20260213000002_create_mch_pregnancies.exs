defmodule Medcamp.Repo.Migrations.CreateMchPregnancies do
  use Ecto.Migration

  def change do
    create table(:mch_pregnancies) do
      add :mother_id, references(:mch_mothers, on_delete: :delete_all), null: false
      add :status, :string, default: "active"
      add :lmp, :date
      add :edd, :date
      add :anc_number, :string

      timestamps(type: :utc_datetime)
    end

    create index(:mch_pregnancies, [:mother_id])
  end
end
