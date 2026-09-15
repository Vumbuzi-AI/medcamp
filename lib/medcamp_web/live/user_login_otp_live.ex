defmodule MedcampWeb.UserLoginOtpLive do
  use MedcampWeb, :live_view

  def render(assigns) do
    ~H"""
    <.auth_shell
      title="Verify your login"
      subtitle="Enter the six-digit code sent to your email. It expires in five minutes."
    >
      <.simple_form for={@form} id="login_otp_form" action={~p"/users/log_in/otp"} phx-update="ignore">
        <.input
          field={@form[:code]}
          type="text"
          label="Verification code"
          inputmode="numeric"
          autocomplete="one-time-code"
          minlength="6"
          maxlength="6"
          pattern="[0-9]{6}"
          required
        />

        <:actions>
          <.auth_submit label="Verify and sign in" phx-disable-with="Verifying..." />
        </:actions>
      </.simple_form>

      <:footer>
        <div class="flex justify-between gap-6">
          <.link href={~p"/users/log_in"} class="transition-colors duration-150 hover:text-[#52B2D8]">
            Start over
          </.link>
          <.link
            href={~p"/users/log_in/otp/resend"}
            method="post"
            class="transition-colors duration-150 hover:text-[#52B2D8]"
          >
            Send a new code
          </.link>
        </div>
      </:footer>
    </.auth_shell>
    """
  end

  def mount(_params, session, socket) do
    if session["login_otp_challenge"] do
      {:ok, assign(socket, form: to_form(%{}, as: "otp"))}
    else
      {:ok,
       socket
       |> put_flash(:error, "Enter your email and password to request a login code.")
       |> redirect(to: ~p"/users/log_in")}
    end
  end
end
