defmodule MedcampWeb.MedicalCampSessionController do
  use MedcampWeb, :controller

  alias Medcamp.Accounts
  alias MedcampWeb.UserAuth

  def create(conn, %{"gsrn" => gsrn, "otp" => otp}) do
    case Accounts.get_user_for_medical_camp_by_otp(otp) do
      nil ->
        conn
        |> put_flash(:error, "Invalid OTP. Please try again.")
        |> redirect(to: "/8018/#{gsrn}/medical-camp")

      user ->
        conn
        |> put_session(:user_return_to, "/8018/#{gsrn}/medical-camp")
        |> UserAuth.log_in_user(user)
    end
  end
end
