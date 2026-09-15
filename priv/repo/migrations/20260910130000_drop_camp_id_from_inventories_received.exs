defmodule Medcamp.Repo.Migrations.DropCampIdFromInventoriesReceived do
  @moduledoc """
  `inventories_received` is the pharmacy item master - a catalogue the
  organisation carries between camps, not a record of something that happened
  at one. It was wrongly given a `camp_id` alongside the true camp-scoped
  stock table `drug_batches`; this removes it. Uniqueness stays
  `(organisation_id, gtin)`.
  """

  use Ecto.Migration

  def up do
    drop index(:inventories_received, [:camp_id])

    alter table(:inventories_received) do
      remove :camp_id
    end
  end

  def down do
    alter table(:inventories_received) do
      add :camp_id, references(:camps, on_delete: :nilify_all)
    end

    create index(:inventories_received, [:camp_id])
  end
end
