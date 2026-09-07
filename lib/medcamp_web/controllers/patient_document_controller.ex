defmodule MedcampWeb.PatientDocumentController do
  use MedcampWeb, :controller

  require Logger

  alias Medcamp.Patients

  @authorized_roles ~w(admin doctor reception nurse)

  @document_types %{
    "birth_certificate" => :birth_certificate,
    "national_id" => :national_id,
    "passport" => :passport,
    "insurance_card" => :insurance_card,
    "lab_report" => :lab_report,
    "prescription" => :prescription,
    "referral_letter" => :referral_letter,
    "xray" => :xray,
    "mri" => :mri,
    "other" => :other
  }

  def show(conn, %{
        "patient_id" => patient_id,
        "document_type" => document_type
      }) do
    current_user = conn.assigns.current_user

    with true <- current_user.role in @authorized_roles,
         {:ok, document_type} <- parse_document_type(document_type),
         document when not is_nil(document) <-
           Patients.get_patient_document(patient_id, document_type),
         {:ok, file_path} <- build_file_path(document.file_path),
         true <- File.exists?(file_path) do
      conn
      |> put_resp_content_type(document.content_type || "application/octet-stream")
      |> put_resp_header(
        "content-disposition",
        ~s(inline; filename="#{document.document_name}")
      )
      |> send_file(200, file_path)
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> text("Forbidden")

      {:error, :invalid_document_type} ->
        conn
        |> put_status(:bad_request)
        |> text("Invalid document type")

      {:error, :file_not_found} ->
        conn
        |> put_status(:not_found)
        |> text("Document file not found")

      nil ->
        conn
        |> put_status(:not_found)
        |> text("Document not found")

      error ->
        Logger.error("Failed serving patient document: #{inspect(error)}")

        conn
        |> put_status(:internal_server_error)
        |> text("Unable to retrieve document")
    end
  end

  def show(conn, _params) do
    conn
    |> put_status(:not_found)
    |> text("Not found")
  end

  defp parse_document_type(type) do
    case Map.fetch(@document_types, type) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, :invalid_document_type}
    end
  end

  defp build_file_path(file_path) when is_binary(file_path) do
    filename = Path.basename(file_path)

    absolute_path =
      Path.join([
        File.cwd!(),
        "priv",
        "uploads",
        "patients",
        filename
      ])

    if File.exists?(absolute_path) do
      {:ok, absolute_path}
    else
      {:error, :file_not_found}
    end
  end
end
