defmodule Medcamp.Repo.Migrations.CreateCamps do
  @moduledoc """
  Gives every organisation a list of camps, and stamps the activity tables
  with the camp the record happened at.

  A camp is an *event*: a weekend in Kajiado, a week in Turkana. The
  catalogues an organisation carries between events - its drug list, its lab
  test definitions, its staff and its patient register - stay organisation
  level and are deliberately not touched here. Only what happened at a camp
  gets a `camp_id`.

  The column is nullable on purpose. Work recorded before this migration, or
  while an organisation has no active camp, belongs to no camp rather than
  being forced into an invented one; those rows simply fall outside a
  camp-filtered view.
  """

  use Ecto.Migration

  # Tables whose rows record something that happened at a camp.
  @camp_tables ~w(
    patient_visits
    triages
    doctor_notes
    lab_results
    drug_allocations
    drugs_given
    drug_batches
    inventories_received
  )a

  def up do
    create table(:camps) do
      add :organisation_id, references(:organisations, on_delete: :restrict), null: false
      add :name, :string, null: false
      add :location, :string
      add :description, :text
      add :start_date, :date
      add :end_date, :date
      add :is_active, :boolean, null: false, default: false

      timestamps(type: :utc_datetime)
    end

    create index(:camps, [:organisation_id])
    create unique_index(:camps, [:organisation_id, :name])

    # At most one active camp per organisation, enforced by the database
    # rather than by whoever remembers to deactivate the previous one.
    create unique_index(:camps, [:organisation_id],
             where: "is_active",
             name: :camps_one_active_per_organisation
           )

    for table <- @camp_tables do
      alter table(table) do
        add :camp_id, references(:camps, on_delete: :nilify_all)
      end

      create index(table, [:camp_id])
    end
  end

  def down do
    for table <- @camp_tables do
      drop index(table, [:camp_id])

      alter table(table) do
        remove :camp_id
      end
    end

    drop table(:camps)
  end
end
