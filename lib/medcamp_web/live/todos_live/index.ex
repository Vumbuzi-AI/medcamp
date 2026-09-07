defmodule MedcampWeb.TodosLive.Index do
  use MedcampWeb, :shared_live_view

  alias MedcampWeb.RoleRouteHelpers
  alias Medcamp.Todos
  alias Medcamp.Todos.Todo

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:filter, "all")
     |> assign(:search, "")
     |> assign(:active_tab, :todos)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> stream_todos()}
  end

  defp stream_todos(socket) do
    all =
      Todos.list_todos_for_user(
        socket.assigns.current_user,
        socket.assigns.filter,
        socket.assigns.search
      )

    total_count = length(all)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)
    todos = Enum.slice(all, (page - 1) * socket.assigns.per_page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> stream(:todos, todos, reset: true)
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Todo")
    |> assign(:todo, %Todo{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Todo")
    |> assign(:todo, Todos.get_todo!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Todos")
    |> assign(:todo, nil)
  end

  @impl true
  def handle_info({MedcampWeb.TodosLive.FormComponent, {:saved, _todo}}, socket) do
    {:noreply, stream_todos(socket)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)
    {:ok, _} = Todos.delete_todo(todo)
    {:noreply, stream_todos(socket)}
  end

  @impl true
  def handle_event("filter", %{"filters" => %{"status" => status}}, socket) do
    {:noreply,
     socket
     |> assign(:filter, status)
     |> assign(:page, 1)
     |> stream_todos()}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    todos = Todos.list_todos_for_user(socket.assigns.current_user, "all", socket.assigns.search)

    {:noreply,
     socket
     |> assign(:filter, "all")
     |> assign(:todos_count, length(todos))
     |> stream(:todos, todos, reset: true)}
  end

  @impl true
  def handle_event("search", %{"search" => term}, socket) do
    {:noreply,
     socket
     |> assign(:search, term)
     |> assign(:page, 1)
     |> stream_todos()}
  end

  @impl true
  def handle_event("clear_search", _params, socket) do
    {:noreply,
     socket
     |> assign(:search, "")
     |> assign(:page, 1)
     |> stream_todos()}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> stream_todos()}
  end

  @impl true
  def handle_event("mark_complete", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)
    {:ok, _updated} = Todos.update_todo(todo, %{status: "completed"})
    {:noreply, stream_todos(socket)}
  end

  defp todos_path(current_user, suffix \\ "") do
    RoleRouteHelpers.role_path(current_user, "/todos" <> suffix)
  end

  defp count_active_filters(assigns) do
    [assigns.filter != "all"] |> Enum.count(& &1)
  end

  defp status_label("pending"), do: "Pending"
  defp status_label("in_progress"), do: "In Progress"
  defp status_label("completed"), do: "Completed"
  defp status_label(other), do: other

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.header class="text-[#373896] border-b border-gray-100 pb-4 mb-4">
        <div class="flex items-center justify-between w-full">
          <div class="flex items-center">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5 mr-2 text-[#6667ab]"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"
              />
            </svg>
            Todos
          </div>
          <.link
            patch={todos_path(@current_user, "/new")}
            class="flex items-center gap-2 px-4 py-2 bg-[#6667ab] text-white rounded-lg hover:bg-[#373896] transition-colors font-medium text-sm"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-4 w-4"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 4v16m8-8H4"
              />
            </svg>
            New Todo
          </.link>
        </div>
      </.header>

      <div class="flex items-center gap-3 mb-4 flex-wrap">
        <form phx-change="search" class="flex-1 min-w-[200px]">
          <.search_input name="search" value={@search} placeholder="Search by title or description" />
        </form>

        <.filter_drawer
          id="todos-filters"
          title="Filter todos"
          apply_event="filter"
          clear_event="clear_filters"
          active_count={count_active_filters(assigns)}
        >
          <:group label="Status">
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Status</label>
              <select
                name="filters[status]"
                class="w-full h-9 rounded-md border border-gray-300 px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
              >
                <option value="all" selected={@filter == "all"}>All</option>
                <option value="pending" selected={@filter == "pending"}>Pending</option>
                <option value="in_progress" selected={@filter == "in_progress"}>In Progress</option>
                <option value="completed" selected={@filter == "completed"}>Completed</option>
              </select>
            </div>
          </:group>

          <:chip :if={@filter != "all"} label={status_label(@filter)} clear="clear_filters" />
        </.filter_drawer>
      </div>

      <%= if @total_count == 0 do %>
        <.blank_state
          icon_path="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
          title="No todos found"
          description={
            if @search != "" or @filter != "all",
              do: "No todos match the current filters.",
              else: "Create a new todo to get started."
          }
        >
          <:actions :if={@search != ""}>
            <button phx-click="clear_search" class="text-xs text-[#6667ab] hover:underline">
              Clear search
            </button>
          </:actions>
        </.blank_state>
      <% else %>
        <div class="space-y-3" id="todos" phx-update="stream">
          <%= for {id, todo} <- @streams.todos do %>
            <div
              id={id}
              class={"rounded-lg border p-4 #{if Todo.overdue?(todo), do: "border-red-200 bg-red-50", else: "border-gray-200 bg-white"} hover:shadow-sm transition-shadow"}
            >
              <div class="flex items-start justify-between gap-3">
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2 flex-wrap">
                    <h3 class={"font-semibold text-gray-900 #{if todo.status == "completed", do: "line-through text-gray-400", else: ""}"}>
                      {todo.title}
                    </h3>
                    <span class={"px-2 py-0.5 text-xs font-medium rounded-full #{Todo.status_classes(todo.status)}"}>
                      {Todo.status_label(todo.status)}
                    </span>
                    <span class={"px-2 py-0.5 text-xs font-medium rounded-full #{Todo.priority_classes(todo.priority)}"}>
                      {String.capitalize(todo.priority)}
                    </span>
                    <%= if Todo.overdue?(todo) do %>
                      <span class="px-2 py-0.5 text-xs font-semibold rounded-full bg-red-100 text-red-700">
                        Overdue
                      </span>
                    <% end %>
                  </div>

                  <%= if todo.description && todo.description != "" do %>
                    <p class="mt-1 text-sm text-gray-600 line-clamp-2">{todo.description}</p>
                  <% end %>

                  <div class="mt-2 flex items-center gap-4 text-xs text-gray-500 flex-wrap">
                    <%= if todo.due_date do %>
                      <span class="flex items-center gap-1">
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-3.5 w-3.5"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                          />
                        </svg>
                        Due: {Calendar.strftime(todo.due_date, "%b %d, %Y")}
                      </span>
                    <% end %>
                    <%= if todo.assigned_to_name && todo.assigned_to_name != "" do %>
                      <span class="flex items-center gap-1">
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-3.5 w-3.5"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                          />
                        </svg>
                        Assigned to: {todo.assigned_to_name}
                      </span>
                    <% end %>
                    <span class="flex items-center gap-1">
                      By: {todo.created_by.name || todo.created_by.email}
                    </span>
                  </div>
                </div>

                <div class="flex items-center gap-2 shrink-0">
                  <%= if todo.status != "completed" do %>
                    <button
                      phx-click="mark_complete"
                      phx-value-id={todo.id}
                      class="p-1.5 rounded-md text-green-600 hover:bg-green-50 transition-colors"
                      title="Mark complete"
                    >
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-5 w-5"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M5 13l4 4L19 7"
                        />
                      </svg>
                    </button>
                  <% end %>
                  <.link
                    patch={todos_path(@current_user, "/#{todo.id}/edit")}
                    class="p-1.5 rounded-md text-[#6667ab] hover:bg-[#e7e7ff] transition-colors"
                    title="Edit"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-5 w-5"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                      />
                    </svg>
                  </.link>
                  <.link
                    phx-click={JS.push("delete", value: %{id: todo.id}) |> hide("##{id}")}
                    data-confirm="Delete this todo?"
                    class="p-1.5 rounded-md text-red-500 hover:bg-red-50 transition-colors"
                    title="Delete"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-5 w-5"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                      />
                    </svg>
                  </.link>
                </div>
              </div>
            </div>
          <% end %>
        </div>
        <.pagination
          page={@page}
          total_pages={@total_pages}
          total_count={@total_count}
          per_page={@per_page}
        />
      <% end %>

      <.modal
        :if={@live_action in [:new, :edit]}
        id="todo-modal"
        show
        on_cancel={JS.patch(todos_path(@current_user))}
      >
        <.live_component
          module={MedcampWeb.TodosLive.FormComponent}
          id={@todo.id || :new}
          title={@page_title}
          action={@live_action}
          todo={@todo}
          current_user={@current_user}
          patch={todos_path(@current_user)}
        />
      </.modal>
    </div>
    """
  end
end
