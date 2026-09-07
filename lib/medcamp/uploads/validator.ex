defmodule Medcamp.Uploads.Validator do
  @moduledoc """
  Shared upload validation for patient document uploads (birth certificates,
  national IDs). Used by both AddPatientComponent and EditPatientComponent
  so the two can't drift out of sync on what's considered a safe upload.
  """

  @allowed_extensions ~w(.pdf .png .jpg .jpeg)
  @allowed_content_types ["application/pdf", "image/png", "image/jpeg"]

  def validate_upload(entry, path) do
    extension =
      entry.client_name
      |> Path.extname()
      |> String.downcase()

    cond do
      extension not in @allowed_extensions ->
        {:error, :invalid_extension}

      entry.client_type not in @allowed_content_types ->
        {:error, :invalid_content_type}

      true ->
        with {:ok, file} <- :file.open(path, [:read, :binary]) do
          try do
            case :file.read(file, 8) do
              {:ok, header} ->
                case detect_file_type(header) do
                  {:ok, detected_type} when detected_type == entry.client_type ->
                    :ok

                  _ ->
                    {:error, :invalid_file_contents}
                end

              {:error, reason} ->
                {:error, reason}

              :eof ->
                {:error, :empty_file}
            end
          after
            :file.close(file)
          end
        end
    end
  end

  defp detect_file_type(<<0x89, ?P, ?N, ?G, 0x0D, 0x0A, 0x1A, 0x0A, _::binary>>) do
    {:ok, "image/png"}
  end

  defp detect_file_type(<<0xFF, 0xD8, 0xFF, _::binary>>) do
    {:ok, "image/jpeg"}
  end

  defp detect_file_type(<<?%, ?P, ?D, ?F, ?-, _::binary>>) do
    {:ok, "application/pdf"}
  end

  defp detect_file_type(_) do
    {:error, :unknown_file_type}
  end
end
