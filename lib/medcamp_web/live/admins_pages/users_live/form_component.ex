defmodule MedcampWeb.AdminUsersLive.FormComponent do
  alias Medcamp.Accounts
  alias Medcamp.Postal
  use MedcampWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>{@title}</.header>

      <p :if={@action == :new} class="mt-1 text-sm text-slate-500">
        We'll email {@form[:email].value || "them"} a link to set their password.
        The account stays inactive until they do.
      </p>

      <.simple_form
        for={@form}
        id="user-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} required type="text" label="Name" />
        <.input field={@form[:email]} required readonly={@action == :edit} type="email" label="Email" />
        <.input
          field={@form[:role]}
          required
          type="select"
          options={Accounts.User.roles()}
          prompt="Select role"
          label="Role"
        />
        <.input :if={@action == :edit} field={@form[:is_active]} type="checkbox" label="Active" />

        <:actions>
          <.button phx-disable-with="Saving...">
            {if @action == :new, do: "Send invitation", else: "Save"}
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{user: user} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn -> to_form(Accounts.change_user(user)) end)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user(socket.assigns.user, user_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"user" => user_params}, socket)
      when socket.assigns.action == :new do
    case Accounts.invite_user(Map.take(user_params, ["name", "email", "role"])) do
      {:ok, %{user: user, token: token}} ->
        setup_link = url(~p"/users/reset_password/#{token}")

        org_name =
          MedcampWeb.Layouts.organisation_name(%{
            current_organisation: socket.assigns[:current_organisation]
          })

        Task.start(fn ->
          Postal.deliver_staff_invitation_instructions(user, setup_link,
            role: user.role,
            organisation_name: org_name
          )
        end)

        {:noreply,
         socket
         |> put_flash(:info, "Invitation sent to #{user.email}")
         |> push_navigate(to: ~p"/admin/users")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end

  def handle_event("save", %{"user" => user_params}, socket)
      when socket.assigns.action == :edit do
    case Accounts.update_user(socket.assigns.user, Map.take(user_params, ~w(name role is_active))) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User updated")
         |> push_navigate(to: ~p"/admin/users")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end
end
