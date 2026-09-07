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
    for user <- default_users() do
      case Accounts.get_user_by_email(user["email"]) do
        nil -> Accounts.create_user(user)
        _ -> :ok
      end
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
