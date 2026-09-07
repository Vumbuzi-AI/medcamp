defmodule MedcampWeb.ReceptionsPagePatientLive.IndexTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures
  import Medcamp.PatientsFixtures

  alias Medcamp.Patients

  setup do
    %{reception: user_fixture(%{role: "reception"})}
  end

  describe "new patient identity documents" do
    test "cancel-upload ignores malformed upload keys instead of crashing" do
      socket = %Phoenix.LiveView.Socket{}

      assert {:noreply, %Phoenix.LiveView.Socket{assigns: %{upload_error: nil}}} =
               MedcampWeb.AddPatientComponent.handle_event(
                 "cancel-upload",
                 %{"ref" => "bogus-ref", "upload" => "bogus_upload_key"},
                 socket
               )
    end

    test "cancel-upload still works for a valid upload key", %{
      conn: conn,
      reception: reception
    } do
      conn = log_in_user(conn, reception)

      {:ok, view, _html} = live(conn, ~p"/reception/patients/new")

      national_id_upload =
        file_input(view, "#patient-form", :national_id_document, [
          %{
            name: "national_id.pdf",
            content: "dummy national id binary content",
            type: "application/pdf"
          }
        ])

      render_upload(national_id_upload, "national_id.pdf")

      assert has_element?(view, "button[aria-label='cancel']")

      view
      |> element("button[aria-label='cancel']")
      |> render_click()

      refute has_element?(view, "button[aria-label='cancel']")
    end

    test "creates a patient with a national ID document and birth certificate number/document",
         %{conn: conn, reception: reception} do
      conn = log_in_user(conn, reception)

      {:ok, view, _html} = live(conn, ~p"/reception/patients/new")

      national_id_upload =
        file_input(view, "#patient-form", :national_id_document, [
          %{
            name: "national_id.pdf",
            content: "%PDF-1.4 dummy national id binary content",
            type: "application/pdf"
          }
        ])

      render_upload(national_id_upload, "national_id.pdf")

      birth_cert_upload =
        file_input(view, "#patient-form", :birth_certificate_document, [
          %{
            name: "birth_certificate.pdf",
            content: "%PDF-1.4 dummy birth certificate binary content",
            type: "application/pdf"
          }
        ])

      render_upload(birth_cert_upload, "birth_certificate.pdf")

      view
      |> form("#patient-form", %{
        "patient" => %{
          "first_name" => "Jane",
          "last_name" => "Wanjiru",
          "phone_number" => "0712345678",
          "date_of_birth" => "1995-04-12",
          "gender" => "Female",
          "national_id" => "30123456",
          "birth_certificate_number" => "BC-2026-001",
          "home_address" => "Nairobi",
          "consent_agreement" => "true"
        }
      })
      |> render_submit()

      [patient] = Patients.list_patients()

      assert patient.national_id == "30123456"

      assert patient.national_id_document =~
               ~r/^\/uploads\/patients\/national-id\/national-id-\d{8}T\d{6}Z-[a-f0-9]{8}\.pdf$/

      assert patient.birth_certificate_number == "BC-2026-001"

      assert patient.birth_certificate_document =~
               ~r/^\/uploads\/patients\/birth-certificate\/birth-certificate-\d{8}T\d{6}Z-[a-f0-9]{8}\.pdf$/

      # The stored filename must never contain the original client-supplied
      # filename - only the document type, a timestamp, and a random
      # suffix, so nothing identifying ever ends up in the URL/logs.
      refute patient.national_id_document =~ "national_id.pdf"
      refute patient.birth_certificate_document =~ "birth_certificate.pdf"
    end

    test "creating a patient without identity documents does not fail", %{
      conn: conn,
      reception: reception
    } do
      conn = log_in_user(conn, reception)

      {:ok, view, _html} = live(conn, ~p"/reception/patients/new")

      view
      |> form("#patient-form", %{
        "patient" => %{
          "first_name" => "No",
          "last_name" => "Documents",
          "phone_number" => "0798765432",
          "date_of_birth" => "1990-01-01",
          "gender" => "Male",
          "home_address" => "Nairobi",
          "consent_agreement" => "true"
        }
      })
      |> render_submit()

      [patient] = Patients.list_patients()

      assert patient.national_id_document == nil
      assert patient.birth_certificate_number == nil
      assert patient.birth_certificate_document == nil
    end

    test "editing a patient without re-uploading a document keeps the existing one", %{
      conn: conn,
      reception: reception
    } do
      conn = log_in_user(conn, reception)

      patient =
        patient_fixture(%{
          "gender" => "Female",
          "national_id_document" => "/uploads/existing-national-id.pdf",
          "birth_certificate_document" => "/uploads/existing-birth-cert.pdf"
        })

      {:ok, view, _html} = live(conn, ~p"/reception/patients/#{patient.id}/edit")

      assert has_element?(view, "a", "View current document")

      view
      |> form("#patient-form", %{
        "patient" => %{
          "first_name" => "Updated",
          "phone_number" => patient.phone_number,
          "date_of_birth" => Date.to_iso8601(patient.date_of_birth),
          "gender" => patient.gender,
          "home_address" => patient.home_address,
          "consent_agreement" => "true"
        }
      })
      |> render_submit()

      updated = Patients.get_patient!(patient.id)
      assert updated.first_name == "Updated"
      assert updated.national_id_document == "/uploads/existing-national-id.pdf"
      assert updated.birth_certificate_document == "/uploads/existing-birth-cert.pdf"
    end

    test "saving an edit redirects to that patient's overview page, not the list", %{
      conn: conn,
      reception: reception
    } do
      conn = log_in_user(conn, reception)

      patient = patient_fixture(%{"gender" => "Female"})

      {:ok, view, _html} = live(conn, ~p"/reception/patients/#{patient.id}/edit")

      view
      |> form("#patient-form", %{
        "patient" => %{
          "first_name" => "Updated",
          "phone_number" => patient.phone_number,
          "date_of_birth" => Date.to_iso8601(patient.date_of_birth),
          "gender" => patient.gender,
          "home_address" => patient.home_address,
          "consent_agreement" => "true"
        }
      })
      |> render_submit()

      assert_redirect(view, ~p"/reception/#{patient.id}/patient_overview")
    end

    test "selecting an unsupported file type does not crash the form and leaves the existing document untouched",
         %{conn: conn, reception: reception} do
      conn = log_in_user(conn, reception)

      patient =
        patient_fixture(%{
          "gender" => "Female",
          "birth_certificate_document" => "/uploads/existing-birth-cert.pdf"
        })

      {:ok, view, _html} = live(conn, ~p"/reception/patients/#{patient.id}/edit")

      upload =
        file_input(view, "#patient-form", :birth_certificate_document, [
          %{
            name: "notes.txt",
            content: "not an image or pdf",
            type: "text/plain"
          }
        ])

      assert {:error, _} = render_upload(upload, "notes.txt")

      html =
        view
        |> element("#patient-form")
        |> render_submit(%{
          "patient" => %{
            "first_name" => patient.first_name,
            "phone_number" => patient.phone_number,
            "date_of_birth" => Date.to_iso8601(patient.date_of_birth),
            "gender" => patient.gender,
            "home_address" => patient.home_address,
            "consent_agreement" => "true"
          }
        })

      assert html =~ "You have selected an unacceptable file type"
      assert html =~ "Birth Certificate Document: You have selected an unacceptable file type"
      assert Process.alive?(view.pid)

      unchanged = Patients.get_patient!(patient.id)
      assert unchanged.birth_certificate_document == "/uploads/existing-birth-cert.pdf"
    end
  end

  describe "replacing an existing document" do
    test "deletes the old file from disk once the new one is saved", %{
      conn: conn,
      reception: reception
    } do
      conn = log_in_user(conn, reception)

      uploads_dir = Path.join([:code.priv_dir(:medcamp), "static", "uploads"])
      File.mkdir_p!(uploads_dir)
      old_path = Path.join(uploads_dir, "old-birth-cert.pdf")
      File.write!(old_path, "%PDF-1.4 old file contents")

      patient =
        patient_fixture(%{
          "gender" => "Female",
          "birth_certificate_document" => "/uploads/old-birth-cert.pdf"
        })

      {:ok, view, _html} = live(conn, ~p"/reception/patients/#{patient.id}/edit")

      upload =
        file_input(view, "#patient-form", :birth_certificate_document, [
          %{
            name: "new-birth-cert.pdf",
            content: "%PDF-1.4 new file contents",
            type: "application/pdf"
          }
        ])

      render_upload(upload, "new-birth-cert.pdf")

      view
      |> element("#patient-form")
      |> render_submit(%{
        "patient" => %{
          "first_name" => patient.first_name,
          "phone_number" => patient.phone_number,
          "date_of_birth" => Date.to_iso8601(patient.date_of_birth),
          "gender" => patient.gender,
          "home_address" => patient.home_address,
          "consent_agreement" => "true"
        }
      })

      updated = Patients.get_patient!(patient.id)
      assert updated.birth_certificate_document != "/uploads/old-birth-cert.pdf"
      assert updated.birth_certificate_document =~ ~r/^\/uploads\/patients\/birth-certificate\//
      refute File.exists?(old_path)
    end

    test "leaves the old file on disk when the document is not replaced", %{
      conn: conn,
      reception: reception
    } do
      conn = log_in_user(conn, reception)

      uploads_dir = Path.join([:code.priv_dir(:medcamp), "static", "uploads"])
      File.mkdir_p!(uploads_dir)
      old_path = Path.join(uploads_dir, "kept-birth-cert.pdf")
      File.write!(old_path, "kept file contents")

      patient =
        patient_fixture(%{
          "gender" => "Female",
          "birth_certificate_document" => "/uploads/kept-birth-cert.pdf"
        })

      {:ok, view, _html} = live(conn, ~p"/reception/patients/#{patient.id}/edit")

      view
      |> element("#patient-form")
      |> render_submit(%{
        "patient" => %{
          "first_name" => "Updated",
          "phone_number" => patient.phone_number,
          "date_of_birth" => Date.to_iso8601(patient.date_of_birth),
          "gender" => patient.gender,
          "home_address" => patient.home_address,
          "consent_agreement" => "true"
        }
      })

      updated = Patients.get_patient!(patient.id)
      assert updated.birth_certificate_document == "/uploads/kept-birth-cert.pdf"
      assert File.exists?(old_path)
    end
  end
end
