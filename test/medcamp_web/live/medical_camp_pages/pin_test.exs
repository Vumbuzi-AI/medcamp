defmodule MedcampWeb.MedicalCampPages.PinTest do
  @moduledoc """
  The camp-station PIN screen (`/8018/:gsrn/medical-camp/pin`) and its
  sign-in (`POST /8018/:gsrn/medical-camp/session`).

  The scanned wristband fixes the organisation; a staff PIN only signs someone
  in if they belong to that organisation (finding S-2, fix 1).
  """
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures
  import Medcamp.PatientsFixtures

  alias Medcamp.Repo

  defp with_otp(user, otp),
    do: user |> Ecto.Changeset.change(%{otp: otp}) |> Repo.update!()

  setup %{conn: conn} do
    patient = patient_fixture()
    %{conn: conn, patient: patient, path: "/8018/#{patient.gsrn}/medical-camp"}
  end

  test "renders the PIN form for a recognised wristband", %{conn: conn, path: path} do
    {:ok, _view, html} = live(conn, "#{path}/pin")

    assert html =~ "Camp station sign-in"
    assert html =~ ~s(action="#{path}/session")
    assert html =~ ~s(name="otp")
  end

  test "shows a not-recognised message for an unknown wristband", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/8018/NOSUCHGSRN/medical-camp/pin")

    assert html =~ "not recognised"
    refute html =~ ~s(name="otp")
  end

  test "a same-org staff PIN signs in and lands on the patient overview", %{
    conn: conn,
    patient: patient,
    path: path
  } do
    _nurse = user_fixture(%{role: "nurse"}) |> with_otp("4242")

    conn = post(conn, "#{path}/session", %{"gsrn" => patient.gsrn, "otp" => "4242"})

    # log_in_user renews the session and redirects; a nurse is then bounced to
    # the triage route by Home's mount.
    assert redirected_to(conn) in [path, "#{path}/triages/new"]
    assert get_session(conn, :user_token)
  end

  test "a PIN belonging to another organisation's user is rejected", %{
    conn: conn,
    patient: patient,
    path: path
  } do
    other_org = Medcamp.OrganisationsFixtures.organisation_fixture(%{"name" => "Other Org"})

    user_fixture(%{role: "nurse"})
    |> Ecto.Changeset.change(%{organisation_id: other_org.id, otp: "9999"})
    |> Repo.update!()

    conn = post(conn, "#{path}/session", %{"gsrn" => patient.gsrn, "otp" => "9999"})

    assert redirected_to(conn) == "#{path}/pin"
    refute get_session(conn, :user_token)
    assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "isn't valid for this camp"
  end

  test "a deactivated same-org user's PIN is rejected", %{
    conn: conn,
    patient: patient,
    path: path
  } do
    user_fixture(%{role: "nurse"})
    |> Ecto.Changeset.change(%{otp: "1212", is_active: false})
    |> Repo.update!()

    conn = post(conn, "#{path}/session", %{"gsrn" => patient.gsrn, "otp" => "1212"})

    assert redirected_to(conn) == "#{path}/pin"
    refute get_session(conn, :user_token)
  end
end
