defmodule Medcamp.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo
  alias Medcamp.Patients

  alias Medcamp.Accounts.{User, UserToken, UserNotifier}

  # Lookups that run before we know which organisation we are in - logging in,
  # a reset-password token, a scanned GSRN - plus the two identifiers that are
  # unique across the whole system rather than per organisation (email, OTP).
  # Everything else in this module is filtered automatically by
  # `Medcamp.Repo.prepare_query/3`.
  @unscoped [skip_org_id: true]

  # In your Accounts context (lib/medcamp/accounts.ex)

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, [email: email], @unscoped)
  end

  @doc """
  Finds a user by email within the current organisation.

  For the admin-facing lookups, where reaching a user in another organisation
  would be a tenancy breach - unlike `get_user_by_email/1`, which is the
  pre-login path and has to search everywhere.
  """
  def get_organisation_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a medical-camp-enabled user by OTP pin.
  """
  def get_user_for_medical_camp_by_otp(otp) when is_binary(otp) do
    Repo.get_by(User, [otp: otp], @unscoped)
  end

  @doc """
  Gets an admin user by a 4-digit OTP pin.
  """
  def get_admin_by_otp(otp) when is_binary(otp) do
    with {:ok, normalized_otp} <- normalize_lookup_otp(otp) do
      Repo.get_by(User, [otp: normalized_otp, role: "admin"], @unscoped)
    else
      :error -> nil
    end
  end

  @doc """
  Gets an active support staff user by a 4-digit OTP pin.

  Used by the PIN-gated mobile meal entry page so support staff can sign in
  with their PIN and record meals without a full login.
  """
  def get_support_staff_by_otp(otp) when is_binary(otp) do
    with {:ok, normalized_otp} <- normalize_lookup_otp(otp) do
      Repo.get_by(
        User,
        [otp: normalized_otp, role: "support staff", is_active: true],
        @unscoped
      )
    else
      :error -> nil
    end
  end

  # Add these functions to your existing Medcamp.Accounts module

  @doc """
  Returns list of users with housekeeping roles.
  """
  def list_housekeeping_staff do
    User
    |> where([u], u.is_active == true)
    |> where([u], u.role in ["housekeeping", "cleaner", "staff"])
    |> order_by([u], asc: u.name)
    |> Repo.all()
  end

  @doc """
  Returns list of staff names (for dropdown filters).
  """
  def list_staff_names do
    User
    |> where([u], u.is_active == true and not is_nil(u.name))
    |> select([u], u.name)
    |> distinct(true)
    |> order_by([u], asc: u.name)
    |> Repo.all()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Records the user's last login timestamp.
  """
  def update_user_last_logged_in(%User{} = user) do
    user
    |> Ecto.Changeset.change(%{
      last_logged_in_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.update()
  end

  @doc """
  Records the user's last logout timestamp.
  """
  def update_user_last_logged_out(%User{} = user) do
    user
    |> Ecto.Changeset.change(%{
      last_logged_out_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.update()
  end

  def list_active_users do
    Repo.all(from u in User, where: u.is_active == true)
    |> Enum.map(fn user -> {user.name, user.id} end)
  end

  defp normalize_lookup_otp(otp) when is_binary(otp) do
    otp = String.trim(otp)

    if otp =~ ~r/^\d{1,4}$/ do
      {:ok, String.pad_leading(otp, 4, "0")}
    else
      :error
    end
  end

  def list_poeple_in_same_department_as_current_user(current_user) do
    Repo.all(
      from u in User,
        where:
          like(u.email, "%@glocalhealth%") and u.role == ^current_user.role and
            u.is_active == true and u.id != ^current_user.id,
        select: u.name
    )
  end

  def replace_all_lab_technician_role do
    Repo.all(from u in User, where: u.role == "lab_technician")
    |> Enum.each(fn user ->
      user
      |> Ecto.Changeset.change(role: "labtechnician")
      |> Repo.update!()
    end)
  end

  def list_users do
    users_list_query(%{})
    |> Repo.all()
  end

  def list_users_paginated(filters \\ %{}, page \\ 1, per_page \\ 20) do
    users_list_query(filters)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
  end

  def count_users(filters \\ %{}) do
    users_count_query(filters)
    |> select([u], count(u.id))
    |> Repo.one()
  end

  def filter_users(filters \\ %{}) do
    users_list_query(filters)
    |> Repo.all()
  end

  def filter_users_paginated(filters \\ %{}, page \\ 1, per_page \\ 20) do
    users_list_query(filters)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
  end

  defp users_list_query(filters) do
    users_base_query()
    |> order_by([u], desc: u.inserted_at)
    |> apply_active_filter(filters[:is_active])
    |> apply_search_filter(filters[:search])
    |> apply_role_filter(filters[:role])
  end

  defp users_count_query(filters) do
    users_base_query()
    |> apply_active_filter(filters[:is_active])
    |> apply_search_filter(filters[:search])
    |> apply_role_filter(filters[:role])
  end

  defp users_base_query do
    from(u in User)
  end

  defp apply_active_filter(query, nil), do: query
  defp apply_active_filter(query, ""), do: query

  defp apply_active_filter(query, "true") do
    where(query, [u], u.is_active == true)
  end

  defp apply_active_filter(query, "false") do
    where(query, [u], u.is_active == false or is_nil(u.is_active))
  end

  defp apply_active_filter(query, _), do: query

  defp apply_search_filter(query, nil), do: query
  defp apply_search_filter(query, ""), do: query

  defp apply_search_filter(query, search) when is_binary(search) do
    search = "%#{String.trim(search)}%"
    where(query, [u], ilike(u.name, ^search) or ilike(u.email, ^search))
  end

  defp apply_search_filter(query, _), do: query

  defp apply_role_filter(query, nil), do: query
  defp apply_role_filter(query, ""), do: query

  defp apply_role_filter(query, role) when is_binary(role) do
    where(query, [u], u.role == ^role)
  end

  defp apply_role_filter(query, _), do: query

  @doc """
  Finds a user by their GS1 GSRN.

  GSRNs are globally unique, so this deliberately searches across every
  organisation - it is how the public `/8017/:gsrn` routes resolve which
  organisation they are dealing with in the first place.
  """
  def get_user_by_gsrn(gsrn) when is_binary(gsrn) do
    Repo.all(from(u in User, where: u.gsrn == ^gsrn), @unscoped)
    |> List.first()
  end

  def change_user_profile(%User{} = user, attrs \\ %{}) do
    User.profile_changeset(user, attrs)
  end

  def update_user_profile(user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.audited_update()
  end

  def list_users_for_selection do
    Repo.all(
      from u in User,
        where: like(u.email, "%@glocalhealth%") and u.is_active == true,
        select: {u.email, u.id}
    )
  end

  @spec list_all_doctors() :: any()
  def list_all_doctors do
    Repo.all(from u in User, where: u.role == "doctor" and u.is_active == true)
  end

  def list_all_doctors_for_selection do
    Repo.all(
      from u in User,
        where: u.role == "doctor" and u.is_active == true,
        select: {u.name, u.id}
    )
  end

  def change_user(user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def get_reset_password_link_for_user(user) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    encoded_token
  end

  def create_user(attrs \\ %{}) do
    attrs =
      attrs
      |> put_gsrn()
      |> ensure_otp()

    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a user.

  Returns `{:error, :user_has_related_records}` when the user is still
  referenced by records that prevent deletion.
  """
  def delete_user(%User{} = user, opts \\ []) do
    Repo.audited_delete(user, opts)
  rescue
    error in Ecto.ConstraintError ->
      if error.type == :foreign_key do
        {:error, :user_has_related_records}
      else
        reraise error, __STACKTRACE__
      end
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, [email: email], @unscoped)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a user by id without an organisation filter.

  Only for the PIN-gated external medical camp pages, which are reached
  without a login and so have no organisation in scope yet - the user found
  here is what establishes it.
  """
  def get_user_across_organisations(id), do: Repo.get(User, id, @unscoped)

  @doc """
  Gets a user by id mid-login, before an organisation is in scope.

  The OTP challenge and the one-time login token both carry a user id that has
  already been verified by a signed session or `Phoenix.Token`, so this is a
  lookup of an identity we have established but not yet entered the tenant of.
  """
  def get_login_user!(id), do: Repo.get!(User, id, @unscoped)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    attrs =
      attrs
      |> put_gsrn()
      |> ensure_otp()

    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  defp ensure_otp(attrs) when is_map(attrs) do
    otp = Map.get(attrs, "otp") || Map.get(attrs, :otp)

    if valid_otp_pin?(otp) do
      attrs
    else
      otp_value = generate_unique_otp_pin4()

      if has_atom_keys?(attrs) do
        Map.put(attrs, :otp, otp_value)
      else
        Map.put(attrs, "otp", otp_value)
      end
    end
  end

  defp put_gsrn(attrs) when is_map(attrs) do
    key = if has_atom_keys?(attrs), do: :gsrn, else: "gsrn"
    Map.put(attrs, key, Patients.get_available_gsrn())
  end

  defp has_atom_keys?(map) do
    map |> Map.keys() |> Enum.any?(&is_atom/1)
  end

  defp valid_otp_pin?(otp) when is_binary(otp) do
    otp =~ ~r/^\d{4}$/
  end

  defp valid_otp_pin?(_), do: false

  defp generate_unique_otp_pin4(attempts \\ 50) do
    otp =
      Enum.reduce_while(1..attempts, nil, fn _, _acc ->
        candidate = generate_otp_pin4()

        # The OTP pin is a login credential with a system-wide unique index,
        # so the candidate has to be checked against every organisation.
        if Repo.get_by(User, [otp: candidate], @unscoped) == nil do
          {:halt, candidate}
        else
          {:cont, nil}
        end
      end)

    otp || raise "Failed to generate a unique 4-digit OTP pin after #{attempts} attempts"
  end

  defp generate_otp_pin4 do
    # Produces a number in [0, 9999], then pads with leading zeros (e.g. 42 -> "0042").
    <<n::unsigned-integer-size(16)>> = :crypto.strong_rand_bytes(2)
    pin_int = rem(n, 10_000)
    pin_int |> Integer.to_string() |> String.pad_leading(4, "0")
  end
end
