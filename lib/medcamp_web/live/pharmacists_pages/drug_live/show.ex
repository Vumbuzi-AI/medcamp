defmodule MedcampWeb.PharmacistsLive.DrugsShow do
  use MedcampWeb, :pharmacist_live_view

  alias Medcamp.DrugAllocations
  alias Medcamp.DrugBatches
  alias Medcamp.DrugsGiven
  alias Medcamp.Drugs

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    drug = Drugs.get_drug!(id)

    {:ok,
     socket
     |> assign(:active_tab, :drugs)
     |> assign(:drug, drug)
     |> assign(:editing_batch, nil)
     |> assign(:editing_drug, false)
     |> assign(:error_message, nil)
     |> assign(:batch_tab, :active)
     |> assign(:drug_tab, :batches)
     |> assign(:prescriptions_status, nil)
     |> assign(:prescriptions_page, 1)
     |> assign(:prescriptions_total_pages, 1)
     |> assign(:prescriptions_per_page, 10)
     |> assign(:drugs_given_page, 1)
     |> assign(:drugs_given_total_pages, 1)
     |> assign(:drugs_given_per_page, 10)
     |> assign(:expiry_filters, default_expiry_filters())
     |> assign(:drug_prescriptions_count, 0)
     |> assign(:drugs_given_count, 0)
     |> assign(:drug_batches, filtered_batches(id, :active, default_expiry_filters()))
     |> assign(:drugs_given, [])
     |> assign(:drug_prescriptions, [])}
  end

  defp default_expiry_filters, do: %{expiry_status: "", expiry_from: "", expiry_to: ""}

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(:page_title, "Listing Drug batches")
    |> assign(:drug_batch, nil)
    |> assign(:requisition_prefill, nil)
    |> assign_drug_tab_from_params(params)
    |> assign_batch_tab_from_params(params)
    |> assign_prescriptions_status_from_params(params)
    |> assign_prescriptions_page_from_params(params)
    |> assign_drugs_given_page_from_params(params)
    |> maybe_load_batches_by_tab()
    |> maybe_load_prescriptions_by_status()
    |> maybe_load_drugs_given()
  end

  defp apply_action(socket, :requisition, params) do
    ir_id =
      case params["inventory_received_id"] do
        "" ->
          nil

        nil ->
          nil

        id when is_binary(id) ->
          case Integer.parse(id) do
            {n, _} -> n
            _ -> nil
          end

        _ ->
          nil
      end

    socket
    |> assign(:page_title, "Listing Drug batches")
    |> assign(:requisition_prefill, %{
      inventory_received_id: ir_id,
      item_title: params["item_title"] || "Requisition",
      item_description: params["item_description"] || ""
    })
  end

  defp assign_drug_tab_from_params(socket, params) do
    tab =
      case params["drug_tab"] do
        "allocations" -> :allocations
        "prescriptions" -> :prescriptions
        _ -> :batches
      end

    assign(socket, :drug_tab, tab)
  end

  defp assign_batch_tab_from_params(socket, params) do
    tab =
      case params["batch_tab"] do
        "discarded" -> :discarded
        _ -> :active
      end

    assign(socket, :batch_tab, tab)
  end

  defp assign_prescriptions_status_from_params(socket, params) do
    status =
      case params["prescription_status"] do
        "given" -> "given"
        "pending" -> "pending"
        _ -> nil
      end

    assign(socket, :prescriptions_status, status)
  end

  defp assign_prescriptions_page_from_params(socket, params) do
    assign(
      socket,
      :prescriptions_page,
      Medcamp.Pagination.normalize_page(params["prescription_page"])
    )
  end

  defp assign_drugs_given_page_from_params(socket, params) do
    assign(socket, :drugs_given_page, Medcamp.Pagination.normalize_page(params["drugs_given_page"]))
  end

  # Only the currently active tab's data is (re)fetched on every param change
  # (tab switch, filter, pagination) - the other two tabs' streams are left
  # exactly as they were until the user actually switches to them.
  defp maybe_load_batches_by_tab(socket) do
    if socket.assigns.drug_tab == :batches, do: load_batches_by_tab(socket), else: socket
  end

  defp maybe_load_prescriptions_by_status(socket) do
    if socket.assigns.drug_tab == :prescriptions,
      do: load_prescriptions_by_status(socket),
      else: socket
  end

  defp maybe_load_drugs_given(socket) do
    if socket.assigns.drug_tab == :allocations, do: load_drugs_given(socket), else: socket
  end

  defp load_prescriptions_by_status(socket) do
    ir_id = socket.assigns.drug.inventory_received_id
    status = socket.assigns.prescriptions_status
    per_page = socket.assigns.prescriptions_per_page

    total_count = DrugAllocations.count_drug_allocations_for_drug(ir_id, status)
    total_pages = Medcamp.Pagination.total_pages(total_count, per_page)
    page = min(socket.assigns.prescriptions_page, total_pages)

    prescriptions = DrugAllocations.list_drug_allocations_for_drug(ir_id, status, page, per_page)

    socket
    |> assign(:drug_prescriptions_count, total_count)
    |> assign(:prescriptions_page, page)
    |> assign(:prescriptions_total_pages, total_pages)
    |> assign(:drug_prescriptions, prescriptions)
  end

  defp load_drugs_given(socket) do
    drug_id = socket.assigns.drug.id
    per_page = socket.assigns.drugs_given_per_page

    total_count = DrugsGiven.count_drugs_given_for_drug(drug_id)
    total_pages = Medcamp.Pagination.total_pages(total_count, per_page)
    page = min(socket.assigns.drugs_given_page, total_pages)

    drugs_given = DrugsGiven.list_drugs_given_for_drug(drug_id, page, per_page)

    socket
    |> assign(:drugs_given_count, total_count)
    |> assign(:drugs_given_page, page)
    |> assign(:drugs_given_total_pages, total_pages)
    |> assign(:drugs_given, drugs_given)
  end

  defp load_batches_by_tab(socket) do
    batches =
      filtered_batches(
        socket.assigns.drug.id,
        socket.assigns.batch_tab,
        socket.assigns.expiry_filters
      )

    assign(socket, :drug_batches, batches)
  end

  defp filtered_batches(drug_id, batch_tab, expiry_filters) do
    batches =
      case batch_tab do
        :discarded -> DrugBatches.list_discarded_drug_batches_for_drug(drug_id)
        _ -> DrugBatches.list_drug_batches_for_drug(drug_id)
      end

    DrugBatches.filter_by_expiry(
      batches,
      expiry_filters[:expiry_status],
      expiry_filters[:expiry_from],
      expiry_filters[:expiry_to]
    )
  end

  defp count_active_batch_filters(expiry_filters) do
    Enum.count(
      [
        expiry_filters[:expiry_status],
        expiry_filters[:expiry_from],
        expiry_filters[:expiry_to]
      ],
      &(&1 not in [nil, ""])
    )
  end

  defp batch_filter_chips(expiry_filters) do
    [
      filter_chip(
        expiry_filters[:expiry_status],
        "expiry_status",
        "Expiry: #{Medcamp.ExpiryFilter.label(expiry_filters[:expiry_status])}"
      ),
      filter_chip(
        expiry_filters[:expiry_from],
        "expiry_from",
        "Expiry from #{expiry_filters[:expiry_from]}"
      ),
      filter_chip(
        expiry_filters[:expiry_to],
        "expiry_to",
        "Expiry to #{expiry_filters[:expiry_to]}"
      )
    ]
    |> Enum.reject(&is_nil/1)
  end

  @impl true
  def handle_event("filter_batches", %{"filters" => filters}, socket) do
    {:noreply,
     socket
     |> assign(:expiry_filters, %{
       expiry_status: Medcamp.ExpiryFilter.normalize(filters["expiry_status"]),
       expiry_from: filters["expiry_from"] || "",
       expiry_to: filters["expiry_to"] || ""
     })
     |> load_batches_by_tab()}
  end

  @impl true
  def handle_event("clear_batch_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:expiry_filters, default_expiry_filters())
     |> load_batches_by_tab()}
  end

  @impl true
  def handle_event("clear_batch_chip", %{"field" => field}, socket) do
    current = socket.assigns.expiry_filters

    filters = %{
      "expiry_status" => current[:expiry_status],
      "expiry_from" => current[:expiry_from],
      "expiry_to" => current[:expiry_to]
    }

    handle_event("filter_batches", %{"filters" => Map.put(filters, field, "")}, socket)
  end

  @impl true
  def handle_event("open_edit_modal", %{"id" => id}, socket) do
    drug_batch = DrugBatches.get_drug_batch!(id)
    {:noreply, assign(socket, :editing_batch, drug_batch)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, editing_batch: nil, error_message: nil)}
  end

  @impl true
  def handle_event("open_requisition_modal", params, socket) do
    path =
      "/pharmacist/drugs/#{socket.assigns.drug.id}/requisition?" <>
        URI.encode_query(%{
          "inventory_received_id" => params["inventory_received_id"] || "",
          "item_title" => params["item_title"] || "Requisition",
          "item_description" => params["item_description"] || ""
        })

    {:noreply, push_patch(socket, to: path)}
  end

  def handle_event("open_edit_drug_modal", _params, socket) do
    {:noreply, assign(socket, :editing_drug, true)}
  end

  def handle_event("close_edit_drug_modal", _params, socket) do
    {:noreply, assign(socket, :editing_drug, false)}
  end

  def handle_event(
        "save_drug_details",
        %{"generic_name" => generic_name, "brand_name" => brand_name},
        socket
      ) do
    drug = socket.assigns.drug

    case Drugs.update_drug(drug, %{generic_name: generic_name, brand_name: brand_name}) do
      {:ok, updated_drug} ->
        {:noreply,
         socket
         |> assign(:drug, updated_drug)
         |> assign(:editing_drug, false)
         |> put_flash(:info, "Drug details updated successfully")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to update: #{inspect(changeset.errors)}")}
    end
  end

  @impl true
  def handle_event("discard_batch", %{"id" => id}, socket) do
    drug_batch = DrugBatches.get_drug_batch!(id)

    case DrugBatches.update_drug_batch(drug_batch, %{is_active: false}) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(
           :drug_batches,
           Enum.reject(socket.assigns.drug_batches, &(&1.id == drug_batch.id))
         )
         |> put_flash(
           :info,
           "Batch discarded. It will no longer appear in drug listing or search."
         )}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to discard batch")}
    end
  end

  def handle_event("reactivate_batch", %{"id" => id}, socket) do
    drug_batch = DrugBatches.get_drug_batch!(id)

    case DrugBatches.update_drug_batch(drug_batch, %{is_active: true}) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(
           :drug_batches,
           Enum.reject(socket.assigns.drug_batches, &(&1.id == drug_batch.id))
         )
         |> put_flash(:info, "Batch reactivated. It will now appear in drug listing and search.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to reactivate batch")}
    end
  end

  def handle_event("switch_drug_tab", %{"tab" => tab}, socket) do
    base = ~p"/pharmacist/drugs/#{socket.assigns.drug.id}"

    path =
      case tab do
        "allocations" -> base <> "?drug_tab=allocations"
        "prescriptions" -> base <> "?drug_tab=prescriptions"
        _ -> base
      end

    {:noreply, push_patch(socket, to: path)}
  end

  def handle_event("switch_batch_tab", %{"tab" => tab}, socket) do
    base = ~p"/pharmacist/drugs/#{socket.assigns.drug.id}"
    path = if tab == "discarded", do: base <> "?batch_tab=discarded", else: base
    {:noreply, push_patch(socket, to: path)}
  end

  def handle_event("filter_prescriptions_status", %{"status" => status}, socket) do
    base = ~p"/pharmacist/drugs/#{socket.assigns.drug.id}?drug_tab=prescriptions"

    path =
      if status in ["given", "pending"],
        do: base <> "&prescription_status=#{status}",
        else: base

    {:noreply, push_patch(socket, to: path)}
  end

  def handle_event("paginate_prescriptions", %{"page" => page}, socket) do
    base = ~p"/pharmacist/drugs/#{socket.assigns.drug.id}?drug_tab=prescriptions"

    base =
      if socket.assigns.prescriptions_status,
        do: base <> "&prescription_status=#{socket.assigns.prescriptions_status}",
        else: base

    {:noreply, push_patch(socket, to: base <> "&prescription_page=#{page}")}
  end

  def handle_event("paginate_drugs_given", %{"page" => page}, socket) do
    path =
      ~p"/pharmacist/drugs/#{socket.assigns.drug.id}?drug_tab=allocations&drugs_given_page=#{page}"

    {:noreply, push_patch(socket, to: path)}
  end

  def handle_event("toggle_otc", _params, socket) do
    drug = socket.assigns.drug
    new_value = !drug.is_otc

    case Drugs.update_drug(drug, %{is_otc: new_value}) do
      {:ok, updated_drug} ->
        flash_msg = if new_value, do: "Drug marked as OTC", else: "Drug marked as non-OTC"

        {:noreply,
         socket
         |> assign(:drug, updated_drug)
         |> put_flash(:info, flash_msg)}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to update OTC status")}
    end
  end

  def handle_event("toggle_dangerous_drug", _params, socket) do
    drug = socket.assigns.drug
    new_value = !drug.is_dangerous_drug

    case Drugs.update_drug(drug, %{is_dangerous_drug: new_value}) do
      {:ok, updated_drug} ->
        flash_msg =
          if new_value do
            "Drug added to the dangerous drug register"
          else
            "Drug removed from the dangerous drug register"
          end

        {:noreply,
         socket
         |> assign(:drug, updated_drug)
         |> put_flash(:info, flash_msg)}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to update dangerous drug register status")}
    end
  end

  @impl true
  def handle_event(
        "update_remaining_quantity",
        %{"remaining_quantity" => remaining_quantity},
        socket
      ) do
    drug_batch = socket.assigns.editing_batch

    case DrugBatches.update_drug_batch(drug_batch, %{
           remaining_quantity: String.to_integer(remaining_quantity)
         }) do
      {:ok, _drug_batch} ->
        {:noreply,
         socket
         |> assign(:editing_batch, nil)
         |> assign(:error_message, nil)
         |> load_batches_by_tab()
         |> put_flash(:info, "Quantity updated successfully")}

      {:error, changeset} ->
        {:noreply,
         assign(
           socket,
           :error_message,
           "Failed to update quantity: #{inspect(changeset.errors)}"
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <div class="mb-6 rounded-2xl border border-slate-200 bg-gradient-to-br from-white via-white to-slate-50 p-5">
        <div class="flex flex-col gap-6 xl:flex-row xl:items-start xl:justify-between">
          <div class="min-w-0 flex-1">
            <.link
              navigate="/pharmacist/drugs"
              class="inline-flex items-center gap-2 text-sm font-medium text-[#373896] transition hover:text-[#6667ab]"
            >
              <Heroicons.icon name="arrow-left" type="outline" class="h-5 w-5" />
              <span>Back to drugs</span>
            </.link>

            <div class="mt-4 max-w-4xl">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                Drug inventory
              </p>
              <h1 class="mt-2 text-2xl font-semibold leading-tight text-[#373896]">
                {Drugs.display_name(@drug)}
              </h1>
              <p class="mt-2 text-sm text-slate-500">
                Review batches, stock position, and allocation activity for this drug.
              </p>
            </div>

            <div class="mt-4 flex flex-wrap gap-2">
              <span class={[
                "inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold",
                if(@drug.is_otc,
                  do: "bg-green-100 text-green-800",
                  else: "bg-slate-100 text-slate-600"
                )
              ]}>
                {if @drug.is_otc, do: "OTC", else: "Non-OTC"}
              </span>
              <span class={[
                "inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold",
                if(@drug.is_dangerous_drug,
                  do: "bg-orange-100 text-orange-800",
                  else: "bg-slate-100 text-slate-600"
                )
              ]}>
                {if @drug.is_dangerous_drug, do: "In DDA", else: "Not in DDA"}
              </span>
            </div>
          </div>

          <div class="flex w-full flex-col gap-3 sm:flex-row sm:flex-wrap xl:w-auto xl:max-w-2xl xl:justify-end">
            <.button
              phx-click="open_edit_drug_modal"
              class="inline-flex min-h-[3.25rem] items-center justify-center gap-2 bg-[#373896] px-5 text-sm shadow-sm hover:bg-[#2f317f]"
            >
              <.icon name="hero-pencil-square" class="h-4 w-4" /> Edit Drug
            </.button>

            <.button
              type="button"
              phx-click="open_requisition_modal"
              phx-value-inventory_received_id={@drug.inventory_received_id}
              phx-value-item_title={"#{@drug.generic_name || @drug.inventory_received.generic_name}"}
              phx-value-item_description={
                @drug.brand_name || @drug.inventory_received.brand_name || ""
              }
              class="inline-flex min-h-[3.25rem] items-center justify-center gap-2 bg-[#23395d] px-5 text-sm shadow-sm hover:bg-[#1b2f4d]"
            >
              <.icon name="hero-document-plus" class="h-4 w-4" /> Make requisition
            </.button>

            <button type="button" phx-click="toggle_dangerous_drug" class={dda_button_class(@drug)}>
              <.icon name="hero-clipboard-document-list" class="h-4 w-4" />
              {if @drug.is_dangerous_drug, do: "Remove from DDA", else: "Add to DDA"}
            </button>
          </div>
        </div>
      </div>

      <div class="mb-6 flex flex-col gap-4 border-b border-gray-200 pb-2 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <.link
            patch={~p"/pharmacist/drugs/#{@drug.id}"}
            class={[
              "inline-flex items-center gap-2 border-b-2 px-4 py-2 text-sm font-medium -mb-px transition-colors",
              if(@drug_tab == :batches,
                do: "border-[#373896] text-[#373896]",
                else: "border-transparent text-gray-500 hover:text-gray-700"
              )
            ]}
          >
            Batches
          </.link>
          <.link
            patch={~p"/pharmacist/drugs/#{@drug.id}?drug_tab=allocations"}
            class={[
              "inline-flex items-center gap-2 border-b-2 px-4 py-2 text-sm font-medium -mb-px transition-colors",
              if(@drug_tab == :allocations,
                do: "border-[#373896] text-[#373896]",
                else: "border-transparent text-gray-500 hover:text-gray-700"
              )
            ]}
          >
            Drug Allocations
          </.link>
          <.link
            patch={~p"/pharmacist/drugs/#{@drug.id}?drug_tab=prescriptions"}
            class={[
              "inline-flex items-center gap-2 border-b-2 px-4 py-2 text-sm font-medium -mb-px transition-colors",
              if(@drug_tab == :prescriptions,
                do: "border-[#373896] text-[#373896]",
                else: "border-transparent text-gray-500 hover:text-gray-700"
              )
            ]}
          >
            Prescriptions
          </.link>
        </div>

        <div class="text-xs font-medium uppercase tracking-[0.18em] text-slate-400">
          {case @drug_tab do
            :batches -> "Batch inventory view"
            :allocations -> "Allocation activity view"
            :prescriptions -> "Prescriptions across all patients"
          end}
        </div>
      </div>

      <%!-- Batches panel --%>
      <%= if @drug_tab == :batches do %>
        <div class="flex flex-wrap items-center gap-2 mb-4">
          <button
            phx-click="switch_batch_tab"
            phx-value-tab="active"
            class={[
              "px-3 py-1.5 text-xs font-medium rounded-full transition-colors",
              if(@batch_tab == :active,
                do: "bg-[#373896] text-white",
                else: "bg-gray-100 text-gray-600 hover:bg-gray-200"
              )
            ]}
          >
            Active
          </button>
          <button
            phx-click="switch_batch_tab"
            phx-value-tab="discarded"
            class={[
              "px-3 py-1.5 text-xs font-medium rounded-full transition-colors",
              if(@batch_tab == :discarded,
                do: "bg-[#373896] text-white",
                else: "bg-gray-100 text-gray-600 hover:bg-gray-200"
              )
            ]}
          >
            Discarded
          </button>

          <div class="ml-auto flex flex-1 flex-wrap items-center justify-end gap-2">
            <.filter_drawer
              id="drug-batches-filters"
              title="Filter batches"
              apply_event="filter_batches"
              clear_event="clear_batch_filters"
              active_count={count_active_batch_filters(@expiry_filters)}
            >
              <:group label="Expiry">
                <.expiry_filter_fields
                  status_value={@expiry_filters[:expiry_status]}
                  from_value={@expiry_filters[:expiry_from]}
                  to_value={@expiry_filters[:expiry_to]}
                />
              </:group>

              <:chip
                :for={chip <- batch_filter_chips(@expiry_filters)}
                label={chip.label}
                clear={JS.push("clear_batch_chip", value: %{"field" => chip.field})}
              />
            </.filter_drawer>
          </div>
        </div>

        <div class="overflow-hidden">
          <.table id="drug_batches" rows={@drug_batches}
            row_id={&"drug_batches-#{&1.id}"}
          >
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

            <:col :let={drug_batch} label="Batch">
              <div class="py-3">
                <span class="px-2 py-1 rounded-full bg-[#e7e7ff] text-[#373896] text-sm font-medium">
                  {if drug_batch.batch, do: drug_batch.batch.batch, else: "—"}
                </span>
              </div>
            </:col>

            <:col :let={drug_batch} label="Status">
              <div class="py-3">
                <%= if drug_batch.is_confirmed do %>
                  <span class="px-2 py-1 rounded-full bg-green-100 text-green-800 text-sm font-medium">
                    Confirmed
                  </span>
                <% else %>
                  <span class="px-2 py-1 rounded-full bg-amber-100 text-amber-800 text-sm font-medium">
                    Pending
                  </span>
                <% end %>
              </div>
            </:col>

            <:col :let={drug_batch} label="Expiry">
              <div class="py-3">
                <%= if drug_batch.batch && drug_batch.batch.expiry do %>
                  <% expired = batch_expired?(drug_batch.batch.expiry) %>
                  <span class={[
                    "text-sm font-medium",
                    if(expired, do: "text-amber-600", else: "text-gray-700")
                  ]}>
                    {drug_batch.batch.expiry}
                    <%= if expired do %>
                      <span class="ml-1 text-amber-600">(Expired)</span>
                    <% end %>
                  </span>
                <% else %>
                  <span class="text-sm text-gray-400">—</span>
                <% end %>
              </div>
            </:col>

            <:col :let={drug_batch} label="Remaining Qty">
              <div class="py-3">
                <%= if drug_batch.remaining_quantity == 0 do %>
                  <span class="px-2 py-1 rounded-full bg-red-100 text-red-800 text-sm font-medium">
                    Out of Stock
                  </span>
                <% else %>
                  <%= cond do %>
                    <% drug_batch.remaining_quantity <= 10 -> %>
                      <span class="px-2 py-1 rounded-full bg-orange-100 text-orange-800 text-sm font-medium">
                        {drug_batch.remaining_quantity} (Low)
                      </span>
                    <% true -> %>
                      <span class="px-2 py-1 rounded-full bg-green-100 text-green-800 text-sm font-medium">
                        {drug_batch.remaining_quantity}
                      </span>
                  <% end %>
                <% end %>
              </div>
            </:col>

            <:col :let={drug_batch} label="Actions">
              <div class="py-3 flex flex-wrap items-center gap-2">
                <%= if @batch_tab == :active do %>
                  <.button
                    type="button"
                    phx-click="discard_batch"
                    phx-value-id={drug_batch.id}
                    data-confirm="Discard this batch? It will be hidden from drug listing and search."
                    class="text-amber-600 hover:text-amber-800 text-sm"
                  >
                    <.icon name="hero-trash" class="h-4 w-4" /> Discard
                  </.button>
                <% else %>
                  <.button
                    type="button"
                    phx-click="reactivate_batch"
                    phx-value-id={drug_batch.id}
                    data-confirm="Reactivate this batch? It will appear in drug listing and search again."
                    class="text-green-600 hover:text-green-800 text-sm"
                  >
                    <.icon name="hero-arrow-path" class="h-4 w-4" /> Reactivate
                  </.button>
                <% end %>
              </div>
            </:col>
          </.table>
        </div>
      <% end %>

      <%!-- Drugs Given panel --%>
      <%= if @drug_tab == :allocations do %>
        <.blank_state
          :if={@drugs_given_count == 0}
          icon_path="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
          title="No dispensing activity found"
          description="This drug has not been dispensed to any patient yet."
        />

        <.table :if={@drugs_given_count > 0} id="drugs_given" rows={@drugs_given}
          row_id={&"drugs_given-#{&1.id}"}
        >
          <:col :let={dg} label="Patient">
            <div class="py-2 font-medium text-gray-900">
              {[
                dg.drug_allocation.patient.first_name,
                dg.drug_allocation.patient.middle_name,
                dg.drug_allocation.patient.last_name
              ]
              |> Enum.filter(& &1)
              |> Enum.join(" ")}
            </div>
          </:col>

          <:col :let={dg} label="Pharmacist">
            <div class="py-2 text-gray-700">
              {if dg.pharmacist, do: dg.pharmacist.name, else: "—"}
            </div>
          </:col>

          <:col :let={dg} label="Qty Given">
            <div class="py-2">
              <span class="text-sm font-semibold text-[#373896]">&times;{dg.quantity}</span>
            </div>
          </:col>

          <:col :let={dg} label="Price">
            <div class="py-2 text-sm text-gray-900">
              KSh {Number.Delimit.number_to_delimited(dg.price, delimiter: ",")}
            </div>
          </:col>

          <:col :let={dg} label="Batches">
            <div class="py-2 flex flex-wrap gap-1">
              <%= for ba <- dg.batch_allocations do %>
                <span class="px-2 py-0.5 bg-[#e7e7ff] text-[#373896] text-xs rounded-full font-medium">
                  Batch #{ba.batch_id} &times;{ba.quantity}
                </span>
              <% end %>
            </div>
          </:col>

          <:col :let={dg} label="Date Given">
            <div class="py-2 text-sm text-gray-600">
              {Calendar.strftime(dg.inserted_at, "%d %b %Y, %H:%M")}
            </div>
          </:col>

          <:col :let={dg} label="">
            <div class="py-2">
              <.link
                navigate={~p"/pharmacist/drug_allocations/#{dg.drug_allocation_id}"}
                class="text-[#373896] hover:text-[#6667ab] text-sm font-medium"
              >
                <.icon name="hero-eye" class="h-4 w-4 inline mr-1" /> View Allocation
              </.link>
            </div>
          </:col>
        </.table>

        <.pagination
          page={@drugs_given_page}
          total_pages={@drugs_given_total_pages}
          total_count={@drugs_given_count}
          per_page={@drugs_given_per_page}
          event="paginate_drugs_given"
        />
      <% end %>

      <%!-- Prescriptions panel --%>
      <%= if @drug_tab == :prescriptions do %>
        <div class="flex flex-wrap items-center gap-2 mb-4">
          <button
            phx-click="filter_prescriptions_status"
            phx-value-status="all"
            class={[
              "px-3 py-1.5 text-xs font-medium rounded-full transition-colors",
              if(@prescriptions_status == nil,
                do: "bg-[#373896] text-white",
                else: "bg-gray-100 text-gray-600 hover:bg-gray-200"
              )
            ]}
          >
            All
          </button>
          <button
            phx-click="filter_prescriptions_status"
            phx-value-status="pending"
            class={[
              "px-3 py-1.5 text-xs font-medium rounded-full transition-colors",
              if(@prescriptions_status == "pending",
                do: "bg-[#373896] text-white",
                else: "bg-gray-100 text-gray-600 hover:bg-gray-200"
              )
            ]}
          >
            Pending
          </button>
          <button
            phx-click="filter_prescriptions_status"
            phx-value-status="given"
            class={[
              "px-3 py-1.5 text-xs font-medium rounded-full transition-colors",
              if(@prescriptions_status == "given",
                do: "bg-[#373896] text-white",
                else: "bg-gray-100 text-gray-600 hover:bg-gray-200"
              )
            ]}
          >
            Given
          </button>
        </div>

        <.blank_state
          :if={@drug_prescriptions_count == 0}
          icon_path="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
          title="No prescriptions found"
          description={
            if @prescriptions_status,
              do: "No prescriptions match this filter.",
              else: "This drug has not been prescribed to any patient yet."
          }
        />

        <.table
          :if={@drug_prescriptions_count > 0}
          id="drug_prescriptions"
          rows={@drug_prescriptions}
          row_id={&"drug_prescriptions-#{&1.id}"}
        >
          <:col :let={da} label="Patient">
            <div class="py-2 font-medium text-gray-900">
              {[da.patient.first_name, da.patient.middle_name, da.patient.last_name]
              |> Enum.filter(& &1)
              |> Enum.join(" ")}
            </div>
          </:col>

          <:col :let={da} label="Date">
            <div class="py-2 text-sm text-gray-600">
              {Calendar.strftime(da.inserted_at, "%d %b %Y, %H:%M")}
            </div>
          </:col>

          <:col :let={da} label="Prescribing Doctor">
            <div class="py-2 text-gray-700">
              {if da.doctor, do: "Dr. #{da.doctor.name}", else: "—"}
            </div>
          </:col>

          <:col :let={da} label="Status">
            <%= if da.has_been_assigned do %>
              <span class="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-medium text-emerald-700">
                <span class="h-1.5 w-1.5 rounded-full bg-emerald-500"></span> Given
              </span>
            <% else %>
              <span class="inline-flex items-center gap-1.5 rounded-full bg-amber-50 px-2.5 py-1 text-xs font-medium text-amber-700">
                <span class="h-1.5 w-1.5 rounded-full bg-amber-500"></span> Pending
              </span>
            <% end %>
          </:col>

          <:col :let={da} label="">
            <div class="py-2">
              <.link
                navigate={~p"/pharmacist/drug_allocations/#{da.id}"}
                class="text-[#373896] hover:text-[#6667ab] text-sm font-medium"
              >
                <.icon name="hero-eye" class="h-4 w-4 inline mr-1" /> View Allocation
              </.link>
            </div>
          </:col>
        </.table>

        <.pagination
          page={@prescriptions_page}
          total_pages={@prescriptions_total_pages}
          total_count={@drug_prescriptions_count}
          per_page={@prescriptions_per_page}
          event="paginate_prescriptions"
        />
      <% end %>
    </div>

    <%!-- Edit Drug Details Modal --%>
    <%= if @editing_drug do %>
      <div class="fixed inset-0 z-50 overflow-y-auto">
        <div class="fixed inset-0 bg-black bg-opacity-50 transition-opacity"></div>
        <div class="flex min-h-full items-center justify-center p-4">
          <div class="relative bg-white rounded-lg shadow-xl max-w-md w-full p-6">
            <div class="mb-4">
              <h3 class="text-lg font-semibold text-gray-900">Edit Drug Details</h3>
              <p class="mt-1 text-sm text-gray-600">
                Update the generic and brand name for this drug.
              </p>
            </div>
            <form phx-submit="save_drug_details" class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Generic Name</label>
                <input
                  type="text"
                  name="generic_name"
                  value={@drug.generic_name || @drug.inventory_received.generic_name || ""}
                  class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#373896] focus:border-transparent"
                  placeholder="e.g. Paracetamol"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Brand Name</label>
                <input
                  type="text"
                  name="brand_name"
                  value={@drug.brand_name || @drug.inventory_received.brand_name || ""}
                  class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#373896] focus:border-transparent"
                  placeholder="e.g. Panadol"
                />
              </div>
              <div class="flex gap-3 pt-4">
                <button
                  type="submit"
                  class="flex-1 px-4 py-2 bg-[#373896] text-white rounded-lg hover:bg-[#6667ab] font-medium transition-colors"
                >
                  Save Changes
                </button>
                <button
                  type="button"
                  phx-click="close_edit_drug_modal"
                  class="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 font-medium transition-colors"
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    <% end %>

    <%!-- Edit Quantity Modal --%>
    <%= if @editing_batch do %>
      <div class="fixed inset-0 z-50 overflow-y-auto">
        <%!-- Overlay --%>
        <div class="fixed inset-0 bg-black bg-opacity-50 transition-opacity"></div>

        <%!-- Modal --%>
        <div class="flex min-h-full items-center justify-center p-4">
          <div class="relative bg-white rounded-lg shadow-xl max-w-md w-full p-6">
            <%!-- Header --%>
            <div class="mb-4">
              <h3 class="text-lg font-semibold text-gray-900">
                Update Remaining Quantity
              </h3>
              <p class="mt-2 text-sm text-gray-600">
                <span class="font-medium">{@editing_batch.inventory_received.brand_name}</span>
                - Batch: <span class="font-medium">{@editing_batch.batch.batch}</span>
              </p>
            </div>

            <%!-- Error Message --%>
            <%= if @error_message do %>
              <div class="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-800 text-sm">
                {@error_message}
              </div>
            <% end %>

            <%!-- Form --%>
            <form phx-submit="update_remaining_quantity" class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">
                  Current Quantity:
                  <span class="text-[#373896] font-semibold">
                    {@editing_batch.remaining_quantity}
                  </span>
                </label>
                <input
                  type="number"
                  name="remaining_quantity"
                  value={@editing_batch.remaining_quantity}
                  min="0"
                  required
                  class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#373896] focus:border-transparent text-lg"
                  placeholder="Enter new quantity"
                  autofocus
                />
              </div>

              <%!-- Action Buttons --%>
              <div class="flex gap-3 pt-4">
                <button
                  type="submit"
                  class="flex-1 px-4 py-2 bg-[#373896] text-white rounded-lg hover:bg-[#6667ab] font-medium transition-colors"
                >
                  Save Changes
                </button>
                <button
                  type="button"
                  phx-click="close_modal"
                  class="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 font-medium transition-colors"
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    <% end %>

    <%!-- Make requisition modal --%>
    <%= if @requisition_prefill do %>
      <.modal
        id="requisition-for-item-modal"
        show
        on_cancel={JS.patch(~p"/pharmacist/drugs/#{@drug.id}")}
      >
        <.live_component
          module={MedcampWeb.RequisitionLive.RequisitionForItemComponent}
          id="requisition-for-item"
          inventory_received_id={@requisition_prefill.inventory_received_id}
          item_title={@requisition_prefill.item_title}
          item_description={@requisition_prefill.item_description}
          current_user={@current_user}
          patch={~p"/pharmacist/drugs/#{@drug.id}"}
        />
      </.modal>
    <% end %>
    """
  end

  defp dda_button_class(drug) do
    base =
      "inline-flex min-h-[3.25rem] items-center justify-center gap-2 rounded-lg px-5 py-2 text-sm font-semibold shadow-sm transition-colors"

    state_class =
      if drug.is_dangerous_drug do
        "border border-orange-300 bg-orange-50 text-orange-700 hover:bg-orange-100"
      else
        "border border-amber-300 bg-amber-50 text-amber-800 hover:bg-amber-100"
      end

    base <> " " <> state_class
  end

  defp batch_expired?(nil), do: false

  defp batch_expired?(expiry_string) when is_binary(expiry_string) do
    case Date.from_iso8601(expiry_string) do
      {:ok, expiry_date} -> Date.compare(expiry_date, Date.utc_today()) == :lt
      _ -> false
    end
  end

  defp batch_expired?(_), do: false
end
