defmodule MedcampWeb.MedicalCampSessionController do
  use MedcampWeb, :controller

  alias Medcamp.Accounts
  alias MedcampWeb.PublicTenant
  alias MedcampWeb.UserAuth

  @doc """
  Camp-station PIN sign-in. The scanned `gsrn` fixes which organisation the
  station belongs to; a PIN only signs someone in if they are an active member
  of that organisation. A matching OTP in another organisation is rejected.
  """
  def create(conn, %{"gsrn" => gsrn, "otp" => otp}) do
    home = ~p"/8018/#{gsrn}/medical-camp"

    with {:ok, _patient, organisation} <- PublicTenant.resolve_patient(gsrn),
         user when not is_nil(user) <- Accounts.get_camp_user_by_otp(otp, organisation.id) do
      conn
      |> put_session(:user_return_to, home)
      |> UserAuth.log_in_user(user)
    else
      _ ->
        conn
        |> put_flash(:error, "That PIN isn't valid for this camp. Please try again.")
        |> redirect(to: home <> "/pin")
    end
  end
end
