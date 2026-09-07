defmodule Medcamp.Patients.Patient do
  use Ecto.Schema
  import Ecto.Changeset

  alias Medcamp.Patients.PatientDocument

  schema "patients" do
    field :first_name, :string
    field :middle_name, :string
    field :last_name, :string
    field :email, :string
    field :phone_number, :string
    field :national_id, :string
    field :national_id_document, :string
    field :birth_certificate_number, :string
    field :birth_certificate_document, :string
    field :date_of_birth, :date
    field :gender, :string
    field :gsrn, :string
    field :pin, :integer

    field :consent_agreement, :boolean, default: false

    field :insurance_scheme, :string
    field :insurance_number, :string
    field :insurance_cover_limit, :integer
    field :insurance_company, :string
    field :has_insurance, :boolean, default: false

    field :is_for_medical_camp, :boolean, default: false
    field :medical_camp_name, :string
    field :patient_type, :string

    field :home_address, :string

    field :emergency_contact_relationship, :string
    field :emergency_contact_phone_number, :string
    field :emergency_contact_name, :string

    # Virtual field
    field :age, :integer, virtual: true

    belongs_to :creator, Medcamp.Accounts.User, foreign_key: :creator_id

    has_many :documents, PatientDocument,
      foreign_key: :patient_id,
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(patient, attrs) do
    patient
    |> cast(attrs, [
      :first_name,
      :middle_name,
      :last_name,
      :insurance_company,
      :national_id,
      :national_id_document,
      :birth_certificate_number,
      :birth_certificate_document,
      :email,
      :pin,
      :phone_number,
      :date_of_birth,
      :gender,
      :emergency_contact_name,
      :emergency_contact_phone_number,
      :insurance_scheme,
      :insurance_number,
      :insurance_cover_limit,
      :has_insurance,
      :is_for_medical_camp,
      :medical_camp_name,
      :patient_type,
      :home_address,
      :emergency_contact_relationship,
      :consent_agreement,
      :gsrn,
      :creator_id
    ])
    |> validate_required([
      :first_name,
      :phone_number,
      :date_of_birth,
      :gender,
      :home_address,
      :creator_id
    ])
    |> validate_phone_number(:phone_number)
    |> validate_phone_number(:emergency_contact_phone_number)
    |> validate_format(
      :email,
      ~r/^[^\s]+@[^\s]+\.[^\s]+$/,
      message: "must be a valid email address"
    )
    |> validate_length(:first_name, min: 2)
    |> validate_length(:last_name, min: 2)
    |> validate_length(:home_address, min: 3)
    |> validate_length(:emergency_contact_name, min: 2)
    |> validate_number(
      :pin,
      greater_than_or_equal_to: 1000,
      less_than_or_equal_to: 9999
    )
    |> validate_date_of_birth_not_in_future()
    |> foreign_key_constraint(:creator_id)
  end

  defp validate_date_of_birth_not_in_future(changeset) do
    validate_change(changeset, :date_of_birth, fn :date_of_birth, date ->
      case date do
        %Date{} ->
          if Date.compare(date, Date.utc_today()) == :gt do
            [date_of_birth: "cannot be in the future"]
          else
            []
          end

        _ ->
          []
      end
    end)
  end

  # Deliberately lenient: catches obvious garbage (letters, way too
  # short/long) without enforcing one specific national format, since real
  # patient/contact numbers may be local (07...) or international (+254...).
  defp validate_phone_number(changeset, field) do
    validate_change(changeset, field, fn field, phone ->
      if is_binary(phone) and String.trim(phone) != "" do
        digits = String.replace(phone, ~r/[^\d]/, "")

        cond do
          not Regex.match?(~r/^\+?[\d\s-]+$/, phone) ->
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

  def public_booking_changeset(patient, attrs) do
    patient
    |> cast(attrs, [
      :first_name,
      :last_name,
      :email,
      :phone_number
    ])
    |> update_change(:first_name, &normalize_text/1)
    |> update_change(:last_name, &normalize_text/1)
    |> update_change(:email, &normalize_email/1)
    |> update_change(:phone_number, &normalize_text/1)
    |> validate_required([
      :first_name,
      :last_name,
      :email,
      :phone_number
    ])
  end

  def calculate_age(nil), do: nil

  def calculate_age(date_of_birth) do
    today = Date.utc_today()
    years = today.year - date_of_birth.year

    if Date.compare(today, %{date_of_birth | year: today.year}) == :lt do
      years - 1
    else
      years
    end
  end

  def with_age(patient) do
    %{patient | age: calculate_age(patient.date_of_birth)}
  end

  defp normalize_text(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp normalize_text(value), do: value

  defp normalize_email(value) when is_binary(value) do
    case value |> String.trim() |> String.downcase() do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp normalize_email(value), do: value
end
