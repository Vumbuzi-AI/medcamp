defmodule MedcampWeb.MedicalCampAuth do
  @moduledoc """
  Authorises the signed-in staff member for a camp station page reached by
  scanning a patient wristband (`/8018/:gsrn/medical-camp/...`).

  These pages sit outside the normal tenant-scoped `live_session`, so the
  guard is explicit here:

    * a valid `user_token` in the session (regular staff login or the station
      PIN sign-in), and
    * the user's organisation is the **same** as the scanned patient's, and
    * the user's role is one the route allows (a doctor page needs a doctor).

  On failure:

    * **no session at all** -> the station PIN screen
      (`/8018/:gsrn/medical-camp/pin`), so a nurse can PIN in and keep scanning.
    * **signed in, but wrong organisation or role** -> `/users/log_in`.

  Use `{:require_camp_role, ["doctor"]}` to name the roles. `:require_camp_auth`
  is kept as "any clinical camp role". On success `:current_user`, `:patient`
  and `:active_camp` are assigned.
  """
  import Phoenix.LiveView
  import Phoenix.Component, only: [assign: 3]

  alias Medcamp.Accounts
  alias Medcamp.Camps
  alias MedcampWeb.PublicTenant

  @clinical_roles ~w(doctor nurse labtechnician pharmacist receptionist)

  # Every station page under /8018/:gsrn shows which camp its records land in.
  def on_mount(:assign_active_camp, %{"gsrn" => gsrn}, _session, socket) do
    _ = PublicTenant.resolve_patient(gsrn)
    {:cont, assign(socket, :active_camp, safe_active_camp())}
  end

  def on_mount(:assign_active_camp, _params, _session, socket),
    do: {:cont, assign(socket, :active_camp, nil)}

  def on_mount(:require_camp_auth, params, session, socket),
    do: on_mount({:require_camp_role, @clinical_roles}, params, session, socket)

  def on_mount({:require_camp_role, allowed_roles}, %{"gsrn" => gsrn}, session, socket) do
    with token when is_binary(token) <- session["user_token"],
         %Accounts.User{} = user <- Accounts.get_user_by_session_token(token),
         {:ok, patient, _org} <- PublicTenant.resolve_patient(gsrn),
         true <- user.organisation_id == patient.organisation_id,
         true <- user.role in allowed_roles do
      {:cont,
       socket
       |> assign(:current_user, user)
       |> assign(:patient, patient)
       |> assign(:active_camp, safe_active_camp())}
    else
      # No usable session -> the station PIN screen (keeps scan-and-go fast).
      nil ->
        {:halt, redirect(socket, to: "/8018/#{gsrn}/medical-camp/pin")}

      # Signed in but not for this camp, or the code resolves to no patient.
      # Silent redirect (no flash): `/users/log_in` bounces an authenticated
      # user straight to their own workspace, and a mis-scanned wristband at a
      # multi-org event is routine, not an error worth shouting about.
      _ ->
        {:halt, redirect(socket, to: "/users/log_in")}
    end
  end

  defp safe_active_camp do
    Camps.get_active_camp()
  rescue
    _ -> nil
  end
end
