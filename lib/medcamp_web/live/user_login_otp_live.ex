defmodule MedcampWeb.UserLoginOtpLive do
  use MedcampWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="w-[90%] min-h-screen mx-auto flex justify-center items-center">
      <div class="w-full max-w-md px-8 py-10 rounded-xl border border-gray-200 shadow-sm">
        <.header class="text-center">
          Verify your login
          <p class="text-[16px] text-grey font-normal">
            Enter the six-digit code sent to your email. It expires in five minutes.
          </p>
        </.header>

        <.simple_form
          for={@form}
          id="login_otp_form"
          action={~p"/users/log_in/otp"}
          class="w-full"
          phx-update="ignore"
        >
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
            <.button phx-disable-with="Verifying..." class="w-full">
              Verify and log in
            </.button>
          </:actions>
        </.simple_form>

        <div class="mt-5 flex justify-between text-sm">
          <.link href={~p"/users/log_in"} class="font-semibold">Start over</.link>
          <.link href={~p"/users/log_in/otp/resend"} method="post" class="font-semibold">
            Send a new code
          </.link>
        </div>
      </div>
    </div>
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
