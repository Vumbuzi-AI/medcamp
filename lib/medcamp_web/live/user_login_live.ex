defmodule MedcampWeb.UserLoginLive do
  use MedcampWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto flex min-h-screen w-full items-center justify-center px-4 sm:w-[90%] lg:justify-between lg:px-0">
      <div class="hidden h-screen w-[48%] items-center justify-center lg:flex">
        <img src="/images/why.png" alt="Medcamp Logo" class="mx-auto h-[90vh] w-full object-cover" />
      </div>
      <div class="flex min-h-screen w-full max-w-md flex-col items-center justify-center px-2 py-8 sm:px-6 lg:w-[48%] lg:max-w-none lg:px-12">
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
          class="w-full"
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

        <p class="mt-8 text-sm text-grey">
          New here?
          <.link navigate={~p"/organisations/register"} class="font-semibold text-brand-primary">
            Create your organisation
          </.link>
        </p>
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
