defmodule Medcamp.AuthorizationTest do
  use Medcamp.DataCase

  alias Medcamp.Authorization

  import Medcamp.AccountsFixtures

  defp permission_fixture(attrs \\ %{}) do
    attrs = Enum.into(attrs, %{slug: "test.permission-#{System.unique_integer()}"})
    {:ok, permission} = Authorization.create_permission(attrs)
    permission
  end

  describe "can?/2" do
    test "returns false when the permission slug doesn't exist" do
      user = user_fixture(%{role: "doctor"})

      refute Authorization.can?(user, "nonexistent.permission")
    end

    test "returns false when the role has no default grant and there's no override" do
      user = user_fixture(%{role: "doctor"})
      permission = permission_fixture()

      refute Authorization.can?(user, permission.slug)
    end

    test "returns true when the role has a default grant" do
      user = user_fixture(%{role: "doctor"})
      permission = permission_fixture()

      {:ok, _} = Authorization.grant_role_permission("doctor", permission.slug)

      assert Authorization.can?(user, permission.slug)
    end

    test "a role default grant only applies to users with that role" do
      doctor = user_fixture(%{role: "doctor"})
      nurse = user_fixture(%{role: "nurse"})
      permission = permission_fixture()

      {:ok, _} = Authorization.grant_role_permission("doctor", permission.slug)

      assert Authorization.can?(doctor, permission.slug)
      refute Authorization.can?(nurse, permission.slug)
    end

    test "a per-user grant override wins even when the role has no default" do
      user = user_fixture(%{role: "doctor"})
      permission = permission_fixture()

      {:ok, _} = Authorization.grant_user_override(user, permission.slug, nil)

      assert Authorization.can?(user, permission.slug)
    end

    test "a per-user deny override wins over a role default grant" do
      user = user_fixture(%{role: "doctor"})
      permission = permission_fixture()

      {:ok, _} = Authorization.grant_role_permission("doctor", permission.slug)
      {:ok, _} = Authorization.deny_user_override(user, permission.slug, nil)

      refute Authorization.can?(user, permission.slug)
    end

    test "a per-user override never affects other users with the same role" do
      doctor_a = user_fixture(%{role: "doctor"})
      doctor_b = user_fixture(%{role: "doctor"})
      permission = permission_fixture()

      {:ok, _} = Authorization.grant_role_permission("doctor", permission.slug)
      {:ok, _} = Authorization.deny_user_override(doctor_a, permission.slug, nil)

      refute Authorization.can?(doctor_a, permission.slug)
      assert Authorization.can?(doctor_b, permission.slug)
    end

    test "removing a user override returns them to inheriting the role default" do
      user = user_fixture(%{role: "doctor"})
      permission = permission_fixture()

      {:ok, _} = Authorization.grant_role_permission("doctor", permission.slug)
      {:ok, _} = Authorization.deny_user_override(user, permission.slug, nil)
      refute Authorization.can?(user, permission.slug)

      {:ok, _} = Authorization.remove_user_override(user, permission.slug)

      assert Authorization.can?(user, permission.slug)
    end
  end

  describe "effective_permissions/1" do
    test "combines role defaults with grant and deny overrides" do
      user = user_fixture(%{role: "doctor"})
      granted_by_role = permission_fixture(%{slug: "role.granted"})
      denied_override = permission_fixture(%{slug: "role.denied-by-override"})
      granted_override = permission_fixture(%{slug: "user.granted-only"})

      {:ok, _} = Authorization.grant_role_permission("doctor", granted_by_role.slug)
      {:ok, _} = Authorization.grant_role_permission("doctor", denied_override.slug)
      {:ok, _} = Authorization.deny_user_override(user, denied_override.slug, nil)
      {:ok, _} = Authorization.grant_user_override(user, granted_override.slug, nil)

      effective = Authorization.effective_permissions(user)

      assert MapSet.member?(effective, granted_by_role.slug)
      refute MapSet.member?(effective, denied_override.slug)
      assert MapSet.member?(effective, granted_override.slug)
    end
  end

  describe "grant_role_permission/3" do
    test "is idempotent" do
      permission = permission_fixture()

      {:ok, first} = Authorization.grant_role_permission("doctor", permission.slug)
      {:ok, second} = Authorization.grant_role_permission("doctor", permission.slug)

      assert first.id == second.id
    end

    test "returns an error for an unknown permission slug" do
      assert {:error, :permission_not_found} =
               Authorization.grant_role_permission("doctor", "nonexistent.permission")
    end
  end

  describe "revoke_role_permission/2" do
    test "removes the role default grant" do
      user = user_fixture(%{role: "doctor"})
      permission = permission_fixture()

      {:ok, _} = Authorization.grant_role_permission("doctor", permission.slug)
      assert Authorization.can?(user, permission.slug)

      {:ok, _} = Authorization.revoke_role_permission("doctor", permission.slug)

      refute Authorization.can?(user, permission.slug)
    end

    test "returns an error when there's nothing to revoke" do
      permission = permission_fixture()

      assert {:error, :not_found} =
               Authorization.revoke_role_permission("doctor", permission.slug)
    end
  end

  describe "remove_user_override/2" do
    test "is a no-op when there's no override to remove" do
      user = user_fixture(%{role: "doctor"})
      permission = permission_fixture()

      assert {:ok, nil} = Authorization.remove_user_override(user, permission.slug)
    end
  end

  describe "list_user_overrides/1" do
    test "returns only this user's override rows, preloaded with their permission" do
      user = user_fixture(%{role: "doctor"})
      other_user = user_fixture(%{role: "doctor"})
      permission = permission_fixture()

      {:ok, _} = Authorization.grant_user_override(user, permission.slug, nil)
      {:ok, _} = Authorization.deny_user_override(other_user, permission.slug, nil)

      [override] = Authorization.list_user_overrides(user)

      assert override.permission.slug == permission.slug
      assert override.effect == "grant"
    end
  end

  describe "record_permission_review/3 and last_reviewed_at/1" do
    test "records a review and returns the most recent review timestamp" do
      reviewer = user_fixture(%{role: "admin"})

      assert Authorization.last_reviewed_at("doctor") == nil

      {:ok, _} = Authorization.record_permission_review("doctor", reviewer, "quarterly review")

      assert %DateTime{} = Authorization.last_reviewed_at("doctor")
    end
  end
end
