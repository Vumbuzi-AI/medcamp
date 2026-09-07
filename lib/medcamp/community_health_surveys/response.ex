defmodule Medcamp.CommunityHealthSurveys.Response do
  use Ecto.Schema
  import Ecto.Changeset

  @yes_no_options ["Yes", "No"]
  @insurance_cover_options ["SHA", "Employer Medical Cover", "Private Insurance", "Other"]
  @insurance_provider_options [
    "AAR",
    "Jubilee",
    "CIC",
    "Britam",
    "APA",
    "Madison",
    "Resolution",
    "SHA",
    "Other"
  ]
  @preferred_facility_options [
    "Glocal Healthcare Centre of Excellence",
    "Health Centre",
    "Dispensary",
    "Private Clinic",
    "Hospital",
    "Other"
  ]
  @facility_choice_reason_options [
    "Near Home",
    "Affordable",
    "Insurance Accepted",
    "Good Service",
    "Qualified Doctors",
    "Laboratory Services",
    "Pharmacy Available",
    "Open Convenient Hours",
    "Other"
  ]
  @experience_rating_options ["Excellent", "Good", "Fair", "Poor", "Not Applicable"]
  @non_visit_reason_options [
    "Not Aware of Facility",
    "Prefer Another Facility",
    "Insurance Not Accepted",
    "Cost Concerns",
    "Too Far",
    "Other",
    "Not Applicable"
  ]
  @likely_service_options [
    "General Outpatient Clinic",
    "Child Welfare & Immunization",
    "Antenatal Care",
    "Maternity Services",
    "Laboratory Services",
    "Pharmacy Services",
    "Dental Services",
    "Specialist Clinics",
    "Chronic Disease Clinics",
    "Health Screening Services",
    "Home Care Services"
  ]
  @household_condition_options [
    "Hypertension",
    "Diabetes",
    "Asthma",
    "Heart Disease",
    "Other Chronic Condition",
    "None"
  ]
  @preferred_contact_method_options ["WhatsApp", "SMS", "Phone Call", "Email"]

  @required_fields [
    :surveyor_name,
    :survey_date,
    :house_number,
    :adults_count,
    :children_count,
    :has_health_insurance
  ]

  @public_required_fields [
    :survey_date,
    :house_number,
    :adults_count,
    :children_count,
    :has_health_insurance
  ]

  @multi_select_fields [
    :insurance_covers,
    :insurance_providers,
    :facility_choice_reasons,
    :likely_services,
    :household_conditions
  ]

  schema "community_health_survey_responses" do
    field :surveyor_name, :string
    field :survey_date, :date
    field :house_number, :string
    field :adults_count, :integer, default: 0
    field :children_count, :integer, default: 0
    field :total_household_members, :integer, default: 0
    field :has_health_insurance, :string
    field :insurance_covers, {:array, :string}, default: []
    field :insurance_providers, {:array, :string}, default: []
    field :insurance_provider_other, :string
    field :preferred_facility_type, :string
    field :preferred_facility_other, :string
    field :preferred_facility_name, :string
    field :facility_choice_reasons, {:array, :string}, default: []
    field :visited_glocal, :string
    field :glocal_experience_rating, :string
    field :glocal_non_visit_reason, :string
    field :likely_services, {:array, :string}, default: []
    field :household_conditions, {:array, :string}, default: []
    field :interested_in_screenings, :string
    field :wants_updates, :string
    field :preferred_contact_method, :string
    field :contact_number, :string

    timestamps(type: :utc_datetime)
  end

  def yes_no_options, do: @yes_no_options
  def insurance_cover_options, do: @insurance_cover_options
  def insurance_provider_options, do: @insurance_provider_options
  def preferred_facility_options, do: @preferred_facility_options
  def facility_choice_reason_options, do: @facility_choice_reason_options
  def experience_rating_options, do: @experience_rating_options
  def non_visit_reason_options, do: @non_visit_reason_options
  def likely_service_options, do: @likely_service_options
  def household_condition_options, do: @household_condition_options
  def preferred_contact_method_options, do: @preferred_contact_method_options

  def changeset(response, attrs, required_fields \\ @required_fields) do
    response
    |> cast(attrs, [
      :surveyor_name,
      :survey_date,
      :house_number,
      :adults_count,
      :children_count,
      :total_household_members,
      :has_health_insurance,
      :insurance_covers,
      :insurance_providers,
      :insurance_provider_other,
      :preferred_facility_type,
      :preferred_facility_other,
      :preferred_facility_name,
      :facility_choice_reasons,
      :visited_glocal,
      :glocal_experience_rating,
      :glocal_non_visit_reason,
      :likely_services,
      :household_conditions,
      :interested_in_screenings,
      :wants_updates,
      :preferred_contact_method,
      :contact_number
    ])
    |> normalize_multi_selects()
    |> compute_total_household_members()
    |> normalize_conditionals()
    |> normalize_optional_strings([:surveyor_name])
    |> validate_required(required_fields)
    |> validate_length_if_present(:surveyor_name, min: 2, max: 120)
    |> validate_length(:house_number, min: 1, max: 120)
    |> validate_length(:preferred_facility_name, max: 160)
    |> validate_number(:adults_count, greater_than_or_equal_to: 0, less_than_or_equal_to: 5)
    |> validate_number(:children_count, greater_than_or_equal_to: 0, less_than_or_equal_to: 5)
    |> validate_yes_no(:has_health_insurance)
    |> validate_yes_no_if_present(:visited_glocal)
    |> validate_yes_no_if_present(:interested_in_screenings)
    |> validate_yes_no_if_present(:wants_updates)
    |> validate_option_subset(:insurance_covers, @insurance_cover_options)
    |> validate_option_subset(:insurance_providers, @insurance_provider_options)
    |> validate_option_subset(:facility_choice_reasons, @facility_choice_reason_options)
    |> validate_option_subset(:likely_services, @likely_service_options)
    |> validate_option_subset(:household_conditions, @household_condition_options)
    |> validate_inclusion_if_present(:preferred_facility_type, @preferred_facility_options)
    |> validate_inclusion_if_present(:glocal_experience_rating, @experience_rating_options)
    |> validate_inclusion_if_present(:glocal_non_visit_reason, @non_visit_reason_options)
    |> validate_inclusion_if_present(
      :preferred_contact_method,
      @preferred_contact_method_options
    )
    |> validate_max_selected(:facility_choice_reasons, 3, "Select up to 3 reasons")
    |> validate_household_conditions()
    |> validate_insurance_fields()
    |> validate_contact_preferences()
    |> validate_contact_number()
  end

  def public_changeset(response, attrs) do
    changeset(response, attrs, @public_required_fields)
  end

  def valid_contact_number?(nil), do: false
  def valid_contact_number?(""), do: false

  def valid_contact_number?(value) when is_binary(value) do
    Regex.match?(~r/^\+?[0-9\s-]{9,20}$/, String.trim(value))
  end

  defp normalize_multi_selects(changeset) do
    Enum.reduce(@multi_select_fields, changeset, fn field, acc ->
      update_change(acc, field, &normalize_string_list/1)
    end)
  end

  defp normalize_string_list(nil), do: []

  defp normalize_string_list(values) when is_list(values) do
    values
    |> Enum.map(&to_string/1)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp normalize_optional_strings(changeset, fields) do
    Enum.reduce(fields, changeset, fn field, acc ->
      update_change(acc, field, &blank_string_to_nil/1)
    end)
  end

  defp blank_string_to_nil(nil), do: nil

  defp blank_string_to_nil(value) when is_binary(value) do
    value = String.trim(value)
    if value == "", do: nil, else: value
  end

  defp blank_string_to_nil(value), do: value

  defp compute_total_household_members(changeset) do
    adults = get_field(changeset, :adults_count) || 0
    children = get_field(changeset, :children_count) || 0

    put_change(changeset, :total_household_members, adults + children)
  end

  defp normalize_conditionals(changeset) do
    changeset
    |> maybe_clear_insurance_fields()
    |> maybe_clear_facility_other()
    |> maybe_clear_visit_fields()
    |> maybe_clear_contact_fields()
  end

  defp maybe_clear_insurance_fields(changeset) do
    case get_field(changeset, :has_health_insurance) do
      "Yes" ->
        if "Other" in (get_field(changeset, :insurance_providers) || []) do
          changeset
        else
          put_change(changeset, :insurance_provider_other, nil)
        end

      _ ->
        changeset
        |> put_change(:insurance_covers, [])
        |> put_change(:insurance_providers, [])
        |> put_change(:insurance_provider_other, nil)
    end
  end

  defp maybe_clear_facility_other(changeset) do
    if get_field(changeset, :preferred_facility_type) == "Other" do
      changeset
    else
      put_change(changeset, :preferred_facility_other, nil)
    end
  end

  defp maybe_clear_visit_fields(changeset) do
    case get_field(changeset, :visited_glocal) do
      "Yes" -> put_change(changeset, :glocal_non_visit_reason, nil)
      "No" -> put_change(changeset, :glocal_experience_rating, nil)
      _ -> changeset
    end
  end

  defp maybe_clear_contact_fields(changeset) do
    if get_field(changeset, :wants_updates) == "Yes" do
      changeset
    else
      changeset
      |> put_change(:preferred_contact_method, nil)
      |> put_change(:contact_number, nil)
    end
  end

  defp validate_yes_no(changeset, field) do
    validate_inclusion(changeset, field, @yes_no_options)
  end

  defp validate_yes_no_if_present(changeset, field) do
    validate_inclusion_if_present(changeset, field, @yes_no_options)
  end

  defp validate_length_if_present(changeset, field, opts) do
    case get_field(changeset, field) do
      nil -> changeset
      "" -> changeset
      _value -> validate_length(changeset, field, opts)
    end
  end

  defp validate_option_subset(changeset, field, allowed_values) do
    values = get_field(changeset, field) || []

    case Enum.find(values, &(&1 not in allowed_values)) do
      nil -> changeset
      _ -> add_error(changeset, field, "contains an invalid selection")
    end
  end

  defp validate_inclusion_if_present(changeset, field, allowed_values) do
    case get_field(changeset, field) do
      nil -> changeset
      "" -> changeset
      _value -> validate_inclusion(changeset, field, allowed_values, message: "is invalid")
    end
  end

  defp validate_required_selection(changeset, field, message) do
    if Enum.empty?(get_field(changeset, field) || []) do
      add_error(changeset, field, message)
    else
      changeset
    end
  end

  defp validate_max_selected(changeset, field, max_count, message) do
    if length(get_field(changeset, field) || []) > max_count do
      add_error(changeset, field, message)
    else
      changeset
    end
  end

  defp validate_household_conditions(changeset) do
    conditions = get_field(changeset, :household_conditions) || []

    if "None" in conditions and length(conditions) > 1 do
      add_error(
        changeset,
        :household_conditions,
        "\"None\" cannot be combined with other conditions"
      )
    else
      changeset
    end
  end

  defp validate_insurance_fields(changeset) do
    if get_field(changeset, :has_health_insurance) == "Yes" do
      changeset
      |> validate_required_selection(:insurance_covers, "Select at least one insurance cover")
      |> validate_required_selection(:insurance_providers, "Select at least one provider")
      |> validate_other_provider()
    else
      changeset
    end
  end

  defp validate_other_provider(changeset) do
    if "Other" in (get_field(changeset, :insurance_providers) || []) do
      changeset
      |> validate_required([:insurance_provider_other])
      |> validate_length(:insurance_provider_other, min: 2, max: 120)
    else
      changeset
    end
  end

  defp validate_contact_preferences(changeset) do
    changeset =
      if get_field(changeset, :preferred_facility_type) == "Other" do
        changeset
        |> validate_required([:preferred_facility_other])
        |> validate_length(:preferred_facility_other, min: 2, max: 120)
      else
        changeset
      end

    changeset
  end

  defp validate_contact_number(changeset) do
    case get_field(changeset, :contact_number) do
      nil ->
        changeset

      "" ->
        changeset

      value ->
        if valid_contact_number?(value) do
          put_change(changeset, :contact_number, String.trim(value))
        else
          add_error(changeset, :contact_number, "must be a valid phone number")
        end
    end
  end
end
