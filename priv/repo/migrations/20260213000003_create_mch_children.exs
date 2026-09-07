defmodule Medcamp.Repo.Migrations.CreateMchChildren do
  use Ecto.Migration

  def change do
    create table(:mch_children) do
      add :mother_id, references(:mch_mothers, on_delete: :delete_all), null: false
      add :name, :string
      add :sex, :string
      add :date_of_birth, :date
      add :gestation_at_birth_weeks, :integer
      add :birth_weight_grams, :integer
      add :birth_length_cm, :decimal
      add :head_circumference_cm, :decimal
      add :birth_order, :integer
      add :place_of_birth, :string
      add :immunization_register_number, :string
      add :cwc_number, :string
      add :health_facility_name, :string
      add :kmhfl_code, :string
      add :guardian_name, :string
      add :guardian_phone, :string

      timestamps(type: :utc_datetime)
    end

    create index(:mch_children, [:mother_id])
  end
end
