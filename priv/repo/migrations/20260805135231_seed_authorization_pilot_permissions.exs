defmodule Medcamp.Repo.Migrations.SeedAuthorizationPilotPermissions do
  use Ecto.Migration

  @moduledoc """
  Seeds the pilot permission + role_permissions rows that
  `MedcampWeb.Plugs.RequirePermission` now enforces on `/doctor/doctor_procedures*`
  (see docs/RBAC_ACCESS_CONTROL_PLAN.md §6, item 1).

  This has to ship as a migration, not rely on `priv/repo/seeds.exs` (which
  is only run manually), because the router enforcement and this data must
  land atomically - deploying the router change without this data would lock
  every doctor out of a route they already have access to today.
  """

  def up do
    execute("""
    INSERT INTO permissions (slug, description, resource_area, inserted_at, updated_at)
    VALUES
      ('doctor.procedures', 'View and manage doctor procedures', 'doctor_procedures', NOW(), NOW()),
      ('admin.audit_logs', 'View the system audit log', 'audit_logs', NOW(), NOW()),
      ('admin.users', 'Manage user accounts and roles', 'users', NOW(), NOW())
    ON CONFLICT (slug) DO NOTHING
    """)

    execute("""
    INSERT INTO role_permissions (role, permission_id, granted_at, inserted_at, updated_at)
    SELECT 'doctor', id, NOW(), NOW(), NOW() FROM permissions WHERE slug = 'doctor.procedures'
    UNION ALL
    SELECT 'admin', id, NOW(), NOW(), NOW() FROM permissions WHERE slug = 'admin.audit_logs'
    UNION ALL
    SELECT 'admin', id, NOW(), NOW(), NOW() FROM permissions WHERE slug = 'admin.users'
    ON CONFLICT (role, permission_id) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM role_permissions
    WHERE permission_id IN (
      SELECT id FROM permissions
      WHERE slug IN ('doctor.procedures', 'admin.audit_logs', 'admin.users')
    )
    """)

    execute("""
    DELETE FROM permissions
    WHERE slug IN ('doctor.procedures', 'admin.audit_logs', 'admin.users')
    """)
  end
end
