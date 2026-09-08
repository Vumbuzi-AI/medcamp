defmodule Medcamp.Repo.Migrations.AddApprovalToOrganisations do
  @moduledoc """
  Distinguishes a self-serve signup that has never been approved from an
  organisation that was approved and later suspended.

  Both are `is_active: false`, but only the first should be told it is waiting
  on us. Every organisation that already exists predates self-serve signup, so
  it is backfilled as approved.
  """

  use Ecto.Migration

  def up do
    alter table(:organisations) do
      add :approved_at, :utc_datetime
      add :contact_name, :string
    end

    flush()

    execute "UPDATE organisations SET approved_at = inserted_at WHERE is_active = true"
  end

  def down do
    alter table(:organisations) do
      remove :approved_at
      remove :contact_name
    end
  end
end
