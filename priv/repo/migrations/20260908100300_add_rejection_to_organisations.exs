defmodule Medcamp.Repo.Migrations.AddRejectionToOrganisations do
  @moduledoc """
  Lets a superadmin reject a self-serve signup with a reason, instead of only
  being able to approve it. A rejected organisation is inactive, never
  approved, and carries the reason so it can be shown/emailed.

  Both columns are nullable and default-free, so this is forward-only-safe
  against live data.
  """

  use Ecto.Migration

  def up do
    alter table(:organisations) do
      add :rejected_at, :utc_datetime
      add :rejection_reason, :text
    end
  end

  def down do
    alter table(:organisations) do
      remove :rejected_at
      remove :rejection_reason
    end
  end
end
