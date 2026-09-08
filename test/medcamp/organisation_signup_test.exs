defmodule Medcamp.OrganisationSignupTest do
  @moduledoc """
  Self-serve signup and the approval gate that stands between a signup and a
  usable tenant.
  """

  use Medcamp.DataCase, async: true

  alias Medcamp.Accounts
  alias Medcamp.Organisations
  alias Medcamp.Tenancy

  defp signup(overrides \\ %{}) do
    org =
      Enum.into(overrides, %{
        "name" => "Nairobi Health Camp",
        "email" => "camp@example.com",
        "contact_name" => "Ada Lovelace",
        "location" => "Nairobi"
      })

    admin = %{"email" => "ada@example.com", "password" => "hello world!"}

    Organisations.register_organisation(org, admin)
  end

  describe "register_organisation/2" do
    test "creates the organisation and its admin together" do
      assert {:ok, %{organisation: org, admin: admin}} = signup()

      assert org.name == "Nairobi Health Camp"
      assert admin.email == "ada@example.com"
      assert admin.role == "admin"

      # The admin belongs to the organisation that was just created, not to
      # whichever tenant the signup request happened to be running in.
      assert admin.organisation_id == org.id
    end

    test "the new organisation starts pending, not active" do
      assert {:ok, %{organisation: org}} = signup()

      refute org.is_active
      assert is_nil(org.approved_at)
      assert Organisations.pending?(org)
      assert org.id in Enum.map(Organisations.list_pending_organisations(), & &1.id)
    end

    test "derives a slug from the name" do
      assert {:ok, %{organisation: org}} = signup()
      assert org.slug =~ ~r/^nairobi-health-camp-[a-z0-9]+$/
    end

    test "generates a lowercase slug suffix" do
      slug = Medcamp.Organisations.Organisation.slugify("Jkuat")

      assert slug =~ ~r/^jkuat-[a-z0-9]+$/
      refute slug =~ ~r/[A-Z]/
    end

    test "two organisations with the same name get distinct slugs" do
      assert {:ok, %{organisation: first}} = signup(%{"email" => "first@example.com"})

      assert {:ok, %{organisation: second}} =
               Organisations.register_organisation(
                 %{
                   "name" => "Nairobi Health Camp",
                   "email" => "second@example.com",
                   "contact_name" => "Grace Hopper"
                 },
                 %{"email" => "grace@example.com", "password" => "hello world!"}
               )

      refute first.slug == second.slug
    end

    test "a duplicate admin email leaves no orphaned organisation behind" do
      assert {:ok, _} = signup()

      before = length(Organisations.list_organisations())

      assert {:error, :admin, changeset} =
               Organisations.register_organisation(
                 %{
                   "name" => "Another Camp",
                   "email" => "another@example.com",
                   "contact_name" => "Grace Hopper"
                 },
                 %{"email" => "ada@example.com", "password" => "hello world!"}
               )

      assert "has already been taken" in errors_on(changeset).email
      assert length(Organisations.list_organisations()) == before
    end

    test "rejects an organisation with no contact name" do
      assert {:error, :organisation, changeset} = signup(%{"contact_name" => ""})
      assert "can't be blank" in errors_on(changeset).contact_name
    end
  end

  describe "approve/1" do
    test "activates the organisation and records when" do
      assert {:ok, %{organisation: org}} = signup()
      assert {:ok, approved} = Organisations.approve(org)

      assert approved.is_active
      refute is_nil(approved.approved_at)
      refute Organisations.pending?(approved)
      assert Organisations.list_pending_organisations() == []
    end

    test "a suspended organisation is not the same as a pending one" do
      assert {:ok, %{organisation: org}} = signup()
      {:ok, approved} = Organisations.approve(org)
      {:ok, suspended} = Organisations.deactivate_organisation(approved)

      refute suspended.is_active
      refute is_nil(suspended.approved_at)
      refute Organisations.pending?(suspended)
    end
  end

  describe "tenancy of a fresh signup" do
    test "the new admin sees none of another organisation's data", %{organisation: existing} do
      {:ok, patient} =
        Tenancy.with_org(existing.id, fn ->
          Medcamp.Patients.create_patient(%{
            "first_name" => "Ada",
            "last_name" => "Test",
            "gender" => "female"
          })
        end)

      assert {:ok, %{organisation: new_org}} = signup()

      patients =
        Tenancy.with_org(new_org.id, fn -> Medcamp.Patients.list_patients() end)

      refute patient.id in Enum.map(patients, & &1.id)
      assert patients == []
    end

    test "the admin is reachable only from inside its own organisation" do
      assert {:ok, %{organisation: org, admin: admin}} = signup()

      assert Tenancy.with_org(org.id, fn ->
               Accounts.get_organisation_user_by_email(admin.email)
             end).id == admin.id

      # The default test tenant is a different organisation.
      assert is_nil(Accounts.get_organisation_user_by_email(admin.email))
    end
  end
end
