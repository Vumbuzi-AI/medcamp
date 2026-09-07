defmodule Medcamp.Repo.Migrations.GrantInventoryPanelsToReception do
  @moduledoc """
  Reception (and admin) work the inventory manager's pages and are shown
  its sidebar there, but held none of its `inventory_manager.*` panels:
  every tab in that sidebar rendered hidden and every URL under
  `/inventory_manager/` was refused with "You do not have permission to
  access that page."

  `SidebarCatalog.shared_tabs/1` now declares those sidebars as shared,
  and `PanelSync.sync/1` grants them, so this is another re-run of it.
  Per-user overrides are untouched.
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
