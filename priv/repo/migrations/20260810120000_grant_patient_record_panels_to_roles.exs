defmodule Medcamp.Repo.Migrations.GrantPatientRecordPanelsToRoles do
  @moduledoc """
  `SeedPatientRecordPermissions` created the `<role>.patient.*` permission
  rows but `PanelSync` only granted roles their *main* sidebar panels, so
  no role held any patient-record section: every doctor, nurse, lab tech,
  receptionist, pharmacist and radiologist lost the tabs shown inside an
  open patient.

  `PanelSync.sync/1` now derives role defaults from both sidebars, so this
  is just another re-run of it. Per-user overrides are untouched, so an
  admin who deliberately revoked a section keeps that decision.
  """

  use Ecto.Migration

  alias Medcamp.Authorization.PanelSync

  def up do
    PanelSync.sync(repo())
  end

  def down do
    # Nothing to undo: these are role defaults for panels the earlier
    # panel-permission migrations own and remove on their own rollback.
    :ok
  end
end
