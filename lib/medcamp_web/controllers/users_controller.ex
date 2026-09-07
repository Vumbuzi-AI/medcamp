defmodule MedcampWeb.UsersController do
  use MedcampWeb, :controller
  alias Medcamp.Accounts
  alias MedcampWeb.UserAuth

  def index(conn, %{"email" => email}) do
    user = Accounts.get_user_by_email(email)

    UserAuth.log_in_user(conn, user)
    render(conn, "index.html", text: "Redirecting to user page")
  end

  def index(conn, _params) do
    render(conn, "index.html", text: "Redirecting to test page")
  end
end
