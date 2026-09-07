defmodule MedcampWeb.AdminStockTakeLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.Departments
  alias Medcamp.StockTakes
  alias Medcamp.StockTakes.StockTake

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    departments = Departments.list_departments_for_selection()

    {:ok,
     socket
     |> assign(:active_tab, :stock_takes)
     |> assign(:departments, departments)
     |> assign(:department_id, nil)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:show_new_form, false)
     |> assign(:deleting_stock_take, nil)
     |> assign(:form, to_form(StockTakes.change_stock_take(%StockTake{})))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    dept_param = params["department_id"]
    page_param = params["page"]

    department_id =
      if is_binary(dept_param) and dept_param != "" do
        Enum.find_value(socket.assigns.departments, fn {_name, id} ->
          if to_string(id) == dept_param, do: to_string(id), else: nil
        end)
      else
        nil
      end

    page =
      case Integer.parse(to_string(page_param)) do
        {p, _} when p > 0 -> p
        _ -> 1
      end

    {:noreply,
     socket
     |> assign(:department_id, department_id)
     |> assign(:page, page)
     |> load_stock_takes()}
  end

  defp load_stock_takes(socket) do
    department_id = socket.assigns.department_id
    total_count = StockTakes.count_stock_takes(department_id)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    stock_takes =
      StockTakes.list_stock_takes_paginated(page, socket.assigns.per_page, department_id)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:stock_takes, stock_takes)
  end

  @impl true
  def handle_event("show_new_form", _, socket) do
    {:noreply,
     socket
     |> assign(:show_new_form, true)
     |> assign(:form, to_form(StockTakes.change_stock_take(%StockTake{})))}
  end

  @impl true
  def handle_event("cancel_new", _, socket) do
    {:noreply, assign(socket, :show_new_form, false)}
  end

  @impl true
  def handle_event("confirm_delete", %{"id" => id}, socket) do
    stock_take = StockTakes.get_stock_take!(id)
    {:noreply, assign(socket, :deleting_stock_take, stock_take)}
  end

  @impl true
  def handle_event("cancel_delete", _, socket) do
    {:noreply, assign(socket, :deleting_stock_take, nil)}
  end

  @impl true
  def handle_event("execute_delete", _, socket) do
    if stock_take = socket.assigns.deleting_stock_take do
      case StockTakes.delete_requester_stock_take(stock_take) do
        {:ok, _} ->
          {:noreply,
           socket
           |> put_flash(:info, "Stock take deleted.")
           |> assign(:deleting_stock_take, nil)
           |> load_stock_takes()}

        {:error, _} ->
          {:noreply,
           socket
           |> put_flash(:error, "Completed or approved stock takes cannot be deleted.")
           |> assign(:deleting_stock_take, nil)}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("filter_department", %{"department_id" => dept_id}, socket) do
    {:noreply, push_patch(socket, to: build_path(dept_id, 1))}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, push_patch(socket, to: build_path(socket.assigns.department_id, page))}
  end

  @impl true
  def handle_event("validate", %{"stock_take" => params}, socket) do
    form = to_form(StockTakes.change_stock_take(%StockTake{}, params), action: :validate)
    {:noreply, assign(socket, :form, form)}
  end

  @impl true
  def handle_event("delete_stock_take", %{"id" => id}, socket) do
    stock_take = StockTakes.get_stock_take!(id)

    case StockTakes.delete_requester_stock_take(stock_take) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Stock take deleted.")
         |> load_stock_takes()}

      {:error, _} ->
        {:noreply,
         put_flash(socket, :error, "Completed or approved stock takes cannot be deleted.")}
    end
  end

  @impl true
  def handle_event("create", %{"stock_take" => params}, socket) do
    params = Map.put(params, "admin_id", socket.assigns.current_user.id)

    case StockTakes.create_stock_take(params) do
      {:ok, stock_take} ->
        {:noreply,
         socket
         |> put_flash(:info, "Stock take session started.")
         |> push_navigate(to: "/admin/stock_takes/#{stock_take.id}")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:show_new_form, true)
         |> assign(:form, to_form(changeset))}
    end
  end

  defp build_path(department_id, page) do
    params = %{}

    params =
      if is_binary(department_id) and department_id != "",
        do: Map.put(params, "department_id", department_id),
        else: params

    page_int = if is_binary(page), do: String.to_integer(page), else: page
    params = if page_int > 1, do: Map.put(params, "page", page_int), else: params

    if map_size(params) > 0 do
      "/admin/stock_takes?" <> URI.encode_query(params)
    else
      "/admin/stock_takes"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <%!-- Header --%>
      <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 px-6 py-5">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div class="flex items-center gap-3">
            <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-emerald-100">
              <Heroicons.icon
                name="clipboard-document-check"
                type="outline"
                class="h-5 w-5 text-emerald-600"
              />
            </div>
            <div>
              <h1 class="text-lg font-semibold text-slate-900">Stock Takes</h1>
              <p class="text-sm text-slate-500">
                Physical inventory count sessions with full audit trail
              </p>
            </div>
          </div>
          <div class="flex flex-wrap items-center gap-3">
            <form phx-change="filter_department" class="flex items-center gap-2">
              <label
                for="department-filter"
                class="text-xs font-semibold uppercase tracking-wider text-slate-500"
              >
                Department:
              </label>
              <select
                id="department-filter"
                name="department_id"
                class="rounded-lg border border-slate-300 bg-white pl-3.5 pr-10 py-2 text-sm font-medium text-slate-700 shadow-sm focus:border-emerald-500 focus:outline-none focus:ring-1 focus:ring-emerald-500"
              >
                <option value="" selected={is_nil(@department_id) || @department_id == ""}>
                  All Departments
                </option>
                <option
                  :for={{name, id} <- @departments}
                  value={to_string(id)}
                  selected={to_string(id) == to_string(@department_id)}
                >
                  {name}
                </option>
              </select>
            </form>
            <button
              phx-click="show_new_form"
              class="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-4 py-2 text-sm font-semibold text-white hover:bg-emerald-700 transition-colors"
            >
              <Heroicons.icon name="plus" type="outline" class="h-4 w-4" /> New Stock Take
            </button>
          </div>
        </div>
      </div>

      <%!-- New Stock Take Form --%>
      <%= if @show_new_form do %>
        <div class="bg-white rounded-xl shadow-sm border border-emerald-200 px-6 py-5">
          <h2 class="text-base font-semibold text-slate-900 mb-4">Start New Stock Take Session</h2>
          <.form for={@form} phx-change="validate" phx-submit="create">
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <.input
                  field={@form[:department_id]}
                  type="select"
                  label="Destination Department"
                  options={@departments}
                  prompt="Select department"
                />
              </div>
              <div>
                <.input field={@form[:date]} type="date" label="Stock Take Date" />
              </div>
              <div>
                <.input
                  field={@form[:notes]}
                  type="text"
                  label="Notes (optional)"
                  placeholder="e.g. End of month count, annual audit..."
                />
              </div>
            </div>
            <div class="mt-4 flex gap-3">
              <.button phx-disable-with="Creating...">
                Start Stock Take
              </.button>
              <button
                type="button"
                phx-click="cancel_new"
                class="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
            </div>
          </.form>
        </div>
      <% end %>

      <%!-- Stock Takes List --%>
      <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 overflow-hidden">
        <%= if Enum.empty?(@stock_takes) do %>
          <div class="flex flex-col items-center justify-center py-20 px-4 text-center">
            <div class="flex h-16 w-16 items-center justify-center rounded-full bg-emerald-50">
              <Heroicons.icon
                name="clipboard-document-check"
                type="outline"
                class="h-8 w-8 text-emerald-400"
              />
            </div>
            <h3 class="mt-4 text-base font-medium text-slate-900">No stock takes found</h3>
            <p class="mt-2 max-w-sm text-sm text-slate-500">
              <%= if @department_id do %>
                No stock take sessions match the selected department filter.
              <% else %>
                Create your first stock take session to start counting inventory.
              <% end %>
            </p>
          </div>
        <% else %>
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Date
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Department
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Conducted By
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Notes
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Items
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Status
                </th>
                <th class="px-6 py-3 text-right text-xs font-semibold uppercase tracking-wider text-gray-500">
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 bg-white">
              <%= for st <- @stock_takes do %>
                <tr class="hover:bg-gray-50 transition-colors">
                  <td class="px-6 py-4">
                    <span class="text-sm font-medium text-slate-900">{format_date(st.date)}</span>
                  </td>
                  <td class="px-6 py-4">
                    <span class="text-sm font-medium text-slate-800">
                      {if st.department, do: st.department.name, else: "—"}
                    </span>
                  </td>
                  <td class="px-6 py-4">
                    <div class="flex items-center gap-2">
                      <div class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-emerald-100 text-emerald-700 text-xs font-semibold">
                        {String.first(conducted_by(st) || "?")}
                      </div>
                      <span class="text-sm text-gray-700">{conducted_by(st) || "—"}</span>
                    </div>
                  </td>
                  <td class="px-6 py-4">
                    <span class="text-sm text-gray-500">{st.notes || "—"}</span>
                  </td>
                  <td class="px-6 py-4">
                    <span class="inline-flex items-center rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-medium text-slate-700">
                      {length(st.entries)} item{if length(st.entries) != 1, do: "s", else: ""}
                    </span>
                  </td>
                  <td class="px-6 py-4">
                    {status_badge(assigns, st.status)}
                  </td>
                  <td class="px-6 py-4 text-right">
                    <div class="inline-flex items-center justify-end gap-2 w-36">
                      <.link
                        navigate={"/admin/stock_takes/#{st.id}"}
                        class={[
                          "inline-flex items-center justify-center gap-1.5 rounded-lg w-24 py-1.5 text-xs font-semibold transition-all",
                          st.status == "draft" &&
                            "bg-emerald-50 text-emerald-700 hover:bg-emerald-100 border border-emerald-200/80 shadow-2xs",
                          st.status != "draft" &&
                            "bg-slate-100/80 text-slate-700 hover:bg-slate-200/80 border border-slate-200/50"
                        ]}
                      >
                        <Heroicons.icon
                          name={if st.status == "draft", do: "pencil-square", else: "eye"}
                          type="outline"
                          class="h-3.5 w-3.5"
                        />
                        {if st.status == "draft", do: "Continue", else: "View"}
                      </.link>
                      <%= if st.status in ["draft", "pending", "rejected"] do %>
                        <button
                          type="button"
                          phx-click="confirm_delete"
                          phx-value-id={st.id}
                          class="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg text-slate-400 hover:bg-rose-50 hover:text-rose-600 transition-all border border-transparent hover:border-rose-200/60"
                          title="Delete stock take"
                        >
                          <Heroicons.icon name="trash" type="outline" class="h-3.5 w-3.5" />
                        </button>
                      <% else %>
                        <div class="w-7 shrink-0"></div>
                      <% end %>
                    </div>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
          <.pagination
            page={@page}
            total_pages={@total_pages}
            total_count={@total_count}
            per_page={@per_page}
            class="px-6 pb-4"
          />
        <% end %>
      </div>

      <%!-- Delete Confirmation Modal --%>
      <.modal
        :if={@deleting_stock_take}
        id="delete-confirm-modal"
        show
        on_cancel={JS.push("cancel_delete")}
      >
        <div class="space-y-4">
          <div class="flex items-center gap-3 text-red-600">
            <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-red-100">
              <Heroicons.icon name="exclamation-triangle" type="outline" class="h-6 w-6 text-red-600" />
            </div>
            <div>
              <h3 class="text-base font-semibold text-slate-900">Delete Stock Take Session</h3>
              <p class="text-xs text-slate-500">
                This action will permanently remove this draft session.
              </p>
            </div>
          </div>
          <p class="text-sm text-slate-600">
            Are you sure you want to delete the stock take for
            <span class="font-semibold text-slate-900">
              {if @deleting_stock_take.department,
                do: @deleting_stock_take.department.name,
                else: "this department"}
            </span>
            dated <span class="font-semibold text-slate-900">{format_date(@deleting_stock_take.date)}</span>?
          </p>
          <div class="flex justify-end gap-3 pt-3 border-t border-slate-100">
            <button
              type="button"
              phx-click="cancel_delete"
              class="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 transition-colors"
            >
              Cancel
            </button>
            <button
              type="button"
              phx-click="execute_delete"
              class="rounded-lg bg-red-600 px-4 py-2 text-sm font-semibold text-white hover:bg-red-700 transition-colors"
            >
              Delete Session
            </button>
          </div>
        </div>
      </.modal>
    </div>
    """
  end

  defp status_badge(assigns, "draft") do
    ~H"""
    <span class="inline-flex items-center gap-1 rounded-full bg-amber-50 px-2.5 py-1 text-xs font-semibold text-amber-700 ring-1 ring-inset ring-amber-600/20">
      <span class="h-1.5 w-1.5 rounded-full bg-amber-500"></span> Draft
    </span>
    """
  end

  defp status_badge(assigns, "completed") do
    ~H"""
    <span class="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700 ring-1 ring-inset ring-emerald-600/20">
      <span class="h-1.5 w-1.5 rounded-full bg-emerald-500"></span> Completed
    </span>
    """
  end

  defp status_badge(assigns, "pending") do
    ~H"""
    <span class="inline-flex items-center gap-1 rounded-full bg-blue-50 px-2.5 py-1 text-xs font-semibold text-blue-700 ring-1 ring-inset ring-blue-600/20">
      <span class="h-1.5 w-1.5 rounded-full bg-blue-500"></span> Pending approval
    </span>
    """
  end

  defp status_badge(assigns, "rejected") do
    ~H"""
    <span class="inline-flex items-center gap-1 rounded-full bg-red-50 px-2.5 py-1 text-xs font-semibold text-red-700 ring-1 ring-inset ring-red-600/20">
      <span class="h-1.5 w-1.5 rounded-full bg-red-500"></span> Rejected
    </span>
    """
  end

  defp status_badge(assigns, _), do: ~H""

  defp conducted_by(%{admin: %{name: name}}) when is_binary(name), do: name
  defp conducted_by(%{requested_by: %{name: name}}) when is_binary(name), do: name
  defp conducted_by(_), do: nil

  defp format_date(date) do
    Calendar.strftime(date, "%B %-d, %Y")
  end
end
