defmodule MedcampWeb.PageController do
  use MedcampWeb, :controller

  @doc """
  The camp system has no public marketing site: anyone hitting the root who is
  not already signed in goes straight to the login page. Signed-in users never
  reach here - the `:redirect_to_correct_page` plug sends them to their role
  landing page first.
  """
  def home(conn, _params) do
    redirect(conn, to: ~p"/users/log_in")
  end
end
