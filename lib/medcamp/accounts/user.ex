defmodule Medcamp.Accounts.User do
  use Ecto.Schema
  use Medcamp.Tenancy.Schema
  import Ecto.Changeset

  @roles ~w(admin doctor nurse pharmacist labtechnician)

  def roles, do: @roles

  schema "users" do
    tenant_field()

    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :utc_datetime
    field :name, :string
    field :image, :string
    field :otp, :string
    field :otp_expires_at, :utc_datetime
    field :experience, :string
    field :phone_number, :string
    field :id_number, :string
    field :license_number, :string
    field :role, :string, default: "doctor"
    field :is_superadmin, :boolean, default: false
    field :is_active, :boolean, default: true
    field :is_for_medical_camp, :boolean, default: false
    field :last_logged_in_at, :utc_datetime
    field :last_logged_out_at, :utc_datetime

    field :gsrn, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :role, :name, :gsrn, :otp, :is_for_medical_camp])
    |> validate_email(opts)
    |> validate_password(opts)
    |> validate_otp_pin_if_changed()
    |> validate_required([:name])
    |> validate_role()
    |> put_org_id()
  end

  def changeset(user, attrs, opts \\ []) do
    attrs = normalize_inserted_at(attrs)

    user
    |> cast(attrs, [
      :email,
      :password,
      :role,
      :name,
      :phone_number,
      :is_active,
      :is_for_medical_camp,
      :gsrn,
      :hashed_password,
      :otp,
      :otp_expires_at,
      :inserted_at
    ])
    |> validate_email(opts)
    |> validate_otp_pin_if_changed()
    |> validate_required([:name, :role])
    |> validate_role()
    |> put_org_id()
  end

  defp normalize_inserted_at(attrs) when is_map(attrs) do
    attrs
    |> normalize_inserted_at_key("inserted_at")
    |> normalize_inserted_at_key(:inserted_at)
  end

  defp normalize_inserted_at(attrs), do: attrs

  defp normalize_inserted_at_key(attrs, key) do
    case Map.fetch(attrs, key) do
      {:ok, value} -> put_normalized_inserted_at(attrs, key, value)
      :error -> attrs
    end
  end

  defp put_normalized_inserted_at(attrs, key, value) when is_binary(value) do
    value = String.trim(value)

    cond do
      value == "" ->
        Map.delete(attrs, key)

      true ->
        case datetime_local_to_utc(value) do
          {:ok, datetime} -> Map.put(attrs, key, datetime)
          :error -> attrs
        end
    end
  end

  defp put_normalized_inserted_at(attrs, _key, _value), do: attrs

  defp datetime_local_to_utc(value) do
    with {:ok, naive_datetime} <- parse_datetime_local(value) do
      {:ok,
       naive_datetime
       |> NaiveDateTime.add(-3 * 60 * 60, :second)
       |> DateTime.from_naive!("Etc/UTC")
       |> DateTime.truncate(:second)}
    end
  end

  defp parse_datetime_local(value) do
    value =
      if value =~ ~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/ do
        value <> ":00"
      else
        value
      end

    case NaiveDateTime.from_iso8601(value) do
      {:ok, naive_datetime} -> {:ok, NaiveDateTime.truncate(naive_datetime, :second)}
      {:error, _reason} -> :error
    end
  end

  defp validate_otp_pin_if_changed(%Ecto.Changeset{} = changeset) do
    otp_change = get_change(changeset, :otp)

    if is_nil(otp_change) do
      changeset
    else
      case normalize_otp_pin(otp_change) do
        {:ok, pin} -> put_change(changeset, :otp, pin)
        :error -> add_error(changeset, :otp, "must be a 4-digit numeric PIN")
      end
    end
  end

  defp normalize_otp_pin(otp) when is_integer(otp) do
    otp |> Integer.to_string() |> normalize_otp_pin()
  end

  defp normalize_otp_pin(otp) when is_binary(otp) do
    otp = String.trim(otp)

    if otp =~ ~r/^\d{1,4}$/ do
      {:ok, String.pad_leading(otp, 4, "0")}
    else
      :error
    end
  end

  defp normalize_otp_pin(_), do: :error

  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :name,
      :image,
      :experience,
      :license_number,
      :phone_number,
      :id_number
    ])
    |> validate_required([:name])
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 6, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Medcamp.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  defp validate_role(changeset) do
    validate_inclusion(changeset, :role, @roles)
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Medcamp.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end
