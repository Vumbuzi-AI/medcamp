defmodule MedcampWeb.LabPages.SettingsIndex do
  use MedcampWeb, :lab_live_view
  alias Medcamp.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :settings)
     |> allow_upload(:image,
       accept: ~w(.jpg .jpeg .png),
       max_entries: 1,
       max_file_size: 5_000_000
     )
     |> assign(:uploaded_files, [])
     |> assign(:active_tab, "profile")
     |> assign_new(:form, fn ->
       to_form(Accounts.change_user_profile(socket.assigns.current_user), as: "user")
     end)}
  end

  @impl true
  def handle_event("validate-profile", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_profile(socket.assigns.current_user, user_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save-profile", %{"user" => user_params}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :image, fn %{path: path}, _entry ->
        dest = Path.join(Application.app_dir(:medcamp, "priv/static/uploads"), Path.basename(path))

        File.cp!(path, dest)
        {:ok, ~p"/uploads/#{Path.basename(dest)}"}
      end)

    profile_image =
      case uploaded_files do
        [] ->
          socket.assigns.current_user.image

        [profile_image] ->
          profile_image
      end

    user_params =
      user_params
      |> Map.put("image", profile_image)

    case Accounts.update_user_profile(socket.assigns.current_user, user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:current_user, user)
         |> put_flash(:info, "Profile updated successfully.")
         |> assign(:form, to_form(Accounts.change_user_profile(user), as: "user"))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.profile_section uploads={@uploads} current_user={@current_user} form={@form} />
    </div>
    """
  end
end
