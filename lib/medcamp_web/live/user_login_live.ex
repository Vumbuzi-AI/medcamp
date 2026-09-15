defmodule MedcampWeb.UserLoginLive do
  use MedcampWeb, :live_view

  def render(assigns) do
    ~H"""
    <.auth_split>
      <h1 class="text-2xl font-bold tracking-[-0.01em]">Sign in to your account</h1>
      <p class="mt-2 text-sm leading-relaxed text-slate-600">
        Continue to your medical camp station, dashboard, or platform console.
      </p>

      <.simple_form
        for={@form}
        id="login_form"
        action={~p"/users/log_in"}
        class="mt-6"
        phx-update="ignore"
      >
        <.input field={@form[:email]} type="email" label="Email" required autocomplete="username" />
        <.input
          field={@form[:password]}
          type="password"
          label="Password"
          required
          autocomplete="current-password"
        />

        <:actions>
          <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
          <.link
            href={~p"/users/reset_password"}
            class="text-sm font-semibold text-[#0C2765] transition-colors duration-150 hover:text-[#52B2D8]"
          >
            Forgot your password?
          </.link>
        </:actions>
        <:actions>
          <.auth_submit label="Sign in" phx-disable-with="Signing in..." />
        </:actions>
      </.simple_form>

      <p class="mt-8 text-sm text-slate-600">
        New here?
        <.link
          navigate={~p"/organisations/register"}
          class="font-semibold text-[#0C2765] transition-colors duration-150 hover:text-[#52B2D8]"
        >
          Create your organisation
        </.link>
      </p>
    </.auth_split>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
