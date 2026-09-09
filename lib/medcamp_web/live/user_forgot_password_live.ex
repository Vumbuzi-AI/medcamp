defmodule MedcampWeb.UserForgotPasswordLive do
  use MedcampWeb, :live_view

  alias Medcamp.Accounts
  alias Medcamp.Postal

  def render(assigns) do
    ~H"""
    <.auth_shell
      title="Forgot your password?"
      subtitle="We'll email a reset link if the address is in our system."
    >
      <.simple_form for={@form} id="reset_password_form" phx-submit="send_email">
        <.input field={@form[:email]} type="email" label="Email" required />
        <:actions>
          <.auth_submit label="Send reset link" phx-disable-with="Sending..." />
        </:actions>
      </.simple_form>

      <:footer>
        <.link href={~p"/users/log_in"} class="transition-colors duration-150 hover:text-[#52B2D8]">
          Back to sign in
        </.link>
      </:footer>
    </.auth_shell>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      token = Accounts.get_reset_password_link_for_user(user)

      reset_link =
        "https://glocalhealthcentre.org/users/reset_password/" <> token

      spawn(fn ->
        Postal.deliver_reset_password_instructions(
          user,
          reset_link
        )
      end)
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
