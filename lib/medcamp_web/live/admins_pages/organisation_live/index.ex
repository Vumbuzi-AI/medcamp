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
    <div class="-m-4 min-h-screen bg-slate-50 p-4 sm:-m-6 sm:p-6">
      <.form
        for={@form}
        id="organisation-form"
        phx-change="validate"
        phx-submit="save"
        class="mx-auto max-w-6xl space-y-6"
      >
        <section class="rounded-2xl border border-slate-200 bg-white p-5 sm:p-7">
          <div class="flex flex-col gap-5 lg:flex-row lg:items-start lg:justify-between">
            <div class="flex min-w-0 gap-4">
              <img
                src={Organisations.logo_path(@organisation)}
                alt={Organisations.display_name(@organisation)}
                class="h-16 w-16 shrink-0 rounded-2xl border border-brand-200 bg-brand-50 object-contain p-1.5"
              />
              <div class="min-w-0">
                <h1 class="truncate text-2xl font-bold tracking-[-0.01em] text-slate-900 sm:text-3xl">
                  Organisation
                </h1>
                <p class="mt-2 max-w-2xl text-sm leading-relaxed text-slate-500">
                  Your details and branding. The colours below are used across the whole
                  system, including printed lab reports.
                </p>
              </div>
            </div>

            <div class="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 sm:min-w-72">
              <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">Location</p>
              <p class="mt-1 truncate text-sm font-semibold text-brand-primary">
                {empty_value(@organisation.location)}
              </p>
            </div>
          </div>
        </section>

        <div class="grid gap-6 xl:grid-cols-[minmax(0,1fr)_360px]">
          <div class="space-y-6">
            <section class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
              <div class="flex items-start gap-3 border-b border-slate-100 pb-5">
                <div class="grid h-11 w-11 shrink-0 place-items-center rounded-full border border-slate-200 bg-slate-50 text-brand-primary">
                  <Heroicons.icon name="building-office-2" type="outline" class="h-6 w-6" />
                </div>
                <div>
                  <h2 class="text-lg font-semibold text-slate-900">Organisation details</h2>
                  <p class="mt-1 text-sm leading-relaxed text-slate-500">
                    Keep the camp organisation contact information current for staff,
                    reports, and platform support.
                  </p>
                </div>
              </div>

              <div class="mt-6 grid grid-cols-1 gap-5 lg:grid-cols-2">
                <.input field={@form[:name]} type="text" label="Name" />
                <.input field={@form[:email]} type="email" label="Email" />
                <.input field={@form[:phone_number]} type="text" label="Phone number" />
                <.input field={@form[:location]} type="text" label="Location" />
                <div class="lg:col-span-2">
                  <.input field={@form[:slug]} type="text" label="Slug" />
                  <p class="mt-1 text-xs text-slate-500">
                    Lowercase letters, numbers and hyphens. Identifies the organisation
                    internally; changing it does not affect any saved links.
                  </p>
                </div>
              </div>
            </section>

            <section class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
              <div class="flex items-start gap-3 border-b border-slate-100 pb-5">
                <div class="grid h-11 w-11 shrink-0 place-items-center rounded-full border border-slate-200 bg-slate-50 text-brand-primary">
                  <Heroicons.icon name="swatch" type="outline" class="h-6 w-6" />
                </div>
                <div>
                  <h2 class="text-lg font-semibold text-slate-900">Brand colours</h2>
                  <p class="mt-1 text-sm leading-relaxed text-slate-500">
                    These colours theme the workspace, action buttons, sidebar highlights,
                    and printed medical camp reports.
                  </p>
                </div>
              </div>

              <p
                :if={Organisations.using_default_colours?(@organisation)}
                class="mt-4 inline-flex items-center gap-1.5 rounded-full bg-slate-100 px-3 py-1 text-xs font-medium text-slate-600"
              >
                <span class="h-1.5 w-1.5 rounded-full bg-slate-400"></span>
                Using the default Tibasasa palette
              </p>

              <div class="mt-6 grid grid-cols-1 gap-5 sm:grid-cols-2">
                <.colour_field
                  field={@form[:primary_color]}
                  label="Primary colour"
                  helper="Main navigation and primary actions"
                />
                <.colour_field
                  field={@form[:accent_color]}
                  label="Accent colour"
                  helper="Highlights, links, and supporting states"
                />
              </div>
            </section>
          </div>

          <aside class="space-y-6">
            <section class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
              <div class="flex items-start gap-3">
                <div class="grid h-11 w-11 shrink-0 place-items-center rounded-full border border-slate-200 bg-slate-50 text-brand-primary">
                  <Heroicons.icon name="photo" type="outline" class="h-6 w-6" />
                </div>
                <div>
                  <h2 class="text-lg font-semibold text-slate-900">Organisation logo</h2>
                  <p class="mt-1 text-sm leading-relaxed text-slate-500">
                    Used in the sidebar, patient cards, and report letterheads.
                  </p>
                </div>
              </div>

              <div class="mt-6 flex flex-col items-center rounded-2xl border border-dashed border-slate-300 bg-slate-50 px-5 py-6 text-center">
                <img
                  src={Organisations.logo_path(@organisation)}
                  alt={Organisations.display_name(@organisation)}
                  class="h-24 w-24 rounded-2xl border border-brand-200 bg-white object-contain p-2 shadow-sm"
                />
                <p class="mt-4 text-sm font-semibold text-slate-900">
                  {Organisations.display_name(@organisation)}
                </p>
                <p
                  :if={Organisations.using_default_logo?(@organisation)}
                  class="mt-2 inline-flex items-center gap-1.5 rounded-full bg-slate-100 px-3 py-1 text-xs font-medium text-slate-600"
                >
                  <span class="h-1.5 w-1.5 rounded-full bg-slate-400"></span>
                  Using the default Tibasasa logo
                </p>
                <p class="mt-2 text-xs text-slate-500">PNG or JPEG, under 2 MB</p>

                <.live_file_input
                  upload={@uploads.logo}
                  class="mt-5 block w-full cursor-pointer rounded-xl border border-slate-300 bg-white text-sm text-slate-600 file:mr-4 file:border-0 file:bg-brand-primary file:px-4 file:py-3 file:text-sm file:font-semibold file:text-white hover:file:bg-brand-primary-dark"
                />
              </div>

              <div
                :for={entry <- @uploads.logo.entries}
                class="mt-4 rounded-xl border border-slate-200 bg-white p-3"
              >
                <div class="flex items-center justify-between gap-3">
                  <p class="min-w-0 truncate text-sm font-medium text-slate-700">
                    {entry.client_name}
                  </p>
                  <button
                    type="button"
                    class="shrink-0 rounded-full px-3 py-1 text-xs font-semibold text-red-600 transition-colors hover:bg-red-50"
                    phx-click="cancel-logo"
                    phx-value-ref={entry.ref}
                  >
                    Remove
                  </button>
                </div>
                <p :for={err <- upload_errors(@uploads.logo, entry)} class="mt-2 text-sm text-red-600">
                  {error_to_string(err)}
                </p>
              </div>
            </section>

            <section class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
              <h2 class="text-lg font-semibold text-slate-900">Preview</h2>
              <p class="mt-1 text-sm text-slate-500">
                A quick check of the identity patients and staff will see.
              </p>

              <div class="mt-5 rounded-2xl border border-slate-200 p-4">
                <div class="flex items-center gap-3">
                  <img
                    src={Organisations.logo_path(@organisation)}
                    alt=""
                    class="h-12 w-12 rounded-xl border border-brand-200 bg-brand-50 object-contain p-1"
                  />
                  <div class="min-w-0">
                    <p class="truncate text-sm font-semibold text-slate-900">
                      {empty_value(@organisation.name)}
                    </p>
                    <p class="truncate text-xs text-slate-500">
                      {empty_value(@organisation.location)}
                    </p>
                  </div>
                </div>
                <div class="mt-4 grid grid-cols-2 gap-2">
                  <span class="h-2 rounded-full bg-brand-primary"></span>
                  <span class="h-2 rounded-full bg-brand-accent"></span>
                </div>
              </div>
            </section>
          </aside>
        </div>

        <div class="flex flex-col gap-3 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm sm:flex-row sm:items-center sm:justify-between">
          <p class="text-sm text-slate-500">
            Changes apply to this organisation's medical camp workspace after saving.
          </p>
          <.button phx-disable-with="Saving...">Save changes</.button>
        </div>
      </.form>
    </div>
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, required: true
  attr :helper, :string, required: true

  defp colour_field(assigns) do
    ~H"""
    <div>
      <.input field={@field} type="color" label={@label} />
      <p class="mt-2 text-xs text-slate-500">{@helper}</p>
    </div>
    """
  end

  defp empty_value(nil), do: "Not set"
  defp empty_value(""), do: "Not set"
  defp empty_value(value), do: value

  defp error_to_string(:too_large), do: "Logo must be under 2 MB"
  defp error_to_string(:not_accepted), do: "Logo must be a PNG or JPEG"
  defp error_to_string(:too_many_files), do: "Only one logo"
  defp error_to_string(_), do: "Could not upload this file"
end
