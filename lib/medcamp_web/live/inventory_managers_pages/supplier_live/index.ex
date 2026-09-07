defmodule MedcampWeb.SupplierLive.Index do
  use MedcampWeb, :inventory_manager_live_view

  alias Medcamp.Suppliers
  alias Medcamp.Suppliers.Supplier

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :suppliers)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:total_count, 0)
     |> assign(:total_pages, 0)
     |> assign(:search, "")
     |> assign_suppliers(1)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Supplier")
    |> assign(:supplier, Suppliers.get_supplier!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Supplier")
    |> assign(:supplier, %Supplier{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Suppliers")
    |> assign(:supplier, nil)
  end

  @impl true
  def handle_info({MedcampWeb.SupplierLive.FormComponent, {:saved, _supplier}}, socket) do
    {:noreply, assign_suppliers(socket, socket.assigns.page)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, assign_suppliers(socket, page)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    supplier = Suppliers.get_supplier!(id)
    {:ok, _} = Suppliers.delete_supplier(supplier)

    {:noreply, assign_suppliers(socket, socket.assigns.page)}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply,
     socket
     |> assign(:search, search)
     |> assign_suppliers(1)}
  end

  @impl true
  def handle_event("clear_search", _params, socket) do
    {:noreply,
     socket
     |> assign(:search, "")
     |> assign_suppliers(1)}
  end

  defp assign_suppliers(socket, page) do
    page = normalize_page(page)
    search = socket.assigns.search
    total_count = Suppliers.count_suppliers(search)
    total_pages = max(1, div(total_count + @per_page - 1, @per_page))
    page = min(page, total_pages)

    suppliers = Suppliers.list_suppliers_paginated(page, @per_page, search)

    socket
    |> assign(:page, page)
    |> assign(:per_page, @per_page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:suppliers, suppliers)
  end

  defp normalize_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {value, _} when value > 0 -> value
      _ -> 1
    end
  end

  defp normalize_page(page) when is_integer(page) and page > 0, do: page
  defp normalize_page(_), do: 1

  @impl true

  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.page_header
        icon_path="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"
        title="Suppliers"
        subtitle="Search and manage registered suppliers."
      >
        <:actions>
          <.link patch={~p"/inventory_manager/suppliers/new"}>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">
              <div class="flex items-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-2"
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
                New Supplier
              </div>
            </.button>
          </.link>
        </:actions>
      </.page_header>

      <div class="flex items-center gap-3 mb-4">
        <form phx-change="search" class="flex-1">
          <.search_input
            name="search"
            value={@search}
            placeholder="Search by name, email, or contact"
          />
        </form>
      </div>

      <%= if Enum.empty?(@suppliers) do %>
        <.blank_state
          icon_path="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"
          title="No suppliers found"
          description="No suppliers match the current search."
        >
          <:actions :if={@search != ""}>
            <button phx-click="clear_search" class="text-xs text-[#6667ab] hover:underline">
              Clear filters
            </button>
          </:actions>
        </.blank_state>
      <% else %>
        <.table id="suppliers" rows={@suppliers}>
          <:col :let={supplier} label="Name">
            <div class="flex items-center py-3">
              <div class="h-8 w-8 rounded-full bg-[#e7e7ff] flex items-center justify-center text-[#373896] font-medium mr-2 text-sm">
                {String.first(supplier.name || "")}
              </div>
              <.link
                patch={~p"/inventory_manager/suppliers/#{supplier}"}
                class="font-medium text-gray-900 hover:text-[#373896]"
              >
                {supplier.name}
              </.link>
            </div>
          </:col>

          <:col :let={supplier} label="Email">
            <div class="flex items-center py-3">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-1 text-[#6667ab]"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                />
              </svg>
              <span class="text-gray-700">{supplier.email}</span>
            </div>
          </:col>

          <:col :let={supplier} label="Contact number">
            <div class="flex items-center py-3">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-1 text-[#6667ab]"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"
                />
              </svg>
              <span class="text-gray-700">{supplier.contact}</span>
            </div>
          </:col>

          <:action :let={supplier}>
            <div class="flex items-center justify-center">
              <.link
                patch={~p"/inventory_manager/suppliers/#{supplier}/edit"}
                class="flex items-center text-[#6667ab] hover:text-[#373896]"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-1"
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
                Edit
              </.link>
            </div>
          </:action>

          <:action :let={supplier}>
            <div class="flex items-center justify-center">
              <.link
                phx-click={JS.push("delete", value: %{id: supplier.id})}
                data-confirm="Are you sure?"
                class="flex items-center text-red-600 hover:text-red-800"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-1"
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
                Delete
              </.link>
            </div>
          </:action>
        </.table>
      <% end %>

      <.pagination
        page={@page}
        total_pages={@total_pages}
        total_count={@total_count}
        per_page={@per_page}
      />

      <.modal
        :if={@live_action in [:new, :edit]}
        id="supplier-modal"
        show
        on_cancel={JS.patch(~p"/inventory_manager/suppliers")}
      >
        <.live_component
          module={MedcampWeb.SupplierLive.FormComponent}
          id={@supplier.id || :new}
          title={@page_title}
          action={@live_action}
          supplier={@supplier}
          patch={~p"/inventory_manager/suppliers"}
        />
      </.modal>
    </div>
    """
  end
end
