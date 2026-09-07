defmodule Medcamp.Repo.Migrations.CreateMchDeliveries do
  use Ecto.Migration

  def change do
    create table(:mch_deliveries) do
      add :pregnancy_id, references(:mch_pregnancies, on_delete: :delete_all), null: false
      add :child_id, references(:mch_children, on_delete: :nilify_all)
      add :delivery_date, :date
      add :delivery_time, :time
      add :duration_of_pregnancy_weeks, :integer
      add :mode_of_delivery, :string
      add :birth_weight_grams, :integer
      add :birth_length_cm, :decimal
      add :head_circumference_cm, :decimal
      add :place_of_childbirth, :string
      add :conducted_by, :string

      timestamps(type: :utc_datetime)
    end

    create index(:mch_deliveries, [:pregnancy_id])
    create index(:mch_deliveries, [:child_id])
  end
end
