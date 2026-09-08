defmodule Medcamp.Scheduler do
  @moduledoc """
  Bootstraps a usable set of camp logins on first boot.

  A medical camp is stood up from an empty database on the morning of the
  camp, so the system ships with one account per role rather than leaving an
  operator unable to log in. Existing accounts are never touched, and the
  whole step is skipped in tests.

  These are convenience credentials, not a security boundary: change the
  passwords (or delete the accounts) before running a real camp.
  """

  use GenServer
  alias Medcamp.Accounts
  alias Medcamp.Organisations
  alias Medcamp.Tenancy

  @default_password "123456"

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    unless skip_bootstrap?() do
      spawn(fn -> maybe_create_default_users() end)
    end

    {:ok, state}
  end

  defp skip_bootstrap? do
    Code.ensure_loaded?(Mix) and Mix.env() == :test
  end

  defp maybe_create_default_users do
    # A spawned process starts with an empty process dictionary, so the
    # organisation these accounts belong to has to be established here - and
    # created first, if this really is a brand new database.
    organisation = default_organisation()

    Tenancy.with_org(organisation.id, fn -> create_missing_users() end)
  end

  defp create_missing_users do
    for user <- default_users(), is_nil(Accounts.get_user_by_email(user["email"])) do
      Accounts.create_user(user)
    end
  end

  defp default_organisation do
    case Organisations.get_organisation_by_slug("default") do
      nil ->
        {:ok, organisation} =
          Organisations.create_organisation(%{
            "name" => "Medcamp",
            "slug" => "default"
          })

        organisation

      organisation ->
        organisation
    end
  end

  defp default_users do
    for {email, name, role} <- [
          {"admin@gmail.com", "Admin", "admin"},
          {"doctor@gmail.com", "Doctor", "doctor"},
          {"nurse@gmail.com", "Nurse", "nurse"},
          {"pharmacist@gmail.com", "Pharmacist", "pharmacist"},
          {"labtechnician@gmail.com", "Lab Technician", "labtechnician"}
        ] do
      %{
        "email" => email,
        "hashed_password" => Bcrypt.hash_pwd_salt(@default_password),
        "name" => name,
        "role" => role
      }
    end
  end
end
