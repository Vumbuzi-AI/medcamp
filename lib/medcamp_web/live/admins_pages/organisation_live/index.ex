defmodule MedcampWeb.AdminOrganisationLive.Index do
  @moduledoc """
  Where an organisation's admin edits their own profile and branding.

  The two colours picked here drive the whole UI - sidebar, buttons, printed
  lab report letterhead - through the `--brand-*` CSS variables the root
  layout emits. See `Medcamp.Organisations.Organisation.css_variables/1`.
  """

  use MedcampWeb, :admin_live_view

  alias Medcamp.Organisations
  alias Medcamp.Uploads.Validator

  @logo_dir "priv/static/uploads/organisations"

  @impl true
  def mount(_params, _session, socket) do
    organisation = socket.assigns.current_organisation

    {:ok,
     socket
     |> assign(:active_tab, :organisation)
     |> assign(:page_title, "Organisation")
     |> assign(:organisation, organisation)
     |> assign(:form, to_form(Organisations.change_profile(organisation), as: "organisation"))
     |> allow_upload(:logo,
       accept: ~w(.png .jpg .jpeg),
       max_entries: 1,
       max_file_size: 2_000_000
     )}
  end

  @impl true
  def handle_event("validate", %{"organisation" => params}, socket) do
    changeset = Organisations.change_profile(socket.assigns.organisation, params)
    {:noreply, assign(socket, :form, to_form(changeset, action: :validate, as: "organisation"))}
  end

  def handle_event("save", %{"organisation" => params}, socket) do
    params = Map.put(params, "logo", consume_logo(socket) || socket.assigns.organisation.logo)

    case Organisations.update_profile(socket.assigns.organisation, params) do
      {:ok, organisation} ->
        {:noreply,
         socket
         |> assign(:organisation, organisation)
         |> assign(:current_organisation, organisation)
         |> assign(
           :form,
           to_form(Organisations.change_profile(organisation), as: "organisation")
         )
         |> put_flash(:info, "Organisation profile updated.")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: "organisation"))}
    end
  end

  def handle_event("cancel-logo", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :logo, ref)}
  end

  # Reuses the same header-sniffing validation as patient document uploads, so
  # a renamed executable cannot be stored as a logo.
  defp consume_logo(socket) do
    socket
    |> consume_uploaded_entries(:logo, fn %{path: path}, entry ->
      case Validator.validate_upload(entry, path) do
        :ok ->
          dir = Application.app_dir(:medcamp, @logo_dir)
          File.mkdir_p!(dir)

          filename =
            "#{socket.assigns.organisation.slug}-#{System.system_time(:second)}" <>
              String.downcase(Path.extname(entry.client_name))

          File.cp!(path, Path.join(dir, filename))
          {:ok, "/uploads/organisations/#{filename}"}

        {:error, _reason} ->
          {:ok, nil}
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> List.first()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl">
      <h1 class="text-2xl font-bold text-brand-primary">Organisation</h1>
      <p class="mt-1 text-sm text-grey">
        Your details and branding. The colours below are used across the whole system,
        including printed lab reports.
      </p>

      <.form
        for={@form}
        id="organisation-form"
        phx-change="validate"
        phx-submit="save"
        class="mt-6 space-y-5"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:email]} type="email" label="Email" />
        <.input field={@form[:phone_number]} type="text" label="Phone number" />
        <.input field={@form[:location]} type="text" label="Location" />

        <div class="grid grid-cols-1 gap-5 sm:grid-cols-2">
          <.input field={@form[:primary_color]} type="color" label="Primary colour" />
          <.input field={@form[:accent_color]} type="color" label="Accent colour" />
        </div>

        <div>
          <label class="block text-sm font-semibold leading-6 text-zinc-800">Logo</label>
          <div class="mt-2 flex items-center gap-4">
            <img
              src={Organisations.logo_path(@organisation)}
              alt={Organisations.display_name(@organisation)}
              class="h-16 w-16 rounded-xl border border-brand-200 bg-brand-50 object-contain p-1"
            />
            <.live_file_input upload={@uploads.logo} class="text-sm" />
          </div>

          <div :for={entry <- @uploads.logo.entries} class="mt-2 text-sm text-grey">
            {entry.client_name}
            <button
              type="button"
              class="ml-2 text-red-600"
              phx-click="cancel-logo"
              phx-value-ref={entry.ref}
            >
              remove
            </button>
            <p :for={err <- upload_errors(@uploads.logo, entry)} class="text-red-600">
              {error_to_string(err)}
            </p>
          </div>
        </div>

        <.button phx-disable-with="Saving...">Save changes</.button>
      </.form>
    </div>
    """
  end

  defp error_to_string(:too_large), do: "Logo must be under 2 MB"
  defp error_to_string(:not_accepted), do: "Logo must be a PNG or JPEG"
  defp error_to_string(:too_many_files), do: "Only one logo"
  defp error_to_string(_), do: "Could not upload this file"
end
