defmodule Medcamp.Authorization do
  @moduledoc """
  The Authorization context — role-default and per-user override permissions,
  layered additively on top of the existing `role`-string authentication.

  See `docs/RBAC_ACCESS_CONTROL_PLAN.md` for the design this implements.

  Nothing in this context is wired into route enforcement or navigation yet
  (Phase 0: schema + resolution logic only, seeded to reproduce today's
  access exactly). Enforcement and admin UI are follow-on phases.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.Accounts.User
  alias Medcamp.Authorization.Permission
  alias Medcamp.Authorization.PermissionReview
  alias Medcamp.Authorization.RolePermission
  alias Medcamp.Authorization.UserPermission

  @doc """
  Resolves whether `user` has `permission_slug`.

  Precedence: a per-user override (grant or deny) always wins over the
  role default. No row for the user means "inherit from role". An
  unrecognized permission slug is always `false` (fails closed).
  """
  def can?(%User{} = user, permission_slug) when is_binary(permission_slug) do
    query =
      from p in Permission,
        where: p.slug == ^permission_slug,
        left_join: up in UserPermission,
        on: up.permission_id == p.id and up.user_id == ^user.id,
        left_join: rp in RolePermission,
        on: rp.permission_id == p.id and rp.role == ^user.role,
        select: %{user_effect: up.effect, role_granted: not is_nil(rp.id)}

    case Repo.one(query) do
      nil -> false
      %{user_effect: "deny"} -> false
      %{user_effect: "grant"} -> true
      %{user_effect: nil, role_granted: role_granted} -> role_granted
    end
  end

  @doc """
  Returns the set of permission slugs `user` effectively has - role
  defaults with overrides applied. Intended for the admin "effective
  access" view and, later, nav filtering (one query instead of N calls
  to `can?/2`).
  """
  def effective_permissions(%User{} = user) do
    role_slugs =
      from(p in Permission,
        join: rp in RolePermission,
        on: rp.permission_id == p.id,
        where: rp.role == ^user.role,
        select: p.slug
      )
      |> Repo.all()
      |> MapSet.new()

    denied =
      from(p in Permission,
        join: up in UserPermission,
        on: up.permission_id == p.id,
        where: up.user_id == ^user.id and up.effect == "deny",
        select: p.slug
      )
      |> Repo.all()
      |> MapSet.new()

    granted =
      from(p in Permission,
        join: up in UserPermission,
        on: up.permission_id == p.id,
        where: up.user_id == ^user.id and up.effect == "grant",
        select: p.slug
      )
      |> Repo.all()
      |> MapSet.new()

    role_slugs
    |> MapSet.difference(denied)
    |> MapSet.union(granted)
  end

  ## Permissions

  def list_permissions do
    Repo.all(from p in Permission, order_by: [asc: p.slug])
  end

  @doc """
  Every permission in the system, alongside `user`'s effective access to
  it and, when that access is an override rather than the role default,
  the override row itself (preloaded with `:granted_by`).

  This is exactly the data the admin "tick/untick" permissions page
  (`docs/RBAC_ACCESS_CONTROL_PLAN.md` §5.4) renders one row per - it does
  the same resolution as `can?/2`, just for every permission at once
  instead of one slug at a time. Deliberately not scoped down to just
  `user`'s own role: an admin can grant any permission to any user
  regardless of role (see `grant_user_override/3`), so the list this
  renders from has to include the ones that grant would come from too.
  """
  def permission_rows_for_user(%User{} = user) do
    role_permission_ids =
      from(rp in RolePermission, where: rp.role == ^user.role, select: rp.permission_id)
      |> Repo.all()
      |> MapSet.new()

    overrides_by_permission_id =
      user
      |> list_user_overrides()
      |> Map.new(&{&1.permission_id, &1})

    list_permissions()
    |> Enum.map(fn permission ->
      override = overrides_by_permission_id[permission.id]
      role_default = MapSet.member?(role_permission_ids, permission.id)

      granted =
        case override do
          %UserPermission{effect: "grant"} -> true
          %UserPermission{effect: "deny"} -> false
          nil -> role_default
        end

      %{permission: permission, granted: granted, role_default: role_default, override: override}
    end)
  end

  def get_permission_by_slug(slug), do: Repo.get_by(Permission, slug: slug)

  def create_permission(attrs \\ %{}) do
    %Permission{}
    |> Permission.changeset(attrs)
    |> Repo.insert()
  end

  ## Role permissions (defaults)

  @doc """
  Returns the permission slugs granted to `role` by default.
  """
  def list_role_permissions(role) do
    from(p in Permission,
      join: rp in RolePermission,
      on: rp.permission_id == p.id,
      where: rp.role == ^role,
      order_by: [asc: p.slug],
      select: p.slug
    )
    |> Repo.all()
  end

  @doc """
  Grants `permission_slug` to every user with `role`, by default. Idempotent
  - granting an already-granted permission is a no-op.
  """
  def grant_role_permission(role, permission_slug, granted_by \\ nil) do
    with %Permission{id: permission_id} <- get_permission_by_slug(permission_slug) do
      case Repo.get_by(RolePermission, role: role, permission_id: permission_id) do
        nil ->
          %RolePermission{}
          |> RolePermission.changeset(%{
            role: role,
            permission_id: permission_id,
            granted_by_id: granted_by && granted_by.id,
            granted_at: DateTime.utc_now() |> DateTime.truncate(:second)
          })
          |> Repo.audited_insert()

        existing ->
          {:ok, existing}
      end
    else
      nil -> {:error, :permission_not_found}
    end
  end

  def revoke_role_permission(role, permission_slug) do
    with %Permission{id: permission_id} <- get_permission_by_slug(permission_slug),
         %RolePermission{} = role_permission <-
           Repo.get_by(RolePermission, role: role, permission_id: permission_id) do
      Repo.audited_delete(role_permission)
    else
      nil -> {:error, :not_found}
    end
  end

  ## Per-user overrides

  @doc """
  Returns this user's override rows (not role defaults), preloaded with
  their permission.
  """
  def list_user_overrides(%User{} = user) do
    from(up in UserPermission,
      where: up.user_id == ^user.id,
      preload: [:permission, :granted_by],
      order_by: [asc: :inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Applies an admin ticking/unticking a permission checkbox for `user` (the
  §5.4 toggle rule): setting it to match what the role would already give
  reverts to "inherits from role" - deleting any existing override rather
  than leaving a redundant one - otherwise creates a grant or deny
  override.
  """
  def toggle_user_permission(%User{} = user, permission_slug, desired_granted?, granted_by) do
    role_default? =
      Repo.exists?(
        from rp in RolePermission,
          join: p in Permission,
          on: p.id == rp.permission_id,
          where: rp.role == ^user.role and p.slug == ^permission_slug
      )

    cond do
      desired_granted? == role_default? -> remove_user_override(user, permission_slug)
      desired_granted? -> grant_user_override(user, permission_slug, granted_by)
      true -> deny_user_override(user, permission_slug, granted_by)
    end
  end

  def grant_user_override(%User{} = user, permission_slug, granted_by) do
    put_user_override(user, permission_slug, "grant", granted_by)
  end

  def deny_user_override(%User{} = user, permission_slug, granted_by) do
    put_user_override(user, permission_slug, "deny", granted_by)
  end

  defp put_user_override(%User{} = user, permission_slug, effect, granted_by) do
    with %Permission{id: permission_id} <- get_permission_by_slug(permission_slug) do
      attrs = %{
        user_id: user.id,
        permission_id: permission_id,
        effect: effect,
        granted_by_id: granted_by && granted_by.id,
        granted_at: DateTime.utc_now() |> DateTime.truncate(:second)
      }

      case Repo.get_by(UserPermission, user_id: user.id, permission_id: permission_id) do
        nil ->
          %UserPermission{}
          |> UserPermission.changeset(attrs)
          |> Repo.audited_insert()

        existing ->
          existing
          |> UserPermission.changeset(attrs)
          |> Repo.audited_update()
      end
    else
      nil -> {:error, :permission_not_found}
    end
  end

  @doc """
  Removes a user's override for `permission_slug`, returning them to
  inheriting the role default. A no-op (returns `{:ok, nil}`) if no
  override exists.
  """
  def remove_user_override(%User{} = user, permission_slug) do
    with %Permission{id: permission_id} <- get_permission_by_slug(permission_slug),
         %UserPermission{} = override <-
           Repo.get_by(UserPermission, user_id: user.id, permission_id: permission_id) do
      Repo.audited_delete(override)
    else
      nil -> {:ok, nil}
    end
  end

  ## Periodic access review (Reg 12(c))

  def record_permission_review(role, reviewer, notes \\ nil) do
    %PermissionReview{}
    |> PermissionReview.changeset(%{
      role: role,
      reviewer_id: reviewer && reviewer.id,
      reviewed_at: DateTime.utc_now() |> DateTime.truncate(:second),
      notes: notes
    })
    |> Repo.insert()
  end

  def last_reviewed_at(role) do
    from(r in PermissionReview,
      where: r.role == ^role,
      order_by: [desc: r.reviewed_at],
      limit: 1,
      select: r.reviewed_at
    )
    |> Repo.one()
  end
end
