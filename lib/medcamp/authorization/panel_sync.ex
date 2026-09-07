defmodule Medcamp.Authorization.PanelSync do
  @moduledoc """
  Reconciles the `permissions` and `role_permissions` tables with the
  panels in `MedcampWeb.SidebarCatalog`: a permission row per sidebar
  panel, and each role granted its own panels by default - both its
  main sidebar panels and the per-patient record sections.

  Run from a migration, so adding panels to the catalog and making them
  grantable land together on deploy - no separate manual step, and no
  window where the router enforces a permission the database has not
  been told about yet. Adding a panel later is a new migration that
  calls `sync/2` again.

  Idempotent: re-running inserts only what is missing. Per-user
  overrides are never touched, so an admin's decisions survive a
  re-sync. Role defaults for panels no longer in the catalog are
  removed, so deleting a tab retires its grant too.

  Note this reads the catalog as it exists *when the migration runs*,
  not as it was when the migration was written. That is deliberate -
  the point is to converge on the current catalog - but it does mean
  this is not a frozen historical migration in the usual sense.
  """

  import Ecto.Query

  alias MedcampWeb.SidebarCatalog

  @doc """
  Syncs `repo` to the catalog. Returns a summary of what changed:
  `%{permissions: n, role_grants_added: n, role_grants_removed: n}`.

  `now` is passed in rather than read here so a migration can stamp
  every row it writes with a single timestamp.
  """
  def sync(repo, now \\ DateTime.utc_now() |> DateTime.truncate(:second)) do
    permissions = upsert_permissions(repo, now)
    {added, removed} = sync_role_grants(repo, now)

    %{permissions: permissions, role_grants_added: added, role_grants_removed: removed}
  end

  defp upsert_permissions(repo, now) do
    rows =
      Enum.map(SidebarCatalog.all_permissions(), fn permission ->
        permission
        |> Map.put(:inserted_at, now)
        |> Map.put(:updated_at, now)
      end)

    # Descriptions track the catalog, so renaming a sidebar tab and
    # re-syncing updates the label an admin sees.
    {count, _} =
      repo.insert_all("permissions", rows,
        on_conflict: {:replace, [:description, :resource_area, :updated_at]},
        conflict_target: :slug
      )

    count
  end

  defp sync_role_grants(repo, now) do
    permission_ids = permission_ids_by_slug(repo)

    # Both sidebars a role has: its main panels and the sections of an
    # open patient's record, plus any other role's sidebar it is given in
    # full (reception and admin get the inventory manager's). A role gets
    # every panel it can see by default - a doctor holds all `doctor.*`
    # slugs, patient-scoped ones included - so nobody loses access they
    # had before panels became grantable.
    desired =
      MapSet.new(
        for role <- SidebarCatalog.roles(),
            tab <-
              SidebarCatalog.all_tabs(role) ++
                SidebarCatalog.all_patient_tabs(role) ++
                SidebarCatalog.shared_tabs(role),
            do: {role, permission_ids[tab.slug]}
      )

    existing =
      from(rp in "role_permissions", select: {rp.role, rp.permission_id})
      |> repo.all()
      |> MapSet.new()

    to_insert =
      desired
      |> MapSet.difference(existing)
      |> Enum.map(fn {role, permission_id} ->
        %{
          role: role,
          permission_id: permission_id,
          granted_at: now,
          inserted_at: now,
          updated_at: now
        }
      end)

    {added, _} =
      repo.insert_all("role_permissions", to_insert,
        on_conflict: :nothing,
        conflict_target: [:role, :permission_id]
      )

    {added, retire_stale_grants(repo, permission_ids, desired)}
  end

  # Only retire grants for slugs the catalog owns and no longer lists for
  # that role. Grants for slugs the catalog knows nothing about - added by
  # hand, or by an older migration - are left alone rather than assumed
  # obsolete.
  defp retire_stale_grants(repo, permission_ids, desired) do
    catalog_slugs = MapSet.new(Map.keys(permission_ids))

    stale_ids =
      from(rp in "role_permissions",
        join: p in "permissions",
        on: p.id == rp.permission_id,
        select: {rp.id, rp.role, p.slug}
      )
      |> repo.all()
      |> Enum.filter(fn {_id, role, slug} ->
        MapSet.member?(catalog_slugs, slug) and
          not MapSet.member?(desired, {role, permission_ids[slug]})
      end)
      |> Enum.map(fn {id, _role, _slug} -> id end)

    if stale_ids == [] do
      0
    else
      {removed, _} = repo.delete_all(from(rp in "role_permissions", where: rp.id in ^stale_ids))
      removed
    end
  end

  defp permission_ids_by_slug(repo) do
    slugs = Enum.map(SidebarCatalog.all_permissions(), & &1.slug)

    from(p in "permissions", where: p.slug in ^slugs, select: {p.slug, p.id})
    |> repo.all()
    |> Map.new()
  end
end
