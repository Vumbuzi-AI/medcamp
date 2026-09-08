defmodule MedcampWeb.AdminUsersLive.FormComponent do
  alias Medcamp.Accounts
  alias Medcamp.Postal
  use MedcampWeb, :live_component

  defp datetime_local_value(nil), do: nil

  defp datetime_local_value(%DateTime{} = datetime) do
    datetime
    |> DateTime.add(3 * 60 * 60, :second)
    |> Calendar.strftime("%Y-%m-%dT%H:%M")
  end

  defp datetime_local_value(%NaiveDateTime{} = datetime) do
    datetime
    |> NaiveDateTime.add(3 * 60 * 60, :second)
    |> Calendar.strftime("%Y-%m-%dT%H:%M")
  end

  defp datetime_local_value(value) when is_binary(value), do: value
  defp datetime_local_value(_value), do: nil

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="lab_result-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} required type="text" label="Name" />
        <.input
          field={@form[:email]}
          readonly={if @action == :edit, do: true, else: false}
          type="text"
          label="Email"
        />
        <.input
          field={@form[:inserted_at]}
          type="datetime-local"
          label="Inserted at"
          value={datetime_local_value(@form[:inserted_at].value)}
        />
        <.input field={@form[:phone_number]} type="text" label="Contact number" />
        <.input
          field={@form[:role]}
          required
          type="select"
          options={Medcamp.Accounts.User.roles()}
          prompt="Select Role"
          label="Role"
        />
        <.input field={@form[:is_active]} type="checkbox" label="Active?" />

        <:actions>
          <.button phx-disable-with="Saving...">Save User</.button>
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
     |> assign_new(:form, fn ->
       to_form(Accounts.change_user(user))
     end)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user(socket.assigns.user, user_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"user" => user_params}, socket)
      when socket.assigns.action in [:new] do
    random_password =
      Bcrypt.hash_pwd_salt("123456")

    params = Map.put(user_params, "hashed_password", random_password)

    case Accounts.create_user(params) do
      {:ok, user} ->
        token = Accounts.get_reset_password_link_for_user(user)

        reset_link =
          "https://glocalhealthcentre.org/users/reset_password/" <> token

        spawn(fn ->
          Postal.deliver_reset_password_instructions(
            user,
            reset_link
          )
        end)

        {:noreply,
         socket
         |> put_flash(:info, "User created successfully")
         |> push_navigate(to: ~p"/admin/users")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end

  def handle_event("save", %{"user" => user_params}, socket)
      when socket.assigns.action in [:edit] do
    case Accounts.update_user(socket.assigns.user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User updated successfully")
         |> push_navigate(to: ~p"/admin/users/")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end
end
