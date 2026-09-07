defmodule Medcamp.Repo.Migrations.SeedDangerousDrugRegistersPermission do
  use Ecto.Migration

  @moduledoc """
  Seeds `pharmacist.dangerous_drug_registers`, grant-by-default, for the
  allowlist expansion in docs/RBAC_CAPABILITY_TAXONOMY_PROPOSAL.md.

  Grant-by-default (not deny-by-default) is a deliberate choice, confirmed
  with the stakeholder: every pharmacist keeps the access they already have
  today on deploy - an admin can still deny it per-person afterward. This
  ships as a migration, not `priv/repo/seeds.exs`, for the same reason as
  the doctor.procedures pilot: the router enforcement and this data must
  land atomically.
  """

  def up do
    execute("""
    INSERT INTO permissions (slug, description, resource_area, inserted_at, updated_at)
    VALUES
      ('pharmacist.dangerous_drug_registers', 'View and manage the controlled-substance (dangerous drug) register', 'dangerous_drug_registers', NOW(), NOW())
    ON CONFLICT (slug) DO NOTHING
    """)

    execute("""
    INSERT INTO role_permissions (role, permission_id, granted_at, inserted_at, updated_at)
    SELECT 'pharmacist', id, NOW(), NOW(), NOW() FROM permissions
    WHERE slug = 'pharmacist.dangerous_drug_registers'
    ON CONFLICT (role, permission_id) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM role_permissions
    WHERE permission_id IN (
      SELECT id FROM permissions WHERE slug = 'pharmacist.dangerous_drug_registers'
    )
    """)

    execute("""
    DELETE FROM permissions WHERE slug = 'pharmacist.dangerous_drug_registers'
    """)
  end
end
