defmodule MedcampWeb.UsersController do
  use MedcampWeb, :controller
  alias Medcamp.Accounts
  alias MedcampWeb.UserAuth

  def index(conn, %{"email" => email}) do
    # Scoped on purpose: an admin signing in as a colleague must not be able to
    # reach a user in another organisation by guessing their email.
    case Accounts.get_organisation_user_by_email(email) do
      nil ->
        conn
        |> put_flash(:error, "No user with that email in this organisation.")
        |> redirect(to: ~p"/admin/users")

      user ->
        UserAuth.log_in_user(conn, user)
    end
  end

  def index(conn, _params) do
    render(conn, "index.html", text: "Redirecting to test page")
  end
end
