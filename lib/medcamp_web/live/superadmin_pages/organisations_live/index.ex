defmodule MedcampWeb.SuperadminOrganisationsLive.Index do
  @moduledoc """
  Provisioning console: the searchable, paginated list of every organisation,
  plus create and quick-approve of pending signups. Per-organisation management
  (edit, reject-with-reason, deactivate/reactivate, admin users, camp drilldown)
  lives on `MedcampWeb.SuperadminOrganisationsLive.Show`.

  Sits outside every tenant, so all of its queries pass `skip_org_id: true` -
  it is the one place in the app that is allowed to see across organisations,
  and it is reachable only by a user with `is_superadmin` set directly in the
  database.
  """

  use MedcampWeb, :superadmin_live_view

  alias Medcamp.Organisations
  alias Medcamp.Organisations.Organisation

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :organisations)
     |> assign(:page_title, "Organisations")
     |> assign(:current_organisation, nil)
     |> assign(:search, "")
     |> assign(:page, 1)
     |> assign(:per_page, 10)
     |> assign(:form, to_form(Organisations.change_organisation(%Organisation{}), as: "org"))
     |> load_organisations()}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Organisation")
    |> assign(:form, to_form(Organisations.change_organisation(%Organisation{}), as: "org"))
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, "Organisations")
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
         |> load_organisations()
         |> push_navigate(to: ~p"/superadmin/organisations/#{organisation.id}/admin/new")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: "org"))}
    end
  end

  def handle_event("approve", %{"id" => id}, socket) do
    {:ok, organisation} = id |> Organisations.get_organisation!() |> Organisations.approve()
    notify_approved_admins(organisation)

    {:noreply,
     socket
     |> put_flash(:info, "#{organisation.name} approved. Admin setup email sent.")
     |> load_organisations()}
  end

  def handle_event("search", %{"search" => term}, socket) do
    {:noreply, socket |> assign(:search, term) |> assign(:page, 1) |> load_organisations()}
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, Medcamp.Pagination.normalize_page(page))
     |> load_organisations()}
  end

  defp load_organisations(socket) do
    %{rows: rows, count: count} =
      Organisations.paged_organisations(
        search: socket.assigns.search,
        page: socket.assigns.page,
        per_page: socket.assigns.per_page
      )

    socket
    |> assign(:organisations, rows)
    |> assign(:total_count, count)
    |> assign(:total_pages, Medcamp.Pagination.total_pages(count, socket.assigns.per_page))
    |> assign(:pending, Organisations.list_pending_organisations())
  end

  defp notify_approved_admins(organisation) do
    organisation.id
    |> Medcamp.Accounts.list_admins_for_organisation()
    |> Enum.each(fn admin ->
      token = Medcamp.Accounts.get_reset_password_link_for_user(admin)
      url = MedcampWeb.Endpoint.url() <> "/users/reset_password/" <> token

      Task.start(fn ->
        Medcamp.Postal.deliver_organisation_approved_instructions(admin, organisation, url)
      end)
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="rounded-2xl border border-slate-200 bg-white shadow-card p-6">
        <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <h1 class="text-2xl font-bold tracking-[-0.01em] text-[#0C2765]">Organisations</h1>
            <p class="mt-2 text-sm leading-relaxed text-slate-600">
              Create tenant workspaces, approve self-service signups, and open each
              organisation's medical camp dashboard.
            </p>
          </div>
          <.link
            patch={~p"/superadmin/organisations/new"}
            class="inline-flex shrink-0 items-center justify-center gap-2 rounded-full bg-[#0C2765] px-5 py-2.5 text-sm font-semibold text-white transition-colors duration-150 hover:bg-[#16418f]"
          >
            <Heroicons.icon name="plus" type="outline" class="h-4 w-4" /> Add organisation
          </.link>
        </div>
      </div>

      <div
        :if={@pending != []}
        class="overflow-hidden rounded-2xl border border-amber-200 bg-amber-50"
      >
        <div class="flex items-start gap-3 px-5 py-4">
          <Heroicons.icon
            name="exclamation-triangle"
            type="outline"
            class="mt-0.5 h-5 w-5 shrink-0 text-amber-700"
          />
          <div class="min-w-0 flex-1">
            <h2 class="text-sm font-bold text-amber-950">
              Awaiting approval ({length(@pending)})
            </h2>
            <p class="mt-1 text-sm leading-5 text-amber-800">
              These organisations signed up themselves. Their staff cannot log in until approved.
            </p>

            <ul class="mt-4 divide-y divide-amber-200">
              <li
                :for={org <- @pending}
                class="flex flex-col gap-3 py-3 sm:flex-row sm:items-center sm:justify-between"
              >
                <div class="min-w-0">
                  <p class="truncate text-sm font-semibold text-amber-950">{org.name}</p>
                  <p class="truncate text-xs text-amber-800">
                    {org.contact_name} · {org.email}{if org.location, do: " · #{org.location}"}
                  </p>
                </div>
                <button
                  type="button"
                  class="inline-flex min-h-9 shrink-0 items-center justify-center rounded-md bg-amber-700 px-3 text-xs font-semibold text-white transition hover:bg-amber-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-600 focus-visible:ring-offset-2"
                  phx-click="approve"
                  phx-value-id={org.id}
                >
                  Approve
                </button>
              </li>
            </ul>
          </div>
        </div>
      </div>

      <.modal
        :if={@live_action == :new}
        id="organisation-modal"
        show
        on_cancel={JS.patch(~p"/superadmin/organisations")}
      >
        <div class="flex items-center gap-3 border-b border-slate-200 pb-4">
          <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-[#e9f6fb] text-[#0C2765]">
            <Heroicons.icon name="building-office-2" type="outline" class="h-5 w-5" />
          </div>
          <div class="min-w-0 flex-1">
            <h2 class="text-base font-bold text-slate-950">New organisation</h2>
            <p class="text-sm text-slate-600">
              Set the organisation identity and default brand colours.
            </p>
          </div>
        </div>

        <.form for={@form} phx-change="validate" phx-submit="create" class="mt-5 space-y-5">
          <div class="grid grid-cols-1 gap-5 sm:grid-cols-2">
            <.input field={@form[:name]} type="text" label="Name" />
            <.input field={@form[:slug]} type="text" label="Slug" placeholder="acme-health" />
            <.input field={@form[:email]} type="email" label="Email" />
            <.input field={@form[:phone_number]} type="text" label="Phone number" />
            <.input field={@form[:location]} type="text" label="Location" />
            <.input field={@form[:primary_color]} type="color" label="Primary colour" />
            <.input field={@form[:accent_color]} type="color" label="Accent colour" />
          </div>

          <div class="flex items-center justify-end gap-3 border-t border-slate-200 pt-5">
            <button
              type="button"
              class="inline-flex items-center justify-center rounded-full border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-600 transition-colors duration-150 hover:bg-slate-50"
              phx-click={JS.patch(~p"/superadmin/organisations")}
            >
              Cancel
            </button>
            <button
              type="submit"
              phx-disable-with="Creating..."
              class="inline-flex items-center justify-center rounded-full bg-[#0C2765] px-5 py-2.5 text-sm font-semibold text-white transition-colors duration-150 hover:bg-[#16418f] phx-submit-loading:opacity-75"
            >
              Create organisation
            </button>
          </div>
        </.form>
      </.modal>

      <form phx-change="search">
        <div class="relative">
          <Heroicons.icon
            name="magnifying-glass"
            type="outline"
            class="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400"
          />
          <input
            type="text"
            name="search"
            value={@search}
            placeholder="Search organisations by name or slug"
            phx-debounce="300"
            class="h-10 w-full rounded-lg border border-slate-300 pl-9 pr-4 text-sm text-slate-900 placeholder:text-slate-400 focus:border-[#52B2D8] focus:outline-none focus:ring-0"
          />
        </div>
      </form>

      <.data_table id="platform-organisations" rows={@organisations} row_id={&"org-#{&1.id}"}>
        <:col :let={org} label="Organisation">
          <div class="flex items-center gap-3">
            <div class="flex h-9 w-9 shrink-0 items-center justify-center overflow-hidden rounded-xl border border-slate-200 bg-[#e9f6fb] text-xs font-bold text-[#0C2765]">
              <%= if org.logo do %>
                <img src={org.logo} alt={org.name} class="h-full w-full object-contain" />
              <% else %>
                {Medcamp.Organisations.initials(org)}
              <% end %>
            </div>
            <div class="min-w-0">
              <.link
                navigate={~p"/superadmin/organisations/#{org.id}"}
                class="truncate text-sm font-semibold text-slate-900 transition-colors duration-150 hover:text-[#0C2765]"
              >
                {org.name}
              </.link>
              <p :if={org.location} class="truncate text-xs text-slate-500">{org.location}</p>
            </div>
          </div>
        </:col>
        <:col :let={org} label="Slug" class="text-xs italic text-slate-400" hide_below="sm">
          {org.slug}
        </:col>
        <:col :let={org} label="Status">
          <.organisation_status_pill organisation={org} />
        </:col>
        <:action :let={org}>
          <.link
            navigate={~p"/superadmin/organisations/#{org.id}/medical-camp"}
            class="inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-sm font-semibold text-[#0C2765] transition-colors duration-150 hover:bg-[#e9f6fb]"
          >
            <Heroicons.icon name="chart-bar-square" type="outline" class="h-4 w-4" /> Camp dashboard
          </.link>
          <.link
            navigate={~p"/superadmin/organisations/#{org.id}"}
            class="inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-sm font-semibold text-[#0C2765] transition-colors duration-150 hover:bg-[#e9f6fb]"
          >
            <Heroicons.icon name="cog-6-tooth" type="outline" class="h-4 w-4" /> Manage
          </.link>
        </:action>
        <:empty>
          {if @search == "",
            do: "No organisations yet.",
            else: "No organisations match “#{@search}”."}
        </:empty>
        <:footer>
          <.pagination
            page={@page}
            total_pages={@total_pages}
            total_count={@total_count}
            per_page={@per_page}
          />
        </:footer>
      </.data_table>
    </div>
    """
  end
end
