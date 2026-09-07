defmodule MedcampWeb.MealEntryPinSessionController do
  use MedcampWeb, :controller

  alias Medcamp.Accounts

  def create(conn, %{"otp" => otp}) do
    case Accounts.get_support_staff_by_otp(otp) do
      nil ->
        conn
        |> put_flash(:error, "Invalid PIN. Please try again.")
        |> redirect(to: ~p"/meals/add")

      user ->
        conn
        |> put_session(:meal_entry_user_id, user.id)
        |> put_flash(:info, "Signed in as #{user.name}.")
        |> redirect(to: ~p"/meals/add")
    end
  end

  def logout(conn, _params) do
    conn
    |> delete_session(:meal_entry_user_id)
    |> put_flash(:info, "You have been signed out.")
    |> redirect(to: ~p"/meals/add")
  end
end
