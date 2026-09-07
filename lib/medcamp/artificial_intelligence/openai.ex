defmodule Medcamp.ArtificialIntelligence.OpenAI do
  @moduledoc """
  Small wrapper around the OpenAI Chat Completions API.
  """

  @api_url "https://api.openai.com/v1/chat/completions"
  @default_model "gpt-5.4-mini"

  @transcription_url "https://api.openai.com/v1/audio/transcriptions"
  @default_transcription_model "gpt-4o-transcribe"

  def api_key do
    case System.get_env("OPENAI_API_KEY") do
      key when is_binary(key) and byte_size(key) > 0 -> {:ok, key}
      _ -> {:error, "OPENAI_API_KEY is not configured."}
    end
  end

  def request_to_gpt(context, prompt, opts \\ []) do
    with {:ok, api_key} <- fetch_api_key() do
      body =
        %{
          "model" =>
            Keyword.get(opts, :model) || System.get_env("OPENAI_MODEL") || @default_model,
          "messages" => [
            %{"role" => "system", "content" => context},
            %{"role" => "user", "content" => prompt}
          ]
        }
        |> maybe_put_json("reasoning_effort", Keyword.get(opts, :reasoning_effort))
        |> maybe_put_response_format(Keyword.get(opts, :response_schema))

      req_options = [
        headers: [
          {"Content-Type", "application/json"},
          {"Authorization", "Bearer #{api_key}"}
        ],
        json: body,
        retry: :transient,
        max_retries: 5,
        receive_timeout: 60_000
      ]

      case Req.post(@api_url, req_options) do
        {:ok, %{status: 200, body: %{"choices" => [%{"message" => %{"content" => content}} | _]}}} ->
          {:ok, String.trim(content)}

        {:ok, %{status: 200, body: %{"choices" => []}}} ->
          {:error, "AI did not return an analysis. Please try again."}

        {:ok, %{status: 400, body: body}} ->
          {:error, "AI request was rejected: #{extract_error_message(body)}"}

        {:ok, %{status: 401}} ->
          {:error, "AI service authorization failed. Check OPENAI_API_KEY."}

        {:ok, %{status: status, body: body}} ->
          {:error, "AI service error (#{status}): #{extract_error_message(body)}"}

        {:error, reason} ->
          {:error, "AI request failed: #{inspect(reason)}"}
      end
    end
  end

  def request_json_to_gpt(context, prompt, opts \\ []) do
    with {:ok, content} <- request_to_gpt(context, prompt, opts),
         {:ok, decoded} <- decode_json_response(content) do
      {:ok, decoded}
    end
  end

  @doc """
  Transcribes a recorded audio file to text using OpenAI's audio transcription API.

  `audio_path` must point to a readable audio file. Supported `opts`:

    * `:filename` - filename sent to the API (defaults to the basename of the path)
    * `:content_type` - MIME type of the upload (defaults to `"audio/webm"`)
    * `:prompt` - optional text to bias transcription (e.g. clinical terminology)
    * `:language` - optional ISO-639-1 language hint (e.g. `"en"`)

  The model can be overridden with the `OPENAI_TRANSCRIBE_MODEL` env var.

  Returns `{:ok, text}` or `{:error, message}`.
  """
  def transcribe_audio(audio_path, opts \\ []) do
    with {:ok, api_key} <- fetch_api_key(),
         {:ok, audio} <- File.read(audio_path) do
      filename = Keyword.get(opts, :filename) || Path.basename(audio_path)
      content_type = Keyword.get(opts, :content_type) || "audio/webm"
      model = System.get_env("OPENAI_TRANSCRIBE_MODEL") || @default_transcription_model

      parts =
        [
          model: model,
          file: {audio, filename: filename, content_type: content_type}
        ]
        |> maybe_put_part(:prompt, Keyword.get(opts, :prompt))
        |> maybe_put_part(:language, Keyword.get(opts, :language))

      req_options = [
        headers: [{"Authorization", "Bearer #{api_key}"}],
        form_multipart: parts,
        retry: :transient,
        max_retries: 2,
        receive_timeout: 120_000
      ]

      case Req.post(@transcription_url, req_options) do
        {:ok, %{status: 200, body: %{"text" => text}}} when is_binary(text) ->
          {:ok, String.trim(text)}

        {:ok, %{status: 400, body: body}} ->
          {:error, "Transcription was rejected: #{extract_error_message(body)}"}

        {:ok, %{status: 401}} ->
          {:error, "AI service authorization failed. Check OPENAI_API_KEY."}

        {:ok, %{status: status, body: body}} ->
          {:error, "Transcription service error (#{status}): #{extract_error_message(body)}"}

        {:error, reason} ->
          {:error, "Transcription request failed: #{inspect(reason)}"}
      end
    else
      {:error, reason} when is_atom(reason) ->
        {:error, "Could not read audio file: #{:file.format_error(reason)}"}

      other ->
        other
    end
  end

  defp maybe_put_part(parts, _key, value) when value in [nil, ""], do: parts
  defp maybe_put_part(parts, key, value), do: parts ++ [{key, value}]

  defp maybe_put_json(body, _key, value) when value in [nil, ""], do: body
  defp maybe_put_json(body, key, value), do: Map.put(body, key, value)

  defp maybe_put_response_format(body, nil), do: body

  defp maybe_put_response_format(body, schema) when is_map(schema) do
    Map.put(body, "response_format", %{
      "type" => "json_schema",
      "json_schema" => %{
        "name" => "medcamp_structured_response",
        "strict" => true,
        "schema" => schema
      }
    })
  end

  defp fetch_api_key, do: api_key()

  defp extract_error_message(%{"error" => %{"message" => message}}) when is_binary(message),
    do: message

  defp extract_error_message(%{"error" => error}) when is_binary(error), do: error
  defp extract_error_message(body) when is_binary(body), do: body
  defp extract_error_message(body), do: inspect(body)

  defp decode_json_response(content) do
    cleaned =
      content
      |> String.trim()
      |> String.replace(~r/\A```json\s*/i, "")
      |> String.replace(~r/\A```\s*/i, "")
      |> String.replace(~r/\s*```\z/, "")
      |> String.trim()

    case Jason.decode(cleaned) do
      {:ok, decoded} when is_map(decoded) ->
        {:ok, decoded}

      {:ok, _decoded} ->
        {:error, "AI returned JSON in an unexpected format."}

      {:error, error} ->
        {:error, "AI returned invalid JSON: #{Exception.message(error)}"}
    end
  end
end
