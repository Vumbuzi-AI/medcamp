defmodule MedcampWeb.CampSessionController do
  @moduledoc """
  Persists the admin's camp filter choice.

  This is a controller rather than a LiveView event because the choice lives
  in the session, and a LiveView cannot write to it - the session belongs to
  the HTTP connection, not to the socket. Posting here and redirecting back
  means the filter survives navigation and a page reload.
  """

  use MedcampWeb, :controller

  alias Medcamp.Camps
  alias MedcampWeb.UserAuth

  def update(conn, params) do
    camp_id = resolve_camp_id(params["camp_id"])

    conn
    |> put_session(UserAuth.camp_filter_session_key(), camp_id)
    |> redirect(to: return_to(conn, params))
  end

  # Resolved against the viewer's own organisation before it is stored, so a
  # hand-edited form cannot park another tenant's camp id in the session. The
  # tenant filter would refuse to match it anyway; this just fails cleanly.
  defp resolve_camp_id(id) when id in [nil, "", "all"], do: nil

  defp resolve_camp_id(id) do
    case Camps.get_camp(id) do
      nil -> nil
      camp -> camp.id
    end
  end

  defp return_to(conn, params) do
    with nil <- safe_path(params["return_to"]),
         nil <- conn |> get_req_header("referer") |> List.first() |> referer_path() do
      ~p"/admin/dashboard"
    end
  end

  defp referer_path(nil), do: nil

  # Query string kept: returning to /admin/patient_visits without the page's
  # own filters would silently throw away what the admin was looking at.
  defp referer_path(referer) do
    uri = URI.parse(referer)

    case safe_path(uri.path) do
      nil -> nil
      path -> if uri.query, do: path <> "?" <> uri.query, else: path
    end
  end

  # Only same-site paths, so the redirect cannot be pointed off the site.
  defp safe_path("/" <> _ = path), do: if(String.starts_with?(path, "//"), do: nil, else: path)
  defp safe_path(_), do: nil
end
