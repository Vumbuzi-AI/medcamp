defmodule MedcampWeb.PharmacistsLive.PendingDrugBatchesIndex do
  use MedcampWeb, :pharmacist_live_view

  alias Medcamp.DrugBatches

  @per_page 10

  @impl true
  def mount(_, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :pending_drug_batches)
     |> assign(:search, "")
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_drug_batches()}
  end

  defp load_drug_batches(socket) do
    filters = %{search: socket.assigns.search}
    total_count = DrugBatches.count_pending_drug_batches(filters)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    drug_batches =
      DrugBatches.list_pending_drug_batches_paginated(filters, page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:drug_batches, drug_batches)
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Drug batches")
    |> assign(:drug_batch, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Add Drug Batch")
    |> assign(:drug_batch, nil)
  end

  defp apply_action(socket, :scan, %{"id" => id}) do
    socket
    |> assign(:page_title, "Listing Drug batches")
    |> assign(:drug_batch, DrugBatches.get_drug_batch!(id))
  end

  @impl true
  def handle_event("search", %{"search" => term}, socket) do
    {:noreply, socket |> assign(:search, term) |> assign(:page, 1) |> load_drug_batches()}
  end

  @impl true
  def handle_event("clear_search", _params, socket) do
    {:noreply, socket |> assign(:search, "") |> assign(:page, 1) |> load_drug_batches()}
  end

  @impl true
  def handle_event("confirm", %{"id" => id}, socket) do
    drug_batch = DrugBatches.get_drug_batch!(id)

    {:ok, _} =
      DrugBatches.update_drug_batch(drug_batch, %{
        is_confirmed: true,
        confirmed_by: socket.assigns.current_user.id
      })

    {:noreply,
     socket
     |> put_flash(:info, "Batch confirmed successfully")
     |> push_navigate(to: ~p"/pharmacist/pending_drug_batches")}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_drug_batches()}
  end

  @impl true

  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <div class="mb-6">
        <.link
          navigate="/pharmacist/drugs"
          class="flex items-center gap-2 text-[#373896] hover:text-[#6667ab] font-medium"
        >
          <Heroicons.icon name="arrow-left" type="outline" class="h-5 w-5" />
          <span>Listing Pending Drug Batches that need Scanning</span>
        </.link>

        <.link
          patch={~p"/pharmacist/pending_drug_batches/new"}
          class="mt-3 inline-flex items-center gap-2 rounded-lg bg-[#373896] px-3 py-2 text-sm font-medium text-white hover:bg-[#2f317f]"
        >
          <Heroicons.icon name="plus" type="outline" class="h-4 w-4" /> Add Drug Batch
        </.link>
      </div>
      <div class="overflow-hidden">
        <form phx-change="search" class="mb-4">
          <.search_input
            name="search"
            value={@search}
            placeholder="Search by brand, generic name, or batch"
          />
        </form>

        <.table id="drug_batches" rows={@drug_batches}
          row_id={&"drug_batches-#{&1.id}"}
        >
          <:empty_state>
            <tr>
              <td class="px-6 py-4 text-sm">
                <p class="font-semibold text-gray-900">
                  {if @search != "",
                    do: "No pending drug batches match the current search",
                    else: "No pending drug batches available"}
                </p>
                <p class="mt-1 text-sm text-gray-400">—</p>
              </td>
              <td class="px-6 py-4 text-sm text-gray-400">—</td>
              <td class="px-6 py-4 text-sm">
                <span class="inline-flex rounded-full bg-[#f0f0ff] px-2 py-1 text-xs font-medium text-gray-400">
                  —
                </span>
              </td>
              <td class="px-6 py-4 text-sm text-gray-400">—</td>
              <td class="px-6 py-4 text-sm text-gray-400">—</td>
            </tr>
          </:empty_state>

          <:col :let={drug_batch} label="Brand Name">
            <div class="py-3">
              <span class="font-medium text-gray-900">
                {drug_batch.inventory_received.strength} {drug_batch.inventory_received.brand_name}
              </span>
            </div>
          </:col>

          <:col :let={drug_batch} label="Generic Name">
            <div class="py-3">
              <span class="text-gray-700">{drug_batch.inventory_received.generic_name}</span>
            </div>
          </:col>

          <:col :let={drug_batch} label="Batch Name">
            <div class="py-3">
              <span class="px-2 py-1 rounded-full bg-[#e7e7ff] text-[#373896] text-sm font-medium">
                {drug_batch.batch.batch}
              </span>
            </div>
          </:col>

          <:col :let={drug_batch} label="Quantity">
            <div class="py-3">
              <span class="text-gray-700">{drug_batch.remaining_quantity}</span>
            </div>
          </:col>

          <:action :let={drug_batch}>
            <div class="flex items-center gap-2">
              <.link
                navigate={~p"/pharmacist/pending_drug_batches/#{drug_batch.id}/scan"}
                class="bg-[#373896] text-white p-3 rounded-lg hover:bg-[#6667ab] font-medium"
              >
                Scan To Confirm
              </.link>
              <p
                phx-click="confirm"
                phx-value-id={drug_batch.id}
                data-confirm="Are you sure you want to confirm this drug batch?"
                class="bg-[#373896] text-white p-3 rounded-lg hover:bg-[#6667ab] font-medium"
              >
                Tap To Confirm
              </p>
            </div>
          </:action>
        </.table>
        <.pagination
          page={@page}
          total_pages={@total_pages}
          total_count={@total_count}
          per_page={@per_page}
        />
      </div>

      <.modal
        :if={@live_action in [:new]}
        id="drug-batch-modal"
        show
        on_cancel={JS.patch(~p"/pharmacist/pending_drug_batches")}
      >
        <.live_component
          module={MedcampWeb.PharmacistsLive.DrugBatchFormComponent}
          id={:new_drug_batch}
          title={@page_title}
          action={@live_action}
          current_user={@current_user}
          patch={~p"/pharmacist/pending_drug_batches"}
        />
      </.modal>

      <.modal
        :if={@live_action in [:scan]}
        id="inventory_received-modal"
        show
        on_cancel={JS.patch(~p"/pharmacist/pending_drug_batches")}
      >
        <.live_component
          module={MedcampWeb.PharmacistsLive.PendingDrugBatchesScan}
          id={:new}
          title={@page_title}
          action={@live_action}
          drug_batch={@drug_batch}
          current_user={@current_user}
          patch={~p"/pharmacist/pending_drug_batches"}
        />
      </.modal>
    </div>
    """
  end
end
