defmodule Medcamp.Repo.Migrations.SeedPanelPermissions do
  @moduledoc """
  Creates one permission per sidebar panel and grants each camp role its own
  panels.

  `Medcamp.Authorization.can?/2` fails closed, so without this every page is
  refused for everyone - including the admin who would otherwise grant them.
  The set is derived from `MedcampWeb.SidebarCatalog`, which is also what
  renders the sidebar and guards the routes, so the three cannot drift apart.

  `PanelSync.sync/1` is idempotent: re-running it after adding a panel to the
  catalog picks up the new one and leaves existing overrides alone.
  """

  use Ecto.Migration

  import Ecto.Query

  alias Medcamp.Authorization.PanelSync

  def up do
    PanelSync.sync(repo())
  end

  def down do
    slugs = Enum.map(MedcampWeb.SidebarCatalog.all_permissions(), & &1.slug)

    permission_ids =
      from(p in "permissions", where: p.slug in ^slugs, select: p.id) |> repo().all()

    repo().delete_all(from(rp in "role_permissions", where: rp.permission_id in ^permission_ids))
    repo().delete_all(from(up in "user_permissions", where: up.permission_id in ^permission_ids))
    repo().delete_all(from(p in "permissions", where: p.id in ^permission_ids))
  end
end
