defmodule MedcampWeb.UserAuthOrganisationGateTest do
  @moduledoc """
  A deactivated (or never-approved) organisation must lock out its staff
  immediately - both at the moment they try to log in, and on requests made
  with a session they already held before their organisation was suspended.
  """

  use MedcampWeb.ConnCase, async: true

  alias Medcamp.Accounts
  alias Medcamp.Organisations
  alias MedcampWeb.UserAuth

  defp create_user(organisation) do
    Medcamp.Tenancy.with_org(organisation.id, fn ->
      {:ok, user} =
        Accounts.register_user(%{
          "name" => "Ada",
          "email" => "ada-#{System.unique_integer([:positive])}@example.com",
          "password" => "hello world!",
          "role" => "admin"
        })

      user
    end)
  end

  # `UserAuth.log_in_user/3` reads and writes the session and flash directly,
  # which a bare `build_conn()` has not set up - the browser pipeline does
  # that before this function is ever reached in production.
  defp conn_with_session(conn) do
    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Phoenix.Controller.fetch_flash([])
  end

  describe "log_in_user/3" do
    test "signs in a user whose organisation is active", %{conn: conn, organisation: org} do
      {:ok, org} = Organisations.approve(org)
      user = create_user(org)

      conn = UserAuth.log_in_user(conn_with_session(conn), user)

      assert get_session(conn, :user_token)
    end

    test "refuses a user whose organisation was deactivated", %{conn: conn, organisation: org} do
      {:ok, org} = Organisations.approve(org)
      user = create_user(org)
      {:ok, _} = Organisations.deactivate_organisation(org)

      conn = UserAuth.log_in_user(conn_with_session(conn), user)

      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "not active"
    end

    test "refuses a user whose organisation is still pending approval", %{
      conn: conn,
      organisation: org
    } do
      user = create_user(org)

      conn = UserAuth.log_in_user(conn_with_session(conn), user)

      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "awaiting approval"
    end

    test "sends a superadmin to the platform console", %{conn: conn, organisation: org} do
      {:ok, org} = Organisations.approve(org)

      user =
        org
        |> create_user()
        |> Ecto.Changeset.change(%{is_superadmin: true})
        |> Medcamp.Repo.update!()

      conn = UserAuth.log_in_user(conn_with_session(conn), user)

      assert redirected_to(conn) == "/superadmin/organisations"
    end
  end

  describe "reject_inactive_organisation/1" do
    test "passes through a user whose organisation is active", %{organisation: org} do
      {:ok, org} = Organisations.approve(org)
      user = create_user(org)

      assert UserAuth.reject_inactive_organisation(user).id == user.id
    end

    test "drops a user whose organisation was deactivated after they logged in", %{
      organisation: org
    } do
      {:ok, org} = Organisations.approve(org)
      user = create_user(org)
      {:ok, _} = Organisations.deactivate_organisation(org)

      assert UserAuth.reject_inactive_organisation(user) == nil
    end

    test "passes nil through unchanged" do
      assert UserAuth.reject_inactive_organisation(nil) == nil
    end
  end
end
