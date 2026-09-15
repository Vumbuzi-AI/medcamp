defmodule Medcamp.Validation do
  @moduledoc """
  Shared normalisation and changeset validation helpers for common inputs.
  """

  import Ecto.Changeset

  @email_format ~r/^[^@,;\s]+@[^@,;\s]+\.[^@,;\s]+$/

  def normalize_email(value) when is_binary(value) do
    case value |> String.trim() |> String.downcase() do
      "" -> nil
      email -> email
    end
  end

  def normalize_email(value), do: value

  def validate_email(changeset, field \\ :email, opts \\ []) do
    changeset
    |> update_change(field, &normalize_email/1)
    |> validate_format(field, @email_format,
      message: Keyword.get(opts, :message, "must be a valid email address")
    )
  end

  # Deliberately light-touch: accepts common phone punctuation, rejects letters,
  # and uses digit length as the actual validity check.
  def validate_phone_number(changeset, field) do
    validate_change(changeset, field, fn field, phone ->
      if is_binary(phone) and String.trim(phone) != "" do
        digits = String.replace(phone, ~r/[^\d]/, "")

        cond do
          not Regex.match?(~r/^\+?[\d\s().-]+$/, phone) ->
            [{field, "is not a valid phone number"}]

          String.length(digits) < 7 or String.length(digits) > 15 ->
            [{field, "is not a valid phone number"}]

          true ->
            []
        end
      else
        []
      end
    end)
  end
end
