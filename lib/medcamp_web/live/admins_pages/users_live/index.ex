defmodule MedcampWeb.AdminUsersLive.Index do
  use MedcampWeb, :admin_live_view
  alias Medcamp.Accounts
  alias Medcamp.Notify

  @per_page 10

  @default_filters %{is_active: "", role: "", search: ""}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :users)
     |> assign(:reset_link, "")
     |> assign(:filters, @default_filters)
     |> assign(:roles, Accounts.User.roles())
     |> assign(:selected_user, nil)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_users()}
  end


  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit User")
    |> assign(:user, Accounts.get_user!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New User")
    |> assign(:user, %Accounts.User{})
  end

  defp apply_action(socket, :user_code, %{"id" => id}) do
    socket
    |> assign(:page_title, "Show User")
    |> assign(:user, Accounts.get_user!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "System Users")
    |> assign(:user, nil)
  end

  @impl true
  def handle_event("show_user_details", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)

    {:noreply,
     socket
     |> assign(:selected_user, user)}
  end

  @impl true
  def handle_event("close_user_details", _params, socket) do
    {:noreply,
     socket
     |> assign(:selected_user, nil)}
  end

  @impl true
  def handle_event("reset-password", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    token = Accounts.get_reset_password_link_for_user(user)
    reset_link = "http://glocalhealthcentre.org/users/reset_password/" <> token

    spawn(fn ->
      Notify.send_reset_password_link(user.email, user.name, reset_link)
    end)

    {:noreply,
     socket
     |> assign(:reset_link, reset_link)
     |> put_flash(:info, "Reset password link sent to #{user.email}")}
  end

  @impl true
  def handle_event("filter", %{"filters" => filters}, socket) do
    filters = Map.merge(stringify_filters(socket.assigns.filters), filters)

    filter_params = %{
      is_active: nilify(filters["is_active"]),
      role: nilify(filters["role"]),
      search: nilify(filters["search"])
    }

    {:noreply,
     socket
     |> assign(:filters, %{
       is_active: filters["is_active"] || "",
       role: filters["role"] || "",
       search: filters["search"] || ""
     })
     |> assign(:page, 1)
     |> load_users(filter_params)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, @default_filters)
     |> assign(:page, 1)
     |> load_users()}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    handle_event("filter", %{"filters" => %{field => ""}}, socket)
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, socket |> assign(:page, max(1, String.to_integer(page))) |> load_users()}
  end

  defp nilify(""), do: nil
  defp nilify(val), do: val && String.trim(val)

  # The search box and the filter drawer submit independently (two separate
  # <form>s), so a submission from either one only carries its own fields.
  # Merging onto a stringified version of the current filters (whose keys
  # are atoms, unlike the string-keyed params Phoenix sends) means a key
  # absent from this submission is left unchanged rather than reset.
  defp stringify_filters(filters) do
    Map.new(filters, fn {key, value} -> {Atom.to_string(key), value} end)
  end

  defp load_users(socket, filters \\ nil) do
    filters = filters || socket.assigns.filters
    page = socket.assigns[:page] || 1
    per_page = socket.assigns[:per_page] || @per_page

    user_count = Accounts.count_users(filters)
    total_pages = Medcamp.Pagination.total_pages(user_count, per_page)
    page = min(max(1, page), total_pages)
    users = Accounts.list_users_paginated(filters, page, per_page)

    socket
    |> assign(:page, page)
    |> assign(:user_count, user_count)
    |> assign(:total_count, user_count)
    |> assign(:total_pages, total_pages)
    |> assign(:users, users)
  end

  defp count_active_filters(filters) do
    filters
    |> Map.take([:is_active, :role])
    |> Map.values()
    |> Enum.count(&(&1 not in [nil, ""]))
  end

  defp filter_chips(filters) do
    [
      filter_chip(filters.is_active, "is_active", is_active_label(filters.is_active)),
      filter_chip(filters.role, "role", filters.role)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp is_active_label("true"), do: "Active"
  defp is_active_label("false"), do: "Inactive"
  defp is_active_label(other), do: other

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 px-6 py-5">
        <.page_header
          icon_path="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0 0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0Zm8.25 2.25a2.625 2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z"
          title="System Users"
          subtitle={"#{@user_count} user#{if @user_count != 1, do: "s", else: ""} found"}
        >
          <:actions>
            <.link patch="/admin/users/new">
              <button class="inline-flex items-center gap-2 rounded-lg bg-[#373896] px-4 py-2 text-sm font-medium text-white hover:bg-[#2d2d7a]">
                <Heroicons.icon name="plus" type="outline" class="h-4 w-4" /> Add User
              </button>
            </.link>
          </:actions>
        </.page_header>

        <div class="flex flex-wrap items-center gap-3">
          <form phx-change="filter" class="flex-1">
            <.search_input
              name="filters[search]"
              value={@filters.search}
              placeholder="Search by name or email"
            />
          </form>

          <.filter_drawer
            id="users-filters"
            title="Filter users"
            apply_event="filter"
            active_count={count_active_filters(@filters)}
          >
            <:group label="Status and Role">
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">Status</label>
                <select
                  name="filters[is_active]"
                  class="w-full h-9 rounded-md border border-gray-300 px-2 text-sm focus:border-[#6667ab] focus:ring-[#6667ab]"
                >
                  <option value="">All statuses</option>
                  <option value="true" selected={@filters.is_active == "true"}>Active</option>
                  <option value="false" selected={@filters.is_active == "false"}>Inactive</option>
                </select>
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">Role</label>
                <select
                  name="filters[role]"
                  class="w-full h-9 rounded-md border border-gray-300 px-2 text-sm focus:border-[#6667ab] focus:ring-[#6667ab]"
                >
                  <option value="">All roles</option>
                  <%= for role <- @roles do %>
                    <option value={role} selected={@filters.role == role}>{role}</option>
                  <% end %>
                </select>
              </div>
            </:group>

            <:chip
              :for={chip <- filter_chips(@filters)}
              label={chip.label}
              clear={JS.push("clear_chip", value: %{"field" => chip.field})}
            />
          </.filter_drawer>
        </div>
      </div>

      <%!-- Table --%>
      <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 overflow-hidden">
        <%= if Enum.empty?(@users) do %>
          <.blank_state
            icon_path="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0 0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0Zm8.25 2.25a2.625 2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z"
            title="No users found"
            description={
              if @filters.search != "" or count_active_filters(@filters) > 0,
                do: "No users match the current filters.",
                else: "No users have been registered yet."
            }
          >
            <:actions :if={@filters.search != "" or count_active_filters(@filters) > 0}>
              <button phx-click="clear_filters" class="text-xs text-[#6667ab] hover:underline">
                Clear filters
              </button>
            </:actions>
          </.blank_state>
        <% else %>
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-5 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  User
                </th>
                <th class="px-5 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Role
                </th>
                <th class="px-5 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Status
                </th>
                <th class="px-5 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  OTP
                </th>
                <th class="px-5 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Last Login
                </th>
                <th class="px-5 py-3 text-right text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 bg-white" id="users-table">
              <%= for user <- @users do %>
                <tr
                  id={"user-#{user.id}"}
                  class="hover:bg-gray-50 cursor-pointer transition-colors"
                  phx-click="show_user_details"
                  phx-value-id={user.id}
                >
                  <%!-- User --%>
                  <td class="px-5 py-3">
                    <div class="flex items-center gap-3">
                      <%= if user.image do %>
                        <img src={user.image} class="h-9 w-9 rounded-full object-cover shrink-0" />
                      <% else %>
                        <div class="h-9 w-9 rounded-full bg-[#e7e7ff] flex items-center justify-center text-[#373896] font-semibold text-sm shrink-0">
                          {String.first(user.name || "?")}
                        </div>
                      <% end %>
                      <div>
                        <p class="font-medium text-gray-900 text-sm">{user.name}</p>
                        <p class="text-xs text-gray-500">{user.email}</p>
                      </div>
                    </div>
                  </td>
                  <%!-- Role --%>
                  <td class="px-5 py-3">
                    <span class="inline-flex items-center rounded-full bg-[#f0f0ff] px-2.5 py-0.5 text-xs font-medium text-[#373896]">
                      {user.role}
                    </span>
                  </td>
                  <%!-- Status --%>
                  <td class="px-5 py-3">
                    <%= if user.is_active do %>
                      <span class="inline-flex items-center gap-1 rounded-full bg-green-50 px-2.5 py-0.5 text-xs font-medium text-green-700 ring-1 ring-green-600/20">
                        <span class="h-1.5 w-1.5 rounded-full bg-green-500"></span> Active
                      </span>
                    <% else %>
                      <span class="inline-flex items-center gap-1 rounded-full bg-red-50 px-2.5 py-0.5 text-xs font-medium text-red-700 ring-1 ring-red-600/20">
                        <span class="h-1.5 w-1.5 rounded-full bg-red-500"></span> Inactive
                      </span>
                    <% end %>
                  </td>
                  <%!-- OTP --%>
                  <td class="px-5 py-3">
                    <%= if user.otp do %>
                      <span class="inline-flex items-center rounded-full bg-amber-50 px-2.5 py-0.5 text-xs font-mono font-semibold text-amber-700 ring-1 ring-amber-600/20">
                        {user.otp}
                      </span>
                    <% else %>
                      <span class="text-xs text-gray-400">—</span>
                    <% end %>
                  </td>
                  <%!-- Last Login --%>
                  <td class="px-5 py-3 text-xs text-gray-500">
                    {format_datetime_kenya(user.last_logged_in_at)}
                  </td>
                  <%!-- Actions — stop propagation so row-click doesn't fire --%>
                  <td class="px-5 py-3 text-right" phx-click="" phx-stop-propagation="">
                    <div class="flex items-center justify-end gap-2">
                      <.link
                        navigate={~p"/admin/users/#{user}/edit"}
                        class="inline-flex items-center gap-1 rounded-md px-2.5 py-1.5 text-xs font-medium text-[#6667ab] hover:bg-[#f0f0ff]"
                        phx-click=""
                      >
                        <Heroicons.icon name="pencil-square" type="outline" class="h-3.5 w-3.5" />
                        Edit
                      </.link>
                      <.link
                        navigate={~p"/admin/users/#{user}/permissions"}
                        class="inline-flex items-center gap-1 rounded-md px-2.5 py-1.5 text-xs font-medium text-[#6667ab] hover:bg-[#f0f0ff]"
                        phx-click=""
                      >
                        <Heroicons.icon name="key" type="outline" class="h-3.5 w-3.5" /> Panels
                      </.link>
                      <.link
                        navigate={~p"/admin/users/#{user.email}"}
                        class="inline-flex items-center gap-1 rounded-md px-2.5 py-1.5 text-xs font-medium text-white bg-[#373896] hover:bg-[#2d2d7a]"
                        phx-click=""
                      >
                        Access
                      </.link>
                    </div>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
          <.pagination
            page={@page}
            total_pages={@total_pages}
            total_count={@user_count}
            per_page={@per_page}
          />
        <% end %>
      </div>
    </div>

    <%!-- ── User Detail Popup ── --%>
    <%= if @selected_user do %>
      <% u = @selected_user %>
      <div
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm"
        phx-click="close_user_details"
      >
        <div
          class="relative w-full max-w-lg bg-white rounded-2xl shadow-2xl overflow-hidden"
          phx-click=""
        >
          <%!-- Header bar --%>
          <div class="bg-[#373896] px-6 py-5 flex items-center gap-4">
            <%= if u.image do %>
              <img
                src={u.image}
                class="h-14 w-14 rounded-full object-cover ring-2 ring-white/40 shrink-0"
              />
            <% else %>
              <div class="h-14 w-14 rounded-full bg-white/20 flex items-center justify-center text-white font-bold text-xl shrink-0">
                {String.first(u.name || "?")}
              </div>
            <% end %>
            <div class="flex-1 min-w-0">
              <p class="text-lg font-bold text-white truncate">{u.name}</p>
              <p class="text-sm text-blue-200 truncate">{u.email}</p>
              <div class="flex items-center gap-2 mt-1">
                <span class="inline-flex items-center rounded-full bg-white/20 px-2 py-0.5 text-xs font-medium text-white">
                  {u.role}
                </span>
                <%= if u.is_active do %>
                  <span class="inline-flex items-center gap-1 rounded-full bg-green-400/30 px-2 py-0.5 text-xs font-medium text-green-100">
                    <span class="h-1.5 w-1.5 rounded-full bg-green-300"></span> Active
                  </span>
                <% else %>
                  <span class="inline-flex items-center gap-1 rounded-full bg-red-400/30 px-2 py-0.5 text-xs font-medium text-red-100">
                    <span class="h-1.5 w-1.5 rounded-full bg-red-300"></span> Inactive
                  </span>
                <% end %>
              </div>
            </div>
            <button
              phx-click="close_user_details"
              class="shrink-0 p-1.5 rounded-lg text-white/70 hover:bg-white/10"
            >
              <Heroicons.icon name="x-mark" type="outline" class="h-5 w-5" />
            </button>
          </div>

          <%!-- Detail grid --%>
          <div class="px-6 py-5 grid grid-cols-2 gap-x-6 gap-y-4 text-sm">
            <div>
              <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-0.5">Phone</p>
              <p class="text-gray-800">{u.phone_number || "—"}</p>
            </div>
            <div>
              <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-0.5">
                ID Number
              </p>
              <p class="text-gray-800">{u.id_number || "—"}</p>
            </div>
            <div>
              <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-0.5">
                License No.
              </p>
              <p class="text-gray-800">{u.license_number || "—"}</p>
            </div>
            <div>
              <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-0.5">GSRN</p>
              <p class="font-mono text-gray-800 text-xs">{u.gsrn || "—"}</p>
            </div>
            <div>
              <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-0.5">OTP</p>
              <p class="font-mono text-gray-800 text-sm font-semibold">{u.otp || "—"}</p>
            </div>
            <div>
              <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-0.5">
                Last Login
              </p>
              <p class="text-gray-800">{format_datetime_kenya(u.last_logged_in_at)}</p>
            </div>
            <div>
              <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-0.5">
                Last Logout
              </p>
              <p class="text-gray-800">{format_datetime_kenya(u.last_logged_out_at)}</p>
            </div>
          </div>

          <%!-- Action buttons --%>
          <div class="border-t border-gray-100 px-6 py-4 flex flex-wrap items-center gap-2 bg-gray-50">
            <.link
              navigate={~p"/admin/users/#{u}/edit"}
              class="inline-flex items-center gap-1.5 rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-sm font-medium text-gray-700 hover:bg-gray-50"
            >
              <Heroicons.icon name="pencil-square" type="outline" class="h-4 w-4" /> Edit
            </.link>
            <.link
              navigate={"/admin/users/#{u.id}/user_code"}
              class="inline-flex items-center gap-1.5 rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-sm font-medium text-gray-700 hover:bg-gray-50"
            >
              <Heroicons.icon name="qr-code" type="outline" class="h-4 w-4" /> User Code
            </.link>
            <.link
              navigate={"/admin/users/#{u.id}/permissions"}
              class="inline-flex items-center gap-1.5 rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-sm font-medium text-gray-700 hover:bg-gray-50"
            >
              <Heroicons.icon name="key" type="outline" class="h-4 w-4" /> Panels
            </.link>
            <button
              phx-click="reset-password"
              phx-value-id={u.id}
              phx-disable-with="Sending…"
              class="inline-flex items-center gap-1.5 rounded-lg border border-amber-300 bg-amber-50 px-3 py-1.5 text-sm font-medium text-amber-700 hover:bg-amber-100"
            >
              <Heroicons.icon name="key" type="outline" class="h-4 w-4" /> Reset Password
            </button>
            <.link
              navigate={~p"/admin/users/#{u.email}"}
              class="inline-flex items-center gap-1.5 rounded-lg bg-[#373896] px-3 py-1.5 text-sm font-medium text-white hover:bg-[#2d2d7a]"
            >
              <Heroicons.icon name="arrow-right-on-rectangle" type="outline" class="h-4 w-4" />
              Access Account
            </.link>
          </div>
        </div>
      </div>
    <% end %>

    <%!-- Edit / New modal --%>
    <.modal
      :if={@live_action in [:new, :edit]}
      id="user-modal"
      show
      on_cancel={JS.patch(~p"/admin/users")}
    >
      <.live_component
        module={MedcampWeb.AdminUsersLive.FormComponent}
        id={:new}
        title={@page_title}
        current_user={@current_user}
        user={@user}
        action={@live_action}
        patch={~p"/admin/users"}
      />
    </.modal>

    <%!-- User code modal --%>
    <.modal
      :if={@live_action in [:user_code]}
      id="user-code-modal"
      show
      on_cancel={JS.patch(~p"/admin/users")}
    >
      <.live_component
        module={MedcampWeb.AdminUsersLive.StaffCodeComponent}
        id={:user_code}
        title={@page_title}
        current_user={@current_user}
        user={@user}
        action={@live_action}
        patch={~p"/admin/users"}
      />
    </.modal>
    """
  end
end
