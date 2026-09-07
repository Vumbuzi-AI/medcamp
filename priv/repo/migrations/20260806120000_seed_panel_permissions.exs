defmodule Medcamp.Repo.Migrations.SeedPanelPermissions do
  @moduledoc """
  Seeds a permission per sidebar panel and grants each role its own
  panels, so existing users keep exactly the access their sidebar
  already gave them and admins can then subtract from that.

  The reconciliation itself lives in `Medcamp.Authorization.PanelSync` so
  a later migration can re-run it after panels are added to the
  catalog.
  """

  use Ecto.Migration

  import Ecto.Query

  alias Medcamp.Authorization.PanelSync

  def up do
    PanelSync.sync(repo())

    retire_legacy_procedures_slug()
  end

  # The pilot used `doctor.procedures` for what the catalog now calls
  # `doctor.doctor_procedures` (derived from the sidebar tab_name). Carry
  # any per-user override across before dropping the old slug, so a
  # doctor who had procedures revoked stays revoked.
  defp retire_legacy_procedures_slug do
    old_id =
      repo().one(from(p in "permissions", where: p.slug == "doctor.procedures", select: p.id))

    new_id =
      repo().one(
        from(p in "permissions", where: p.slug == "doctor.doctor_procedures", select: p.id)
      )

    if old_id && new_id do
      already_overridden =
        from(up in "user_permissions", where: up.permission_id == ^new_id, select: up.user_id)
        |> repo().all()

      repo().update_all(
        from(up in "user_permissions",
          where: up.permission_id == ^old_id and up.user_id not in ^already_overridden
        ),
        set: [permission_id: new_id]
      )

      repo().delete_all(from(up in "user_permissions", where: up.permission_id == ^old_id))
      repo().delete_all(from(rp in "role_permissions", where: rp.permission_id == ^old_id))
      repo().delete_all(from(p in "permissions", where: p.id == ^old_id))
    end
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
