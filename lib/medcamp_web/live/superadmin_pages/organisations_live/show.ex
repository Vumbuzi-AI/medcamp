defmodule MedcampWeb.SuperadminOrganisationsLive.Show do
  @moduledoc """
  Superadmin detail view for one organisation: its profile, lifecycle state
  (pending / active / suspended / rejected), the actions that move it between
  those states, and its admin users.

  Sits outside every tenant, so its queries run unscoped and it is reachable
  only by a user with `is_superadmin` set in the database.
  """

  use MedcampWeb, :superadmin_live_view

  alias Medcamp.Accounts
  alias Medcamp.Organisations
  alias Medcamp.Tenancy

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    organisation = Organisations.get_organisation!(id)

    {:ok,
     socket
     |> assign(:active_tab, :organisations)
     |> assign(:confirm, nil)
     |> assign(:admin_form, nil)
     |> assign(:reject_form, nil)
     |> assign(:form, nil)
     |> assign(:admin_search, "")
     |> assign(:admin_page, 1)
     |> assign(:admin_per_page, 10)
     |> assign_organisation(organisation)}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action)}
  end

  defp apply_action(socket, :edit) do
    assign(
      socket,
      :form,
      to_form(Organisations.change_organisation(socket.assigns.organisation), as: "org")
    )
  end

  defp apply_action(socket, :add_admin) do
    assign(
      socket,
      :admin_form,
      to_form(Accounts.change_admin_invitation(), as: "admin")
    )
  end

  defp apply_action(socket, :reject) do
    assign(socket, :reject_form, to_form(%{"reason" => ""}, as: "reject"))
  end

  defp apply_action(socket, :show), do: socket

  @impl true
  def handle_event("validate-edit", %{"org" => params}, socket) do
    changeset =
      Organisations.change_organisation(socket.assigns.organisation, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: "org"))}
  end

  def handle_event("save-edit", %{"org" => params}, socket) do
    case Organisations.update_organisation(socket.assigns.organisation, params) do
      {:ok, organisation} ->
        {:noreply,
         socket
         |> put_flash(:info, "Organisation updated.")
         |> assign_organisation(organisation)
         |> push_patch(to: ~p"/superadmin/organisations/#{organisation.id}")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: "org"))}
    end
  end

  def handle_event("add-admin", %{"admin" => params}, socket) do
    organisation = socket.assigns.organisation

    result =
      Tenancy.with_org(organisation.id, fn ->
        Accounts.create_admin_invitation(%{
          "name" => params["name"],
          "email" => params["email"]
        })
      end)

    case result do
      {:ok, %{user: user, token: token}} ->
        send_admin_invitation(user, organisation, token)

        {:noreply,
         socket
         |> put_flash(:info, "Admin invitation sent to #{user.email}.")
         |> assign_organisation(organisation)
         |> push_patch(to: ~p"/superadmin/organisations/#{organisation.id}")}

      {:error, changeset} ->
        {:noreply, assign(socket, :admin_form, to_form(changeset, as: "admin"))}
    end
  end

  def handle_event("reject", %{"reject" => %{"reason" => reason}}, socket) do
    reason = String.trim(reason || "")

    if reason == "" do
      {:noreply,
       assign(
         socket,
         :reject_form,
         to_form(%{"reason" => ""}, as: "reject", errors: [reason: {"Give a reason", []}])
       )}
    else
      {:ok, organisation} = Organisations.reject_organisation(socket.assigns.organisation, reason)

      {:noreply,
       socket
       |> put_flash(:info, "#{organisation.name} rejected.")
       |> assign_organisation(organisation)
       |> push_patch(to: ~p"/superadmin/organisations/#{organisation.id}")}
    end
  end

  def handle_event("approve", _params, socket) do
    {:ok, organisation} = Organisations.approve(socket.assigns.organisation)
    notify_approved_admins(organisation)

    {:noreply,
     socket
     |> put_flash(:info, "#{organisation.name} approved. Admin setup email sent.")
     |> assign_organisation(organisation)}
  end

  def handle_event("ask-deactivate", _params, socket) do
    {:noreply, assign(socket, :confirm, true)}
  end

  def handle_event("cancel-confirm", _params, socket) do
    {:noreply, assign(socket, :confirm, nil)}
  end

  def handle_event("toggle-active", _params, socket) do
    organisation = socket.assigns.organisation

    {:ok, organisation} =
      if organisation.is_active do
        Organisations.deactivate_organisation(organisation)
      else
        Organisations.approve(organisation)
      end

    {:noreply, socket |> assign(:confirm, nil) |> assign_organisation(organisation)}
  end

  def handle_event("toggle-admin-active", %{"id" => user_id}, socket) do
    if own_account?(socket, user_id) do
      {:noreply, put_flash(socket, :error, "You can't deactivate your own account from here.")}
    else
      user = Accounts.get_user_across_organisations(user_id)
      {:ok, _} = Accounts.set_user_active(user, not user.is_active)

      {:noreply,
       socket
       |> put_flash(
         :info,
         "#{user.email} #{if user.is_active, do: "deactivated", else: "reactivated"}."
       )
       |> assign_organisation(socket.assigns.organisation)}
    end
  end

  def handle_event("reset-admin-password", %{"id" => user_id}, socket) do
    user = Accounts.get_user_across_organisations(user_id)
    token = Accounts.get_reset_password_link_for_user(user)
    url = MedcampWeb.Endpoint.url() <> "/users/reset_password/" <> token

    spawn(fn -> Medcamp.Postal.deliver_reset_password_instructions(user, url) end)

    {:noreply, put_flash(socket, :info, "Password reset link sent to #{user.email}.")}
  end

  def handle_event("search-admins", %{"search" => term}, socket) do
    {:noreply, socket |> assign(:admin_search, term) |> assign(:admin_page, 1) |> load_admins()}
  end

  def handle_event("paginate-admins", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:admin_page, Medcamp.Pagination.normalize_page(page))
     |> load_admins()}
  end

  defp notify_approved_admins(organisation) do
    organisation.id
    |> Accounts.list_admins_for_organisation()
    |> Enum.each(fn admin ->
      token = Accounts.get_reset_password_link_for_user(admin)
      url = MedcampWeb.Endpoint.url() <> "/users/reset_password/" <> token

      Task.start(fn ->
        Medcamp.Postal.deliver_organisation_approved_instructions(admin, organisation, url)
      end)
    end)
  end

  defp send_admin_invitation(user, organisation, token) do
    url = MedcampWeb.Endpoint.url() <> "/users/reset_password/" <> token

    Task.start(fn ->
      Medcamp.Postal.deliver_admin_invitation_instructions(user, organisation, url)
    end)
  end

  defp own_account?(socket, user_id) do
    to_string(socket.assigns.current_user.id) == to_string(user_id)
  end

  defp assign_organisation(socket, organisation) do
    socket
    |> assign(:organisation, organisation)
    |> assign(:page_title, organisation.name)
    |> load_admins()
  end

  defp load_admins(socket) do
    %{rows: rows, count: count} =
      Accounts.paged_admins_for_organisation(socket.assigns.organisation.id,
        search: socket.assigns.admin_search,
        page: socket.assigns.admin_page,
        per_page: socket.assigns.admin_per_page
      )

    socket
    |> assign(:admins, rows)
    |> assign(:admin_count, count)
    |> assign(
      :admin_total_pages,
      Medcamp.Pagination.total_pages(count, socket.assigns.admin_per_page)
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-5">
      <div class="rounded-2xl border border-slate-200 bg-white shadow-card p-6">
        <.link
          navigate={~p"/superadmin/organisations"}
          class="inline-flex items-center gap-1.5 text-sm font-semibold text-slate-500 transition-colors duration-150 hover:text-[#0C2765]"
        >
          <Heroicons.icon name="arrow-left" type="outline" class="h-4 w-4" /> Back to organisations
        </.link>

        <div class="mt-4 flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div class="flex items-center gap-4">
            <div class="flex h-12 w-12 shrink-0 items-center justify-center overflow-hidden rounded-xl border border-slate-200 bg-[#e9f6fb] text-sm font-bold text-[#0C2765]">
              <%= if @organisation.logo do %>
                <img src={@organisation.logo} alt="" class="h-full w-full object-contain" />
              <% else %>
                {Organisations.initials(@organisation)}
              <% end %>
            </div>
            <div class="min-w-0">
              <div class="flex flex-wrap items-center gap-2">
                <h1 class="text-2xl font-bold tracking-[-0.01em] text-[#0C2765]">
                  {@organisation.name}
                </h1>
                <.organisation_status_pill organisation={@organisation} />
              </div>
              <p class="mt-0.5 text-xs italic text-slate-400">{@organisation.slug}</p>
            </div>
          </div>

          <div class="flex shrink-0 flex-wrap gap-2">
            <.link
              patch={~p"/superadmin/organisations/#{@organisation.id}/edit"}
              class="inline-flex items-center gap-1.5 rounded-full border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-700 transition-colors duration-150 hover:border-slate-400"
            >
              <Heroicons.icon name="pencil-square" type="outline" class="h-4 w-4" /> Edit
            </.link>
            <.link
              navigate={~p"/superadmin/organisations/#{@organisation.id}/medical-camp"}
              class="inline-flex items-center gap-1.5 rounded-full bg-[#0C2765] px-4 py-2 text-sm font-semibold text-white transition-colors duration-150 hover:bg-[#16418f]"
            >
              <Heroicons.icon name="chart-bar-square" type="outline" class="h-4 w-4" /> Camp dashboard
            </.link>
          </div>
        </div>
      </div>

      <div class="rounded-2xl border border-slate-200 bg-white shadow-card">
        <div class="flex flex-col gap-3 border-b border-slate-200 px-6 py-4 sm:flex-row sm:items-center sm:justify-between">
          <div class="min-w-0">
            <p class="text-xs font-semibold uppercase tracking-wider text-slate-500">Status</p>
            <p class="mt-1 text-sm text-slate-700">{lifecycle_hint(@organisation)}</p>
          </div>
          <div class="flex shrink-0 flex-wrap gap-2">
            <button
              :if={Organisations.pending?(@organisation)}
              type="button"
              phx-click="approve"
              class="inline-flex items-center justify-center rounded-full bg-[#0C2765] px-4 py-2 text-sm font-semibold text-white transition-colors duration-150 hover:bg-[#16418f]"
            >
              Approve signup
            </button>
            <.link
              :if={Organisations.pending?(@organisation)}
              patch={~p"/superadmin/organisations/#{@organisation.id}/reject"}
              class="inline-flex items-center justify-center rounded-full border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-600 transition-colors duration-150 hover:border-slate-400"
            >
              Reject…
            </.link>
            <button
              :if={@organisation.is_active}
              type="button"
              phx-click="ask-deactivate"
              class="inline-flex items-center justify-center rounded-full border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-600 transition-colors duration-150 hover:border-slate-400 hover:text-slate-900"
            >
              Deactivate
            </button>
            <button
              :if={not @organisation.is_active and not Organisations.pending?(@organisation)}
              type="button"
              phx-click="approve"
              class="inline-flex items-center justify-center rounded-full bg-[#0C2765] px-4 py-2 text-sm font-semibold text-white transition-colors duration-150 hover:bg-[#16418f]"
            >
              {if @organisation.rejected_at, do: "Approve anyway", else: "Reactivate"}
            </button>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-x-10 gap-y-8 p-6 text-sm sm:grid-cols-2 lg:grid-cols-3">
          <section>
            <h3 class="text-xs font-semibold uppercase tracking-wider text-slate-400">Contact</h3>
            <dl class="mt-3 space-y-2.5">
              <.detail label="Contact name" value={@organisation.contact_name} />
              <.detail label="Email" value={@organisation.email} />
              <.detail label="Phone" value={@organisation.phone_number} />
              <.detail label="Location" value={@organisation.location} />
            </dl>
          </section>

          <section>
            <h3 class="text-xs font-semibold uppercase tracking-wider text-slate-400">Lifecycle</h3>
            <dl class="mt-3 space-y-2.5">
              <.detail label="Created" value={fmt_date(@organisation.inserted_at)} />
              <.detail
                :if={@organisation.approved_at}
                label="Approved"
                value={fmt_date(@organisation.approved_at)}
              />
              <div :if={@organisation.rejected_at} class="flex gap-3">
                <dt class="w-28 shrink-0 text-slate-500">Rejected</dt>
                <dd class="min-w-0 text-slate-800">
                  {fmt_date(@organisation.rejected_at)} — {@organisation.rejection_reason}
                </dd>
              </div>
            </dl>
          </section>

          <section>
            <h3 class="text-xs font-semibold uppercase tracking-wider text-slate-400">Branding</h3>
            <dl class="mt-3 space-y-2.5">
              <div class="flex gap-3">
                <dt class="w-28 shrink-0 text-slate-500">Primary</dt>
                <dd class="flex min-w-0 items-center gap-2">
                  <span
                    class="h-4 w-4 shrink-0 rounded border border-slate-200"
                    style={"background:#{@organisation.primary_color}"}
                  />
                  <span class="font-mono text-xs text-slate-500">{@organisation.primary_color}</span>
                </dd>
              </div>
              <div class="flex gap-3">
                <dt class="w-28 shrink-0 text-slate-500">Accent</dt>
                <dd class="flex min-w-0 items-center gap-2">
                  <span
                    class="h-4 w-4 shrink-0 rounded border border-slate-200"
                    style={"background:#{@organisation.accent_color}"}
                  />
                  <span class="font-mono text-xs text-slate-500">{@organisation.accent_color}</span>
                </dd>
              </div>
              <.detail label="Logo" value={(@organisation.logo && "Custom") || "Default"} />
            </dl>
          </section>
        </div>
      </div>

      <div class="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-card">
        <div class="flex flex-col gap-3 border-b border-slate-200 px-5 py-4 sm:flex-row sm:items-center sm:justify-between">
          <h2 class="text-base font-semibold text-[#0C2765]">
            Admin users <span class="ml-1 text-sm font-normal text-slate-400">({@admin_count})</span>
          </h2>
          <div class="flex flex-col gap-2 sm:flex-row sm:items-center">
            <form phx-change="search-admins" class="sm:w-64">
              <div class="relative">
                <Heroicons.icon
                  name="magnifying-glass"
                  type="outline"
                  class="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400"
                />
                <input
                  type="text"
                  name="search"
                  value={@admin_search}
                  placeholder="Search by name or email"
                  phx-debounce="300"
                  class="h-9 w-full rounded-lg border border-slate-300 pl-9 pr-4 text-sm text-slate-900 placeholder:text-slate-400 focus:border-[#52B2D8] focus:outline-none focus:ring-0"
                />
              </div>
            </form>
            <.link
              patch={~p"/superadmin/organisations/#{@organisation.id}/admin/new"}
              class="inline-flex shrink-0 items-center justify-center gap-1.5 rounded-full bg-[#0C2765] px-4 py-2 text-sm font-semibold text-white transition-colors duration-150 hover:bg-[#16418f]"
            >
              <Heroicons.icon name="user-plus" type="outline" class="h-4 w-4" /> Add admin
            </.link>
          </div>
        </div>

        <.data_table id="organisation-admins" rows={@admins} row_id={&"admin-#{&1.id}"}>
          <:col :let={admin} label="Name">
            <p class="text-sm font-semibold text-slate-900">
              {admin.name}
              <span
                :if={admin.id == @current_user.id}
                class="ml-1 rounded bg-slate-100 px-1.5 py-0.5 text-xs font-medium text-slate-500"
              >
                You
              </span>
            </p>
            <p class="text-xs text-slate-500">{admin.email}</p>
          </:col>
          <:col :let={admin} label="Status">
            <span class={[
              "inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-medium ring-1",
              (admin.is_active && "bg-green-50 text-green-700 ring-green-600/20") ||
                "bg-red-50 text-red-700 ring-red-600/20"
            ]}>
              {if admin.is_active, do: "Active", else: "Deactivated"}
            </span>
          </:col>
          <:col :let={admin} label="Last sign-in" hide_below="md">
            {(admin.last_logged_in_at && fmt_date(admin.last_logged_in_at)) || "Never"}
          </:col>
          <:action :let={admin}>
            <button
              type="button"
              phx-click="reset-admin-password"
              phx-value-id={admin.id}
              class="inline-flex items-center rounded-full px-3 py-1.5 text-sm font-semibold text-[#0C2765] transition-colors duration-150 hover:bg-[#e9f6fb]"
            >
              Reset password
            </button>
            <button
              :if={admin.id != @current_user.id}
              type="button"
              phx-click="toggle-admin-active"
              phx-value-id={admin.id}
              class="inline-flex items-center rounded-full border border-slate-300 px-3 py-1.5 text-sm font-semibold text-slate-600 transition-colors duration-150 hover:border-slate-400 hover:text-slate-900"
            >
              {if admin.is_active, do: "Deactivate", else: "Activate"}
            </button>
            <span :if={admin.id == @current_user.id} class="px-3 py-1.5 text-sm text-slate-400">
              —
            </span>
          </:action>
          <:empty>
            {if @admin_search == "",
              do: "No admin accounts yet.",
              else: "No admins match “#{@admin_search}”."}
          </:empty>
          <:footer>
            <.pagination
              page={@admin_page}
              total_pages={@admin_total_pages}
              total_count={@admin_count}
              per_page={@admin_per_page}
              event="paginate-admins"
            />
          </:footer>
        </.data_table>
      </div>

      <.modal
        :if={@live_action == :edit && @form}
        id="edit-org-modal"
        show
        max_width="max-w-2xl"
        on_cancel={JS.patch(~p"/superadmin/organisations/#{@organisation.id}")}
      >
        <h2 class="text-base font-bold text-slate-950">Edit {@organisation.name}</h2>
        <.form for={@form} phx-change="validate-edit" phx-submit="save-edit" class="mt-5 space-y-5">
          <div class="grid grid-cols-1 gap-5 sm:grid-cols-2">
            <.input field={@form[:name]} type="text" label="Name" />
            <.input field={@form[:slug]} type="text" label="Slug" />
            <.input field={@form[:email]} type="email" label="Email" />
            <.input field={@form[:phone_number]} type="text" label="Phone number" />
            <.input field={@form[:location]} type="text" label="Location" />
            <.input field={@form[:contact_name]} type="text" label="Contact name" />
            <.input field={@form[:primary_color]} type="color" label="Primary colour" />
            <.input field={@form[:accent_color]} type="color" label="Accent colour" />
          </div>
          <div class="flex items-center justify-end gap-3 border-t border-slate-200 pt-5">
            <button
              type="button"
              phx-click={JS.patch(~p"/superadmin/organisations/#{@organisation.id}")}
              class="inline-flex items-center justify-center rounded-full border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-600 transition-colors duration-150 hover:bg-slate-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              phx-disable-with="Saving..."
              class="inline-flex items-center justify-center rounded-full bg-[#0C2765] px-5 py-2.5 text-sm font-semibold text-white transition-colors duration-150 hover:bg-[#16418f]"
            >
              Save changes
            </button>
          </div>
        </.form>
      </.modal>

      <.modal
        :if={@live_action == :add_admin && @admin_form}
        id="add-admin-modal"
        show
        max_width="max-w-2xl"
        on_cancel={JS.patch(~p"/superadmin/organisations/#{@organisation.id}")}
      >
        <h2 class="text-base font-bold text-slate-950">Add an admin to {@organisation.name}</h2>
        <p class="mt-1 text-sm text-slate-600">
          We'll email this person a secure link to set their own password.
        </p>
        <.form for={@admin_form} phx-submit="add-admin" class="mt-5 space-y-5">
          <div class="grid grid-cols-1 gap-5 sm:grid-cols-2">
            <.input field={@admin_form[:name]} type="text" label="Name" required />
            <.input field={@admin_form[:email]} type="email" label="Email" required />
          </div>
          <div class="flex items-center justify-end gap-3 border-t border-slate-200 pt-5">
            <button
              type="button"
              phx-click={JS.patch(~p"/superadmin/organisations/#{@organisation.id}")}
              class="inline-flex items-center justify-center rounded-full border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-600 transition-colors duration-150 hover:bg-slate-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              phx-disable-with="Sending..."
              class="inline-flex items-center justify-center rounded-full bg-[#0C2765] px-5 py-2.5 text-sm font-semibold text-white transition-colors duration-150 hover:bg-[#16418f]"
            >
              Send invite
            </button>
          </div>
        </.form>
      </.modal>

      <.modal
        :if={@live_action == :reject && @reject_form}
        id="reject-org-modal"
        show
        max_width="max-w-lg"
        on_cancel={JS.patch(~p"/superadmin/organisations/#{@organisation.id}")}
      >
        <h2 class="text-base font-bold text-slate-950">Reject {@organisation.name}?</h2>
        <p class="mt-1 text-sm text-slate-600">
          The organisation stays inactive and its admin can't sign in. The reason is kept
          on the record.
        </p>
        <.form for={@reject_form} phx-submit="reject" class="mt-5 space-y-5">
          <.input
            field={@reject_form[:reason]}
            type="textarea"
            label="Reason"
            placeholder="e.g. Could not verify the organisation."
          />
          <div class="flex items-center justify-end gap-3 border-t border-slate-200 pt-5">
            <button
              type="button"
              phx-click={JS.patch(~p"/superadmin/organisations/#{@organisation.id}")}
              class="inline-flex items-center justify-center rounded-full border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-600 transition-colors duration-150 hover:bg-slate-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              phx-disable-with="Rejecting..."
              class="inline-flex items-center justify-center rounded-full bg-red-600 px-5 py-2.5 text-sm font-semibold text-white transition-colors duration-150 hover:bg-red-700"
            >
              Reject signup
            </button>
          </div>
        </.form>
      </.modal>

      <.confirm_dialog
        :if={@confirm}
        id="deactivate-org-dialog"
        title={"Deactivate #{@organisation.name}?"}
        body="Its staff are signed out and can't log in until it's reactivated."
        on_cancel={JS.push("cancel-confirm")}
      >
        <:confirm>
          <button
            type="button"
            phx-click="toggle-active"
            class="inline-flex items-center justify-center rounded-full bg-red-600 px-4 py-2 text-sm font-semibold text-white transition-colors duration-150 hover:bg-red-700"
          >
            Deactivate
          </button>
        </:confirm>
      </.confirm_dialog>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, required: true

  defp detail(assigns) do
    ~H"""
    <div class="flex gap-3">
      <dt class="w-28 shrink-0 text-slate-500">{@label}</dt>
      <dd class="min-w-0 break-words text-slate-800">{@value || "—"}</dd>
    </div>
    """
  end

  defp lifecycle_hint(%{is_active: true}), do: "Active — staff can sign in."

  defp lifecycle_hint(%{rejected_at: %DateTime{}}),
    do: "Rejected — the signup was declined."

  defp lifecycle_hint(%{approved_at: nil}),
    do: "Pending — approve or reject this self-serve signup."

  defp lifecycle_hint(_), do: "Suspended — reactivate to let staff sign in again."

  defp fmt_date(nil), do: "—"
  defp fmt_date(%DateTime{} = dt), do: Calendar.strftime(dt, "%d %b %Y")
  defp fmt_date(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%d %b %Y")
end
