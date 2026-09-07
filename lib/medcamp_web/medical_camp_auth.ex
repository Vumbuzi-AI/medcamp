defmodule MedcampWeb.MedicalCampAuth do
  @moduledoc """
  Handles authentication for medical camp LiveView pages.
  Checks the session for a `camp_user_id` set after OTP verification.
  """
  import Phoenix.LiveView

  def on_mount(:require_camp_auth, %{"gsrn" => gsrn}, session, socket) do
    if session["user_token"] do
      {:cont, socket}
    else
      socket =
        socket
        |> put_flash(:error, "Please verify your OTP to access this page.")
        |> redirect(to: "/8018/#{gsrn}/medical-camp")

      {:halt, socket}
    end
  end
end
