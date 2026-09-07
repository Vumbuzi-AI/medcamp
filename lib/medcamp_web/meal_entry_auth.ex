defmodule MedcampWeb.MealEntryAuth do
  @moduledoc """
  Assigns the PIN-authenticated support staff user for the mobile meal entry
  page (`/meals/add`). Access is granted by entering a support staff PIN, which
  the session controller stores in the session.
  """

  import Phoenix.Component, only: [assign: 3]

  alias Medcamp.Accounts

  def on_mount(:mount_meal_entry_user, _params, session, socket) do
    {:cont, assign(socket, :meal_entry_user, fetch_meal_entry_user(session))}
  end

  defp fetch_meal_entry_user(session) do
    case session["meal_entry_user_id"] do
      nil -> nil
      user_id -> get_active_support_staff(user_id)
    end
  end

  defp get_active_support_staff(user_id) do
    case Accounts.get_user!(user_id) do
      %{role: "support staff", is_active: true} = user -> user
      _ -> nil
    end
  rescue
    Ecto.NoResultsError -> nil
  end
end
