defmodule MedcampWeb.AdminMedicalCampPinSessionController do
  use MedcampWeb, :controller

  alias Medcamp.Accounts

  def create(conn, %{"otp" => otp}) do
    case Accounts.get_admin_by_otp(otp) do
      nil ->
        conn
        |> put_flash(:error, "Invalid admin PIN. Please try again.")
        |> redirect(to: ~p"/admin/medical_camp/access")

      user ->
        conn
        |> put_session(:admin_medical_camp_access_user_id, user.id)
        |> put_flash(:info, "Medical camp access granted.")
        |> redirect(to: ~p"/admin/medical_camp/external")
    end
  end

  def delete(conn, _params) do
    conn
    |> delete_session(:admin_medical_camp_access_user_id)
    |> put_flash(:info, "You have been logged out of the external medical camp page.")
    |> redirect(to: ~p"/admin/medical_camp/access")
  end
end
