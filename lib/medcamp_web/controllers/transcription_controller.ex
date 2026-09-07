defmodule MedcampWeb.TranscriptionController do
  @moduledoc """
  Receives short audio recordings from the clinical forms and returns English
  text via OpenAI, so doctors can dictate in supported languages into free-text
  fields.

  Gated by the authenticated-doctor pipeline in the router.
  """
  use MedcampWeb, :controller

  alias Medcamp.ArtificialIntelligence.VoiceDictation

  def create(conn, %{"audio" => %Plug.Upload{} = upload, "language" => language}) do
    result =
      VoiceDictation.transcribe_to_english(
        upload.path,
        language,
        filename: upload.filename || "recording.webm",
        content_type: upload.content_type || "audio/webm"
      )

    case result do
      {:ok, text} ->
        json(conn, %{text: text})

      {:error, message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: message})
    end
  end

  def create(conn, %{"audio" => %Plug.Upload{}}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "No supported dictation language provided."})
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "No audio file provided."})
  end
end
