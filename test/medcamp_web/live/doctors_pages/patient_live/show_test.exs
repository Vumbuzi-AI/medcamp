defmodule MedcampWeb.DoctorsPagePatientLive.ShowTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures
  import Medcamp.PatientsFixtures
  import Medcamp.AllergyHistoriesFixtures

  alias Medcamp.AllergyHistories

  setup do
    %{doctor: user_fixture(%{role: "doctor"}), patient: patient_fixture()}
  end

  describe "Allergy History" do
    test "shows an empty state when the patient has no recorded allergies", %{
      conn: conn,
      doctor: doctor,
      patient: patient
    } do
      conn = log_in_user(conn, doctor)

      {:ok, _view, html} = live(conn, ~p"/doctor/patients/#{patient.id}")

      assert html =~ "No allergy history recorded for this patient."
    end

    test "lists existing allergy history with criticality and status", %{
      conn: conn,
      doctor: doctor,
      patient: patient
    } do
      conn = log_in_user(conn, doctor)

      allergy_history_fixture(%{
        patient: patient,
        substance_name: "Penicillin",
        category: "medication",
        type: "allergy",
        criticality: "high",
        reaction_manifestation: "Anaphylaxis"
      })

      {:ok, _view, html} = live(conn, ~p"/doctor/patients/#{patient.id}")

      assert html =~ "Penicillin"
      assert html =~ "High criticality"
      assert html =~ "Anaphylaxis"
    end

    test "doctor can add a new allergy history entry", %{
      conn: conn,
      doctor: doctor,
      patient: patient
    } do
      conn = log_in_user(conn, doctor)

      {:ok, view, _html} = live(conn, ~p"/doctor/patients/#{patient.id}")

      view
      |> element("button", "Add Allergy")
      |> render_click()

      assert has_element?(view, "h3", "Add Allergy")

      html =
        view
        |> form("#allergy-history-modal form", %{
          "allergy_history" => %{
            "substance_name" => "Peanuts",
            "category" => "food",
            "type" => "allergy",
            "criticality" => "high",
            "clinical_status" => "active",
            "verification_status" => "confirmed",
            "reaction_manifestation" => "Swelling"
          }
        })
        |> render_submit()

      assert html =~ "Allergy history saved"
      assert html =~ "Peanuts"

      [saved] = AllergyHistories.list_allergy_histories_for_patient(patient.id)
      assert saved.substance_name == "Peanuts"
      assert saved.recorded_by_id == doctor.id
    end

    test "doctor can edit an existing allergy history entry", %{
      conn: conn,
      doctor: doctor,
      patient: patient
    } do
      conn = log_in_user(conn, doctor)

      allergy =
        allergy_history_fixture(%{
          patient: patient,
          substance_name: "Penicillin",
          clinical_status: "active"
        })

      {:ok, view, _html} = live(conn, ~p"/doctor/patients/#{patient.id}")

      view
      |> element(~s([phx-click="edit_allergy"][phx-value-id="#{allergy.id}"]))
      |> render_click()

      assert has_element?(view, "h3", "Edit Allergy")

      html =
        view
        |> form("#allergy-history-modal form", %{
          "allergy_history" => %{
            "substance_name" => allergy.substance_name,
            "category" => allergy.category,
            "type" => allergy.type,
            "criticality" => allergy.criticality,
            "clinical_status" => "resolved",
            "verification_status" => allergy.verification_status
          }
        })
        |> render_submit()

      assert html =~ "Resolved"
      assert AllergyHistories.get_allergy_history!(allergy.id).clinical_status == "resolved"
    end

    test "doctor can remove an allergy history entry", %{
      conn: conn,
      doctor: doctor,
      patient: patient
    } do
      conn = log_in_user(conn, doctor)

      allergy = allergy_history_fixture(%{patient: patient, substance_name: "Latex"})

      {:ok, view, _html} = live(conn, ~p"/doctor/patients/#{patient.id}")

      assert has_element?(view, "p", "Latex")

      view
      |> element(~s([phx-click="delete_allergy"][phx-value-id="#{allergy.id}"]))
      |> render_click()

      refute has_element?(view, "p", "Latex")

      assert_raise Ecto.NoResultsError, fn ->
        AllergyHistories.get_allergy_history!(allergy.id)
      end
    end
  end
end
