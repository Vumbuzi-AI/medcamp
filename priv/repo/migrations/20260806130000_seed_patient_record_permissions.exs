defmodule Medcamp.Repo.Migrations.SeedPatientRecordPermissions do
  @moduledoc """
  Adds the per-patient sidebar sections (the tabs shown once a user opens
  a specific patient - overview, notes, triages, lab results, ...) as
  panels in their own right, granted to each role by default so nobody
  loses access they already had.

  Just a re-run of `Medcamp.Authorization.PanelSync.sync/1` against the
  now-larger catalog; it inserts what is missing and leaves existing
  rows and per-user overrides alone.
  """

  use Ecto.Migration

  alias Medcamp.Authorization.PanelSync

  def up do
    PanelSync.sync(repo())
  end

  def down do
    # Nothing to undo: the panels this adds are removed by the
    # SeedPanelPermissions rollback, which deletes every catalog slug.
    :ok
  end
end
