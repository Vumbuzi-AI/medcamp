defmodule MedcampWeb.OrganisationSignupLiveTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Medcamp.Accounts
  alias Medcamp.Organisations

  @org %{
    "name" => "Coast Outreach Camp",
    "phone_number" => "0712000111",
    "location" => "Mombasa",
    "contact_name" => "Ada Lead"
  }

  @admin %{
    "email" => "lead@example.com",
    "password" => "correct horse battery",
    "password_confirmation" => "correct horse battery"
  }

  defp change(lv, org, admin, extra \\ %{}) do
    lv
    |> form(
      "#organisation-signup-form",
      Map.merge(%{"organisation" => org, "admin" => admin}, extra)
    )
    |> render_change()
  end

  defp submit(lv, org, admin, extra \\ %{}) do
    lv
    |> form(
      "#organisation-signup-form",
      Map.merge(%{"organisation" => org, "admin" => admin}, extra)
    )
    |> render_submit()
  end

  defp to_step_two(lv) do
    change(lv, @org, %{})
    lv |> element("button", "Continue") |> render_click()
    lv
  end

  test "renders step 1", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/organisations/register")

    assert html =~ "Create your organisation"
    assert html =~ "Enter your organisation"
    assert html =~ "Organisation name"
    assert html =~ "Step 1 of 2"
  end

  describe "step 1 → step 2" do
    test "Continue is blocked until the organisation name is given", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/organisations/register")

      change(lv, %{"name" => ""}, %{})
      lv |> element("button", "Continue") |> render_click()
      assert render(lv) =~ "Step 1 of 2"

      change(lv, @org, %{})
      lv |> element("button", "Continue") |> render_click()
      assert render(lv) =~ "Step 2 of 2"
      assert render(lv) =~ "First camp administrator"
    end

    test "a blank 'Your name' does not block leaving step 1", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/organisations/register")

      change(lv, Map.put(@org, "contact_name", ""), %{})
      lv |> element("button", "Continue") |> render_click()

      assert render(lv) =~ "Step 2 of 2"
    end
  end

  describe "step 2 client-side validation" do
    setup %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/organisations/register")
      %{lv: to_step_two(lv)}
    end

    test "a short password is flagged", %{lv: lv} do
      html = change(lv, @org, %{"password" => "12345", "password_confirmation" => "12345"})
      assert html =~ "must be at least 6 characters"
    end

    test "a mismatched confirmation is flagged", %{lv: lv} do
      html = change(lv, @org, %{"password" => "abcdefg", "password_confirmation" => "abcdefx"})
      assert html =~ "does not match the password"
    end

    test "a malformed admin email is flagged", %{lv: lv} do
      html = change(lv, @org, %{"email" => "not-an-email"})
      assert html =~ "must be a valid email address"
    end

    test "the organisation email field is hidden while 'same as mine' is ticked", %{lv: lv} do
      refute render(lv) =~ "Organisation email"

      html = change(lv, @org, @admin, %{"email_same" => "false"})
      assert html =~ "Organisation email"
    end

    test "a valid step 2 shows no field errors", %{lv: lv} do
      html = change(lv, @org, @admin)
      refute html =~ "must be at least 6 characters"
      refute html =~ "does not match the password"
      refute html =~ "must be a valid email address"
    end
  end

  describe "submitting" do
    test "reuses the admin's email as the organisation contact email by default", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/organisations/register")

      html = lv |> to_step_two() |> submit(@org, @admin)

      assert html =~ "in the queue"
      assert html =~ "medical camp approval queue"

      admin = Accounts.get_user_by_email_and_password("lead@example.com", "correct horse battery")
      assert admin
      assert admin.role == "admin"
      assert admin.name == "Ada Lead"

      org = Organisations.get_organisation!(admin.organisation_id)
      assert org.name == "Coast Outreach Camp"
      assert org.email == "lead@example.com"
      refute org.is_active
      assert Organisations.pending?(org)
    end

    test "keeps a separate organisation email when 'same as mine' is unticked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/organisations/register")
      lv = to_step_two(lv)

      # Unticking "same as mine" reveals the separate organisation email field.
      change(lv, @org, @admin, %{"email_same" => "false"})

      html =
        submit(lv, Map.put(@org, "email", "camp@example.com"), @admin, %{"email_same" => "false"})

      assert html =~ "in the queue"

      admin = Accounts.get_user_by_email_and_password("lead@example.com", "correct horse battery")
      org = Organisations.get_organisation!(admin.organisation_id)
      assert org.email == "camp@example.com"
    end

    test "surfaces a duplicate administrator email on the form", %{conn: conn} do
      {:ok, first, _} = live(conn, ~p"/organisations/register")
      first |> to_step_two() |> submit(@org, @admin)

      {:ok, second, _} = live(conn, ~p"/organisations/register")

      html =
        second
        |> to_step_two()
        |> submit(%{"name" => "Another Camp", "contact_name" => "Bob"}, @admin)

      assert html =~ "has already been taken"
      refute html =~ "in the queue"
    end
  end
end
