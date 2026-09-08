defmodule Medcamp.Repo.Migrations.SyncCampsPanel do
  @moduledoc """
  Registers the admin "Camps" panel as a grantable permission.

  `Medcamp.Authorization.can?/2` fails closed, so without this the tab is
  hidden and `/admin/camps` is refused even for an admin. `sync/1` is
  idempotent and derives the set from `MedcampWeb.SidebarCatalog`.
  """

  use Ecto.Migration

  import Ecto.Query

  alias Medcamp.Authorization.PanelSync

  def up do
    PanelSync.sync(repo())
  end

  def down do
    permission_ids =
      from(p in "permissions", where: p.slug == "admin.camps", select: p.id)
      |> repo().all()

    repo().delete_all(from(rp in "role_permissions", where: rp.permission_id in ^permission_ids))
    repo().delete_all(from(up in "user_permissions", where: up.permission_id in ^permission_ids))
    repo().delete_all(from(p in "permissions", where: p.id in ^permission_ids))
  end
end
