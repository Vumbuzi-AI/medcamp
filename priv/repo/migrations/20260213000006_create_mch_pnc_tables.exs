defmodule Medcamp.Repo.Migrations.CreateMchPncTables do
  use Ecto.Migration

  def change do
    create table(:mch_pnc_mother_visits) do
      add :mother_id, references(:mch_mothers, on_delete: :delete_all), null: false
      add :delivery_id, references(:mch_deliveries, on_delete: :nilify_all)
      add :visit_number, :integer
      add :visit_date, :date
      add :bp_systolic, :integer
      add :bp_diastolic, :integer
      add :temperature, :decimal
      add :general_condition, :string
      add :breast_condition, :string
      add :uterus_involution, :string
      add :haemoglobin, :decimal
      add :fp_counseling_done, :boolean
      add :fp_method, :string

      timestamps(type: :utc_datetime)
    end

    create table(:mch_pnc_baby_visits) do
      add :child_id, references(:mch_children, on_delete: :delete_all), null: false
      add :pnc_mother_visit_id, references(:mch_pnc_mother_visits, on_delete: :nilify_all)
      add :general_condition, :string
      add :temperature, :decimal
      add :breaths_per_minute, :integer
      add :exclusive_breastfeeding, :boolean
      add :umbilical_cord_status, :string
      add :visit_date, :date

      timestamps(type: :utc_datetime)
    end

    create index(:mch_pnc_mother_visits, [:mother_id])
    create index(:mch_pnc_mother_visits, [:delivery_id])
    create index(:mch_pnc_baby_visits, [:child_id])
  end
end
