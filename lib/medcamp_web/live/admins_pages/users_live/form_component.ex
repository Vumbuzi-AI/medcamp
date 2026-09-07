defmodule MedcampWeb.AdminUsersLive.FormComponent do
  alias Medcamp.Accounts
  alias Medcamp.Departments
  alias Medcamp.Suppliers
  alias Medcamp.Postal
  use MedcampWeb, :live_component

  defp blank_to_nil(value) when is_binary(value) do
    value = String.trim(value)
    if value == "", do: nil, else: value
  end

  defp blank_to_nil(_), do: nil

  defp maybe_put_prefill(params, key, value, previous_value) do
    current = Map.get(params, key)

    if current in [nil, ""] or (previous_value && current == previous_value) do
      Map.put(params, key, value)
    else
      params
    end
  end

  defp maybe_prefill_from_supplier(user_params, socket) do
    supplier_id = blank_to_nil(user_params["supplier_id"])
    previous_supplier_id = socket.assigns[:prefill_supplier_id]
    previous_prefill = socket.assigns[:prefill_values] || %{}

    cond do
      socket.assigns.action != :new ->
        {user_params, socket}

      is_nil(supplier_id) ->
        {user_params, socket}

      supplier_id == previous_supplier_id ->
        {user_params, socket}

      true ->
        supplier =
          try do
            Suppliers.get_supplier!(supplier_id)
          rescue
            _ -> nil
          end

        if is_nil(supplier) do
          {user_params, socket}
        else
          prefill = %{
            "role" => "supplier",
            "name" => supplier.name,
            "email" => supplier.email,
            "phone_number" => supplier.contact
          }

          user_params =
            user_params
            |> Map.put("role", prefill["role"])
            |> maybe_put_prefill("name", prefill["name"], previous_prefill["name"])
            |> maybe_put_prefill("email", prefill["email"], previous_prefill["email"])
            |> maybe_put_prefill(
              "phone_number",
              prefill["phone_number"],
              previous_prefill["phone_number"]
            )

          socket =
            socket
            |> assign(:prefill_supplier_id, supplier_id)
            |> assign(:prefill_values, prefill)

          {user_params, socket}
        end
    end
  end

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
        <.input
          field={@form[:supplier_id]}
          type="select"
          options={@suppliers}
          prompt="Select supplier (required for supplier role)"
          label="Supplier"
        />
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
          options={[
            "admin",
            "doctor",
            "nurse",
            "labtechnician",
            "reception",
            "pharmacist",
            "radiologist",
            "support staff",
            "inventory_manager",
            "supplier",
            "procurement_officer",
            "stores_officer",
            "finance_officer"
          ]}
          prompt="Select Role"
          label="Role"
        />
        <.input
          field={@form[:department_id]}
          type="select"
          options={@departments}
          prompt="Select department (optional)"
          label="Department"
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
    departments = Departments.list_departments_for_selection()
    suppliers = Suppliers.list_suppliers_for_selection()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:departments, departments)
     |> assign(:suppliers, suppliers)
     |> assign_new(:prefill_supplier_id, fn ->
       if is_integer(user.supplier_id), do: Integer.to_string(user.supplier_id), else: nil
     end)
     |> assign_new(:prefill_values, fn -> %{"role" => user.role} end)
     |> assign_new(:form, fn ->
       to_form(Accounts.change_user(user))
     end)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    {user_params, socket} = maybe_prefill_from_supplier(user_params, socket)
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
