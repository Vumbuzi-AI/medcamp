defmodule Medcamp.Appointments.PublicBooking do
  use Ecto.Schema
  import Ecto.Changeset

  @service_options [
    {"Outpatient", "outpatient"},
    {"Emergency", "emergency"},
    {"Maternal & Child", "maternal"},
    {"Diagnostics", "diagnostics"}
  ]

  @service_labels Map.new(@service_options, fn {label, value} -> {value, label} end)

  embedded_schema do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :phone_number, :string
    field :service, :string
    field :date, :date
    field :time, :time
    field :message, :string
  end

  def service_options, do: @service_options

  def service_label(service) when is_binary(service) do
    Map.get(@service_labels, service, service)
  end

  def service_label(_service), do: nil

  def changeset(public_booking, attrs \\ %{}) do
    public_booking
    |> cast(attrs, [
      :first_name,
      :last_name,
      :email,
      :phone_number,
      :service,
      :date,
      :time,
      :message
    ])
    |> update_change(:first_name, &normalize_text/1)
    |> update_change(:last_name, &normalize_text/1)
    |> update_change(:email, &normalize_email/1)
    |> update_change(:phone_number, &normalize_phone_number/1)
    |> update_change(:message, &normalize_text/1)
    |> validate_required([
      :first_name,
      :last_name,
      :email,
      :phone_number,
      :service,
      :date,
      :message
    ])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email address")
    |> validate_inclusion(:service, Enum.map(@service_options, &elem(&1, 1)))
  end

  defp normalize_text(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp normalize_text(value), do: value

  defp normalize_email(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> case do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp normalize_email(value), do: value

  defp normalize_phone_number(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp normalize_phone_number(value), do: value
end
