defmodule MedcampWeb.SuperadminOrganisationsLive.Index do
  @moduledoc """
  Provisioning console: create organisations and each one's first admin.

  Sits outside every tenant, so all of its queries pass `skip_org_id: true` -
  it is the one place in the app that is allowed to see across organisations,
  and it is reachable only by a user with `is_superadmin` set directly in the
  database.
  """

  use MedcampWeb, :live_view

  alias Medcamp.Accounts
  alias Medcamp.Organisations
  alias Medcamp.Organisations.Organisation
  alias Medcamp.Tenancy

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Organisations")
     |> assign(:current_organisation, nil)
     |> assign(:admin_form, nil)
     |> assign(:form, to_form(Organisations.change_organisation(%Organisation{}), as: "org"))
     |> load_organisations()}
  end

  @impl true
  def handle_event("validate", %{"org" => params}, socket) do
    changeset = Organisations.change_organisation(%Organisation{}, params)
    {:noreply, assign(socket, :form, to_form(changeset, action: :validate, as: "org"))}
  end

  def handle_event("create", %{"org" => params}, socket) do
    case Organisations.create_organisation(params) do
      {:ok, organisation} ->
        {:noreply,
         socket
         |> put_flash(:info, "#{organisation.name} created. Now add its first admin.")
         |> assign(:form, to_form(Organisations.change_organisation(%Organisation{}), as: "org"))
         |> assign(:admin_form, blank_admin_form(organisation))
         |> load_organisations()}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: "org"))}
    end
  end

  def handle_event("add-admin", %{"admin" => params}, socket) do
    organisation = Organisations.get_organisation!(params["organisation_id"])

    # Create the admin inside the new organisation's tenancy so every
    # tenant-stamped write during registration lands in the right place.
    result =
      Tenancy.with_org(organisation.id, fn ->
        Accounts.register_user(%{
          "name" => params["name"],
          "email" => params["email"],
          "password" => params["password"],
          "role" => "admin"
        })
      end)

    case result do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Admin #{user.email} created for #{organisation.name}.")
         |> assign(:admin_form, nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :admin_form, to_form(changeset, as: "admin"))}
    end
  end

  def handle_event("toggle-active", %{"id" => id}, socket) do
    organisation = Organisations.get_organisation!(id)

    {:ok, _} =
      if organisation.is_active do
        Organisations.deactivate_organisation(organisation)
      else
        Organisations.approve(organisation)
      end

    {:noreply, load_organisations(socket)}
  end

  def handle_event("approve", %{"id" => id}, socket) do
    {:ok, organisation} = id |> Organisations.get_organisation!() |> Organisations.approve()

    {:noreply,
     socket
     |> put_flash(:info, "#{organisation.name} approved. Its admin can now sign in.")
     |> load_organisations()}
  end

  def handle_event("add-admin-for", %{"id" => id}, socket) do
    {:noreply, assign(socket, :admin_form, blank_admin_form(Organisations.get_organisation!(id)))}
  end

  defp load_organisations(socket) do
    socket
    |> assign(:organisations, Organisations.list_organisations())
    |> assign(:pending, Organisations.list_pending_organisations())
  end

  defp blank_admin_form(organisation) do
    to_form(
      %{
        "organisation_id" => organisation.id,
        "organisation_name" => organisation.name,
        "name" => "",
        "email" => "",
        "password" => ""
      },
      as: "admin"
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-5xl p-6">
      <h1 class="text-2xl font-bold text-brand-primary">Organisations</h1>
      <p class="mt-1 text-sm text-grey">
        Each organisation is a separate tenant. Nothing is shared between them.
      </p>

      <div :if={@pending != []} class="mt-8 rounded-xl border border-amber-300 bg-amber-50 p-5">
        <h2 class="font-semibold text-amber-900">
          Awaiting approval ({length(@pending)})
        </h2>
        <p class="mt-1 text-sm text-amber-800">
          These signed up themselves. Nobody can log in until you approve them.
        </p>

        <ul class="mt-4 divide-y divide-amber-200">
          <li :for={org <- @pending} class="flex items-center justify-between gap-4 py-3">
            <div class="min-w-0">
              <p class="truncate font-medium text-amber-900">{org.name}</p>
              <p class="truncate text-xs text-amber-800">
                {org.contact_name} · {org.email}{if org.location, do: " · #{org.location}"}
              </p>
            </div>
            <button
              type="button"
              class="shrink-0 rounded-lg bg-amber-600 px-3 py-1.5 text-xs font-semibold text-white"
              phx-click="approve"
              phx-value-id={org.id}
            >
              Approve
            </button>
          </li>
        </ul>
      </div>

      <div class="mt-8 rounded-xl border border-gray-200 p-5">
        <h2 class="font-semibold text-gray-900">New organisation</h2>

        <.form for={@form} phx-change="validate" phx-submit="create" class="mt-4 space-y-4">
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <.input field={@form[:name]} type="text" label="Name" />
            <.input field={@form[:slug]} type="text" label="Slug" placeholder="acme-health" />
            <.input field={@form[:email]} type="email" label="Email" />
            <.input field={@form[:phone_number]} type="text" label="Phone number" />
            <.input field={@form[:location]} type="text" label="Location" />
            <.input field={@form[:primary_color]} type="color" label="Primary colour" />
            <.input field={@form[:accent_color]} type="color" label="Accent colour" />
          </div>

          <.button phx-disable-with="Creating...">Create organisation</.button>
        </.form>
      </div>

      <div :if={@admin_form} class="mt-6 rounded-xl border border-brand-200 bg-brand-50 p-5">
        <h2 class="font-semibold text-brand-primary">
          First admin for {@admin_form[:organisation_name].value}
        </h2>

        <.form for={@admin_form} phx-submit="add-admin" class="mt-4 space-y-4">
          <input
            type="hidden"
            name="admin[organisation_id]"
            value={@admin_form[:organisation_id].value}
          />
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
            <.input field={@admin_form[:name]} type="text" label="Name" required />
            <.input field={@admin_form[:email]} type="email" label="Email" required />
            <.input field={@admin_form[:password]} type="password" label="Password" required />
          </div>

          <.button phx-disable-with="Creating...">Create admin</.button>
        </.form>
      </div>

      <table class="mt-8 w-full text-sm">
        <thead class="border-b border-gray-200 text-left text-xs uppercase tracking-wide text-grey">
          <tr>
            <th class="py-2">Organisation</th>
            <th class="py-2">Slug</th>
            <th class="py-2">Status</th>
            <th class="py-2"></th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100">
          <tr :for={org <- @organisations}>
            <td class="py-3 font-medium text-gray-900">{org.name}</td>
            <td class="py-3 font-mono text-xs text-grey">{org.slug}</td>
            <td class="py-3">
              <span class={[
                "rounded-full px-2 py-0.5 text-xs font-semibold",
                status_class(org)
              ]}>
                {status_label(org)}
              </span>
            </td>
            <td class="py-3 text-right">
              <button
                type="button"
                class="text-xs font-semibold text-brand-primary"
                phx-click="add-admin-for"
                phx-value-id={org.id}
              >
                Add admin
              </button>
              <button
                type="button"
                class="ml-4 text-xs font-semibold text-grey"
                phx-click="toggle-active"
                phx-value-id={org.id}
              >
                {if org.is_active, do: "Deactivate", else: "Activate"}
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  defp status_label(%{is_active: true}), do: "Active"
  defp status_label(%{approved_at: nil}), do: "Pending"
  defp status_label(_), do: "Suspended"

  defp status_class(%{is_active: true}), do: "bg-green-100 text-green-800"
  defp status_class(%{approved_at: nil}), do: "bg-amber-100 text-amber-800"
  defp status_class(_), do: "bg-red-100 text-red-800"
end
