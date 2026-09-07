defmodule MedcampWeb.UserLoginLive do
  use MedcampWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="w-[90%] h-[100vh] mx-auto flex justify-between items-center">
      <div class="w-[48%] flex justify-center items-center h-[100vh]">
        <img src="/images/why.png" alt="Medcamp Logo" class="w-[100%] object-cover h-[90vh] mx-auto" />
      </div>
      <div class="w-[48%] h-[100vh] flex flex-col  justify-center items-center px-12">
        <.header class="text-center">
          Sign to your account
          <p class="text-[16px] text-grey font-normal">
            Welcome back! Please enter your details.
          </p>
        </.header>

        <.simple_form
          for={@form}
          id="login_form"
          action={~p"/users/log_in"}
          class="w-[100%]"
          phx-update="ignore"
        >
          <.input field={@form[:email]} type="email" label="Email" required />
          <.input field={@form[:password]} type="password" label="Password" required />

          <:actions>
            <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
            <.link href={~p"/users/reset_password"} class="text-sm font-semibold">
              Forgot your password?
            </.link>
          </:actions>
          <:actions>
            <.button phx-disable-with="Logging in..." class="w-full">
              Log in <span aria-hidden="true">→</span>
            </.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
