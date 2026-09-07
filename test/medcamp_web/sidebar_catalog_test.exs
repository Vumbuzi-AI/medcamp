defmodule MedcampWeb.SidebarCatalogTest do
  use Medcamp.DataCase

  import Medcamp.AccountsFixtures

  alias Medcamp.Authorization
  alias MedcampWeb.SidebarCatalog

  describe "permission_slug/2" do
    test "normalises the role segment to the slug style already in use" do
      assert SidebarCatalog.permission_slug("doctor", :patients) == "doctor.patients"
      assert SidebarCatalog.permission_slug("labtechnician", :lab_results) == "lab.lab_results"

      assert SidebarCatalog.permission_slug("support staff", :daily_activities) ==
               "support_staff.daily_activities"
    end
  end

  describe "permission_for_path/2" do
    test "matches the longest tab URL, so sub-pages inherit their panel" do
      assert SidebarCatalog.permission_for_path("doctor", "/doctor/patients") ==
               "doctor.patients"

      assert SidebarCatalog.permission_for_path("doctor", "/doctor/patients/42/notes") ==
               "doctor.patients"
    end

    test "does not let one tab swallow another with a shared prefix" do
      # /doctor/patient_visits must not resolve to the /doctor/patients tab.
      assert SidebarCatalog.permission_for_path("doctor", "/doctor/patient_visits") ==
               "doctor.visits"
    end

    test "resolves per-patient sections that nest the id before the section" do
      assert SidebarCatalog.permission_for_path("doctor", "/doctor/42/doctor_procedures") ==
               "doctor.doctor_procedures"

      assert SidebarCatalog.permission_for_path("doctor", "/doctor/42/doctor_procedures/7/edit") ==
               "doctor.doctor_procedures"
    end

    test "returns nil for paths no panel claims" do
      assert SidebarCatalog.permission_for_path("doctor", "/doctor/dashboard") == nil
      assert SidebarCatalog.permission_for_path("doctor", "/doctor/42") == nil
    end
  end

  describe "panel_role_for_path/1" do
    test "derives the panel from the URL prefix, not the user's role" do
      assert SidebarCatalog.panel_role_for_path("/inventory_manager/in_store") ==
               "inventory_manager"

      assert SidebarCatalog.panel_role_for_path("/lab/scan") == "labtechnician"
      assert SidebarCatalog.panel_role_for_path("/support_staff/staff_meals") == "support staff"
    end

    test "returns nil for paths outside every role prefix" do
      assert SidebarCatalog.panel_role_for_path("/chat") == nil
      assert SidebarCatalog.panel_role_for_path("/duty_rota") == nil
    end
  end

  describe "visible_tab_groups/2" do
    test "hides tabs the user has been denied and drops groups left empty" do
      doctor = user_fixture(%{role: "doctor"})

      before = SidebarCatalog.visible_tab_groups(doctor)
      assert "doctor.doctor_procedures" in Enum.map(SidebarCatalog.all_tabs("doctor"), & &1.slug)
      assert tab_named?(before, "My Procedures")

      {:ok, _} = Authorization.deny_user_override(doctor, "doctor.doctor_procedures", nil)

      refute tab_named?(SidebarCatalog.visible_tab_groups(doctor), "My Procedures")
    end

    test "checks the panel being rendered, not the viewer's own role" do
      # An admin browsing the inventory manager pages sees that sidebar, so
      # it must be filtered by the inventory_manager.* slugs.
      admin = user_fixture(%{role: "admin"})

      groups = SidebarCatalog.visible_tab_groups(admin, "inventory_manager")

      assert groups == [] or
               Enum.all?(groups, fn group ->
                 Enum.all?(group.tabs, fn tab ->
                   Authorization.can?(
                     admin,
                     SidebarCatalog.permission_slug("inventory_manager", tab.tab_name)
                   )
                 end)
               end)
    end

    test "a signed-out visitor sees nothing" do
      assert SidebarCatalog.visible_tab_groups(nil) == []
    end
  end

  describe "all_permissions/0" do
    test "covers every tab of every role, deduplicated by slug" do
      slugs = MapSet.new(SidebarCatalog.all_permissions(), & &1.slug)

      for role <- SidebarCatalog.roles(), tab <- SidebarCatalog.all_tabs(role) do
        assert MapSet.member?(slugs, tab.slug),
               "#{role} tab #{tab.name} (#{tab.slug}) has no permission row"
      end
    end
  end

  describe "per-patient panels" do
    test "are slugged apart from the main sidebar's tabs" do
      # A doctor can hold the all-patients lab results panel without
      # holding the per-patient one, so the two must not collide.
      assert SidebarCatalog.permission_slug("doctor", :lab_results) == "doctor.lab_results"

      assert SidebarCatalog.patient_permission_slug("doctor", :lab_results) ==
               "doctor.patient.lab_results"
    end

    test "a patient sub-page resolves to its own section, not the patient list" do
      assert SidebarCatalog.permission_for_path("doctor", "/doctor/patients/42/notes") ==
               "doctor.patient.doctor_notes"

      assert SidebarCatalog.permission_for_path("doctor", "/doctor/patients/42/triages") ==
               "doctor.patient.triages"
    end

    test "sub-pages of a section belong to that section" do
      assert SidebarCatalog.permission_for_path("doctor", "/doctor/patients/42/notes/new") ==
               "doctor.patient.doctor_notes"
    end

    test "sections that nest the id before the section still resolve" do
      assert SidebarCatalog.permission_for_path("doctor", "/doctor/42/doctor_procedures") ==
               "doctor.patient.doctor_procedures"

      assert SidebarCatalog.permission_for_path("nurse", "/nurse/42/cadex_notes") ==
               "nurse.patient.cadex_notes"
    end

    test "list-management routes are not mistaken for a patient record" do
      # /doctor/patients/new sits where an id would go, but "new" is not
      # an id - it belongs to the patient list panel.
      assert SidebarCatalog.permission_for_path("doctor", "/doctor/patients/new") ==
               "doctor.patients"
    end

    test "the patient list itself is still the main sidebar's panel" do
      assert SidebarCatalog.permission_for_path("doctor", "/doctor/patients") == "doctor.patients"
    end

    test "visible_patient_tabs hides denied sections" do
      doctor = user_fixture(%{role: "doctor"})
      patient = %{id: 7}

      assert flat_tab_named?(
               SidebarCatalog.visible_patient_tabs(doctor, "doctor", patient),
               "MCH (Mother & Child)"
             )

      {:ok, _} = Authorization.deny_user_override(doctor, "doctor.patient.mch", nil)

      refute flat_tab_named?(
               SidebarCatalog.visible_patient_tabs(doctor, "doctor", patient),
               "MCH (Mother & Child)"
             )
    end

    test "the back-to-list tab is never filtered away" do
      doctor = user_fixture(%{role: "doctor"})

      for tab <- SidebarCatalog.all_patient_tabs("doctor") do
        {:ok, _} = Authorization.deny_user_override(doctor, tab.slug, nil)
      end

      # Everything denied, but the user must still be able to get out.
      assert [%{name: "All Patients"}] =
               SidebarCatalog.visible_patient_tabs(doctor, "doctor", %{id: 7})
    end
  end

  defp flat_tab_named?(tabs, name), do: Enum.any?(tabs, &(&1.name == name))

  defp tab_named?(groups, name) do
    Enum.any?(groups, fn group -> Enum.any?(group.tabs, &(&1.name == name)) end)
  end
end
