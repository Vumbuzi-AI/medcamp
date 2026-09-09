defmodule MedcampWeb.ProfileSettingsLiveTest do
  use MedcampWeb.ConnCase, async: true

  import Medcamp.AccountsFixtures
  import Phoenix.LiveViewTest

  @role_routes [
    {"admin", "/admin/settings"},
    {"doctor", "/doctor/settings"},
    {"nurse", "/nurse/settings"},
    {"labtechnician", "/lab/settings"},
    {"pharmacist", "/pharmacist/settings"}
  ]

  test "role settings pages share the current profile settings design", %{conn: conn} do
    for {role, path} <- @role_routes do
      user = user_fixture(%{role: role, name: "#{role} User"})

      {:ok, _view, html} =
        conn
        |> recycle()
        |> log_in_user(user)
        |> live(path)

      assert html =~ "Profile Information"
      assert html =~ "Profile photo"
      assert html =~ "Staff details"
      assert html =~ "Upload profile photo"
      assert html =~ "Save profile"
      assert html =~ "medical camp workspace"
      refute html =~ "Account settings"
      refute html =~ "Tap to change profile photo"
      refute html =~ "Save Profile"
      refute html =~ "bg-[#0047AB]"
    end
  end
end
