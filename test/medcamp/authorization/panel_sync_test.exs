defmodule Medcamp.Authorization.PanelSyncTest do
  use Medcamp.DataCase

  import Ecto.Query

  alias Medcamp.Authorization
  alias Medcamp.Authorization.PanelSync
  alias Medcamp.Repo
  alias MedcampWeb.SidebarCatalog

  # The test database is already migrated, so the seeding migration has
  # run - these assert that re-running the sync converges rather than
  # duplicating or clobbering.

  test "every catalog panel has a permission row after migration" do
    slugs = from(p in "permissions", select: p.slug) |> Repo.all() |> MapSet.new()

    for permission <- SidebarCatalog.all_permissions() do
      assert MapSet.member?(slugs, permission.slug),
             "#{permission.slug} was not seeded"
    end
  end

  test "each role is granted its own panels by default" do
    doctor_defaults = MapSet.new(Authorization.list_role_permissions("doctor"))

    for tab <- SidebarCatalog.all_tabs("doctor") do
      assert MapSet.member?(doctor_defaults, tab.slug),
             "doctor is missing its own panel #{tab.slug}"
    end
  end

  test "each role is granted its per-patient record sections by default" do
    for role <- SidebarCatalog.roles(),
        tabs = SidebarCatalog.all_patient_tabs(role),
        tabs != [] do
      defaults = MapSet.new(Authorization.list_role_permissions(role))

      for tab <- tabs do
        assert MapSet.member?(defaults, tab.slug),
               "#{role} is missing its patient-record panel #{tab.slug}"
      end
    end
  end

  test "re-running is idempotent - no duplicate permissions or grants" do
    before_permissions = Repo.aggregate(from(p in "permissions"), :count)
    before_grants = Repo.aggregate(from(rp in "role_permissions"), :count)

    PanelSync.sync(Repo)

    assert Repo.aggregate(from(p in "permissions"), :count) == before_permissions
    assert Repo.aggregate(from(rp in "role_permissions"), :count) == before_grants
  end

  test "re-running leaves per-user overrides untouched" do
    doctor = Medcamp.AccountsFixtures.user_fixture(%{role: "doctor"})
    {:ok, _} = Authorization.deny_user_override(doctor, "doctor.doctor_procedures", nil)

    PanelSync.sync(Repo)

    refute Authorization.can?(doctor, "doctor.doctor_procedures")
    assert [%{effect: "deny"}] = Authorization.list_user_overrides(doctor)
  end

  test "restores a role default that was deleted out from under it" do
    permission_id =
      Repo.one(
        from(p in "permissions", where: p.slug == "doctor.doctor_procedures", select: p.id)
      )

    Repo.delete_all(
      from(rp in "role_permissions",
        where: rp.role == "doctor" and rp.permission_id == ^permission_id
      )
    )

    refute "doctor.doctor_procedures" in Authorization.list_role_permissions("doctor")

    assert %{role_grants_added: added} = PanelSync.sync(Repo)
    assert added >= 1

    assert "doctor.doctor_procedures" in Authorization.list_role_permissions("doctor")
  end

  test "retires a role grant for a catalog slug the role no longer lists" do
    # admin.users is in the catalog, but not as a *doctor* panel - so a
    # stray grant of it to doctors is the catalog's to clean up.
    permission_id =
      Repo.one(from(p in "permissions", where: p.slug == "admin.users", select: p.id))

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Repo.insert_all("role_permissions", [
      %{
        role: "doctor",
        permission_id: permission_id,
        granted_at: now,
        inserted_at: now,
        updated_at: now
      }
    ])

    assert %{role_grants_removed: removed} = PanelSync.sync(Repo)
    assert removed >= 1

    refute "admin.users" in Authorization.list_role_permissions("doctor")
  end
end
