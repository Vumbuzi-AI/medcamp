defmodule MedcampWeb.StockRequests.Hub do
  @moduledoc """
  Shared implementation for the per-bucket "Stock Change Requests" hub.

  A bucket user (pharmacist → drug batches, lab → lab allocations, nurse →
  nursing allocations, reception → received batches) can raise three kinds of
  stock change requests — donations, expiry write-offs and stock takes — all
  scoped to their own bucket. Nothing here mutates stock: requests are submitted
  for admin approval, mirroring the admin-side flow.

  Each role gets a thin LiveView (`MedcampWeb.<Role>StockRequestLive`) that only
  picks its layout macro and its bucket, then delegates `mount/handle_event/
  render` here. Adding another bucket later is a new wrapper + route + menu item.
  """

  use MedcampWeb, :html

  # Only the LiveView-specific helpers; assign/upload_errors/~H come from
  # Phoenix.Component via `:html` (avoids an ambiguous `assign` import).
  import Phoenix.LiveView,
    only: [put_flash: 3, allow_upload: 3, consume_uploaded_entries: 3]

  alias Medcamp.Departments
  alias Medcamp.InventoryDisposals
  alias Medcamp.StockTakes

  @upload_dir Path.join(Application.app_dir(:medcamp, "priv/uploads"), "donations")

  # How many matches the picker shows, and how many rows we pull from the
  # database first when an expiry filter still has to be applied in memory.
  @result_limit 20
  @filtered_candidate_limit 300

  @bucket_labels %{
    "drug_batch" => "pharmacy batch",
    "lab_allocation" => "lab allocation",
    "nursing_allocation" => "nursing allocation",
    "inventory_received" => "received batch"
  }

  # ── Mount ───────────────────────────────────────────────────────────────────

  def mount(bucket, active_tab, _params, _session, socket) do
    default_department_id =
      socket.assigns.current_user.department_id || get_department_id_for_bucket(bucket)

    {:ok,
     socket
     |> assign(:active_tab, active_tab)
     |> assign(:bucket, bucket)
     |> assign(:bucket_label, Map.get(@bucket_labels, bucket, "item"))
     |> assign(:page_title, "Stock Change Requests")
     |> assign(:kind, "donation")
     |> assign(:view, :list)
     |> assign(:show_new_form, false)
     |> assign(:disposal, nil)
     |> assign(:stock_take, nil)
     |> assign(:departments, Departments.list_departments_for_selection())
     |> assign(:default_department_id, default_department_id)
     |> assign(:search_query, "")
     |> assign(:search_results, [])
     |> assign(:expiry_filter, "")
     |> assign(:expiry_from, "")
     |> assign(:expiry_to, "")
     |> assign(:editing_entry_id, nil)
     |> allow_upload(:supporting_document,
       accept: ~w(.pdf),
       max_entries: 1,
       max_file_size: 20_000_000,
       auto_upload: true,
       progress: &handle_document_progress/3
     )
     |> load_requests()}
  end

  defp load_requests(socket) do
    user_id = socket.assigns.current_user.id

    socket
    |> assign(:disposals, InventoryDisposals.list_requester_disposals(user_id))
    |> assign(:stock_takes, StockTakes.list_requester_stock_takes(user_id))
  end

  # ── Navigation between kinds / views ─────────────────────────────────────────

  def handle_event("select_kind", %{"kind" => kind}, socket)
      when kind in ["donation", "expiry", "stock_take"] do
    {:noreply,
     socket
     |> assign(:kind, kind)
     |> assign(:view, :list)
     |> assign(:show_new_form, false)
     |> reset_search()}
  end

  def handle_event("show_new_form", _, socket),
    do: {:noreply, assign(socket, :show_new_form, true)}

  def handle_event("cancel_new", _, socket),
    do: {:noreply, assign(socket, :show_new_form, false)}

  def handle_event("back_to_list", _, socket) do
    {:noreply,
     socket
     |> assign(:view, :list)
     |> assign(:disposal, nil)
     |> assign(:stock_take, nil)
     |> reset_search()
     |> load_requests()}
  end

  def handle_event("validate", _params, socket), do: {:noreply, socket}

  # ── Create ────────────────────────────────────────────────────────────────

  def handle_event("create_disposal", params, socket) do
    kind = socket.assigns.kind

    attrs = %{
      "kind" => kind,
      "date" => params["date"],
      "reason" => params["reason"],
      "requested_by_id" => socket.assigns.current_user.id
    }

    case InventoryDisposals.create_disposal(attrs) do
      {:ok, disposal} ->
        next_step =
          if kind == "donation",
            do: "Add its items and attach the donation PDF next.",
            else: "Add its items next."

        {:noreply,
         socket
         |> assign(:show_new_form, false)
         |> open_disposal(disposal.id)
         |> put_flash(:info, "#{kind_label(kind)} request started. #{next_step}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, put_flash(socket, :error, changeset_error(changeset))}
    end
  end

  def handle_event("remove_supporting_document", _, socket) do
    case InventoryDisposals.remove_supporting_document(socket.assigns.disposal) do
      {:ok, _updated} ->
        {:noreply,
         socket
         |> reload_disposal()
         |> put_flash(:info, "Document removed.")}

      {:error, :not_draft} ->
        {:noreply, put_flash(socket, :error, "This request can no longer be edited.")}
    end
  end

  def handle_event("create_stock_take", params, socket) do
    user = socket.assigns.current_user

    attrs = %{
      "date" => params["date"],
      "notes" => params["notes"],
      "requested_by_id" => user.id,
      "department_id" => params["department_id"]
    }

    case StockTakes.create_stock_take(attrs) do
      {:ok, stock_take} ->
        {:noreply,
         socket
         |> assign(:show_new_form, false)
         |> open_stock_take(stock_take.id)
         |> put_flash(:info, "Stock take started. Add the items you counted.")}

      {:error, changeset} ->
        {:noreply, put_flash(socket, :error, changeset_error(changeset))}
    end
  end

  def handle_event("open_disposal", %{"id" => id}, socket),
    do: {:noreply, open_disposal(socket, id)}

  def handle_event("open_stock_take", %{"id" => id}, socket),
    do: {:noreply, open_stock_take(socket, id)}

  # ── Delete a whole request ───────────────────────────────────────────────────

  # Only the requester's own, not-yet-approved requests can be deleted; once an
  # admin has approved, stock has moved and the request is the audit record.
  def handle_event("delete_disposal", %{"id" => id}, socket) do
    disposal = InventoryDisposals.get_disposal!(String.to_integer(id))

    if disposal.requested_by_id == socket.assigns.current_user.id do
      case InventoryDisposals.delete_disposal(disposal) do
        {:ok, _} ->
          {:noreply,
           socket
           |> assign(:view, :list)
           |> assign(:disposal, nil)
           |> reset_search()
           |> load_requests()
           |> put_flash(:info, "#{kind_label(disposal.kind)} request deleted.")}

        {:error, :already_applied} ->
          {:noreply,
           put_flash(
             socket,
             :error,
             "This request has already changed stock and cannot be deleted."
           )}

        {:error, :not_deletable} ->
          {:noreply, put_flash(socket, :error, "Approved requests cannot be deleted.")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "That request could not be deleted.")}
      end
    else
      {:noreply, put_flash(socket, :error, "That request was not found.")}
    end
  end

  def handle_event("delete_stock_take", %{"id" => id}, socket) do
    stock_take = StockTakes.get_stock_take!(String.to_integer(id))

    if stock_take.requested_by_id == socket.assigns.current_user.id do
      case StockTakes.delete_requester_stock_take(stock_take) do
        {:ok, _} ->
          {:noreply,
           socket
           |> assign(:view, :list)
           |> assign(:stock_take, nil)
           |> reset_search()
           |> load_requests()
           |> put_flash(:info, "Stock take deleted.")}

        {:error, :not_deletable} ->
          {:noreply, put_flash(socket, :error, "Approved stock takes cannot be deleted.")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "That stock take could not be deleted.")}
      end
    else
      {:noreply, put_flash(socket, :error, "That stock take was not found.")}
    end
  end

  # ── Search (bucket-scoped) ───────────────────────────────────────────────────

  # Either input can drive the list on its own: a search term, an expiry preset,
  # or a custom expiry range. Only an empty search *and* no expiry filter clears
  # the results.
  def handle_event("search", %{"q" => query} = params, socket) do
    expiry_filter =
      Medcamp.ExpiryFilter.normalize(params["expiry_filter"] || socket.assigns.expiry_filter)

    expiry_from = params["expiry_from"] || socket.assigns.expiry_from
    expiry_to = params["expiry_to"] || socket.assigns.expiry_to

    expiry_active? =
      Medcamp.ExpiryFilter.bounds(expiry_filter, expiry_from, expiry_to) != {nil, nil}

    searching? = String.trim(query) != ""

    results =
      if searching? or expiry_active? do
        socket.assigns.bucket
        |> run_search(socket.assigns.kind, query, search_limit(expiry_active?))
        |> filter_by_expiry(socket.assigns.bucket, expiry_filter, expiry_from, expiry_to)
        |> reject_already_added(socket)
        |> Enum.take(@result_limit)
      else
        []
      end

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:expiry_filter, expiry_filter)
     |> assign(:expiry_from, expiry_from)
     |> assign(:expiry_to, expiry_to)
     |> assign(:search_results, results)}
  end

  # ── Disposal items ───────────────────────────────────────────────────────────

  def handle_event("add_source", params, socket) do
    bucket = socket.assigns.bucket
    disposal = socket.assigns.disposal
    source = Enum.find(socket.assigns.search_results, &(to_string(&1.id) == params["source_id"]))

    with false <- disposal.status != "draft",
         source when not is_nil(source) <- source,
         {quantity, ""} when quantity > 0 <- Integer.parse(params["quantity"] || ""),
         attrs <-
           bucket
           |> InventoryDisposals.source_attributes(source)
           |> Map.merge(%{
             inventory_disposal_id: disposal.id,
             quantity: quantity,
             notes: params["notes"]
           }),
         :ok <- check_available(attrs, quantity),
         {:ok, _item} <- InventoryDisposals.create_item(attrs) do
      {:noreply,
       socket
       |> reload_disposal()
       |> refresh_search()
       |> put_flash(:info, "Item added to the request.")}
    else
      true ->
        {:noreply, put_flash(socket, :error, "Only draft requests can be changed.")}

      nil ->
        {:noreply, put_flash(socket, :error, "That item is no longer available.")}

      :error ->
        {:noreply, put_flash(socket, :error, "Enter a valid quantity greater than zero.")}

      {:error, :exceeds_available, available, uom} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "You can request at most #{available} #{uom} — that is all the stock remaining on this #{socket.assigns.bucket_label}."
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, put_flash(socket, :error, changeset_error(changeset))}

      {_quantity, _rest} ->
        {:noreply, put_flash(socket, :error, "Enter a whole-number quantity greater than zero.")}
    end
  end

  def handle_event("delete_item", %{"id" => id}, socket) do
    disposal = socket.assigns.disposal

    if disposal.status == "draft" do
      item = id |> String.to_integer() |> InventoryDisposals.get_item!()

      if item.inventory_disposal_id == disposal.id do
        InventoryDisposals.delete_item(item)

        {:noreply,
         socket |> reload_disposal() |> refresh_search() |> put_flash(:info, "Item removed.")}
      else
        {:noreply, put_flash(socket, :error, "That item does not belong to this request.")}
      end
    else
      {:noreply, put_flash(socket, :error, "Only draft requests can be changed.")}
    end
  end

  def handle_event("submit_disposal", _, socket) do
    case InventoryDisposals.submit(socket.assigns.disposal) do
      {:ok, _} ->
        {:noreply,
         socket
         |> reload_disposal()
         |> load_requests()
         |> put_flash(:info, "Request submitted for admin approval.")}

      {:error, :no_items} ->
        {:noreply, put_flash(socket, :error, "Add at least one item before submitting.")}

      {:error, {:insufficient_stock, name, available}} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "#{name} now has only #{available} left. Remove that item and add it again with a smaller quantity."
         )}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "This request cannot be submitted.")}
    end
  end

  # ── Stock take entries ───────────────────────────────────────────────────────

  def handle_event("add_entry", %{"id" => id}, socket) do
    bucket = socket.assigns.bucket
    stock_take = socket.assigns.stock_take
    source = Enum.find(socket.assigns.search_results, &(to_string(&1.id) == id))

    cond do
      stock_take.status != "draft" ->
        {:noreply, put_flash(socket, :error, "Only draft stock takes can be changed.")}

      is_nil(source) ->
        {:noreply, put_flash(socket, :error, "That item is no longer available.")}

      StockTakes.entry_already_in_stock_take?(stock_take.id, bucket, source.id) ->
        {:noreply, put_flash(socket, :info, "Item already added to this stock take.")}

      true ->
        attrs = InventoryDisposals.source_attributes(bucket, source)

        entry_attrs = %{
          stock_take_id: stock_take.id,
          entity_type: attrs.entity_type,
          entity_id: attrs.entity_id,
          entity_name: attrs.entity_name,
          category: attrs.category,
          previous_quantity: attrs.available_quantity,
          uom: attrs.uom
        }

        case StockTakes.create_entry(entry_attrs) do
          {:ok, _entry} ->
            {:noreply, socket |> reload_stock_take() |> refresh_search()}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to add item.")}
        end
    end
  end

  def handle_event("edit_entry", %{"id" => id}, socket),
    do: {:noreply, assign(socket, :editing_entry_id, String.to_integer(id))}

  def handle_event("cancel_edit", _, socket),
    do: {:noreply, assign(socket, :editing_entry_id, nil)}

  def handle_event(
        "save_count",
        %{"entry_id" => entry_id, "counted_quantity" => qty} = params,
        socket
      ) do
    entry = StockTakes.get_entry!(String.to_integer(entry_id))

    case Integer.parse(String.trim(qty)) do
      {counted, _} ->
        attrs = %{
          counted_quantity: counted,
          difference: counted - entry.previous_quantity,
          notes: Map.get(params, "notes", ""),
          uom: params |> Map.get("uom", "") |> String.trim()
        }

        case StockTakes.update_entry(entry, attrs) do
          {:ok, _} ->
            {:noreply, socket |> assign(:editing_entry_id, nil) |> reload_stock_take()}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to save count.")}
        end

      :error ->
        {:noreply, put_flash(socket, :error, "Please enter a valid number.")}
    end
  end

  def handle_event("delete_entry", %{"id" => id}, socket) do
    entry = StockTakes.get_entry!(String.to_integer(id))

    if entry.stock_take_id == socket.assigns.stock_take.id do
      StockTakes.delete_entry(entry)
    end

    {:noreply, reload_stock_take(socket)}
  end

  def handle_event("submit_stock_take", _, socket) do
    case StockTakes.submit_stock_take(socket.assigns.stock_take) do
      {:ok, _} ->
        {:noreply,
         socket
         |> reload_stock_take()
         |> load_requests()
         |> put_flash(:info, "Stock take submitted for admin approval.")}

      {:error, :no_counts} ->
        {:noreply,
         put_flash(socket, :error, "Record at least one counted quantity before submitting.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "This stock take cannot be submitted.")}
    end
  end

  # Nothing else should crash the process (see FunctionClauseError safety).
  def handle_event(_event, _params, socket), do: {:noreply, socket}

  # Re-runs the current search/filter after an item is added, so the picker stays
  # open on the same result set and several items can be added in a row (the
  # newly added one drops out, since it is now on the request).
  defp refresh_search(socket) do
    query = socket.assigns.search_query
    expiry_filter = socket.assigns.expiry_filter
    expiry_from = socket.assigns.expiry_from
    expiry_to = socket.assigns.expiry_to

    expiry_active? =
      Medcamp.ExpiryFilter.bounds(expiry_filter, expiry_from, expiry_to) != {nil, nil}

    results =
      if String.trim(query) != "" or expiry_active? do
        socket.assigns.bucket
        |> run_search(socket.assigns.kind, query, search_limit(expiry_active?))
        |> filter_by_expiry(socket.assigns.bucket, expiry_filter, expiry_from, expiry_to)
        |> reject_already_added(socket)
        |> Enum.take(@result_limit)
      else
        []
      end

    assign(socket, :search_results, results)
  end

  defp reject_already_added(results, socket) do
    added =
      case socket.assigns do
        %{view: :build_disposal, disposal: %{items: items}} when is_list(items) ->
          MapSet.new(items, & &1.entity_id)

        %{view: :build_stock_take, stock_take: %{entries: entries}} when is_list(entries) ->
          MapSet.new(entries, & &1.entity_id)

        _ ->
          MapSet.new()
      end

    Enum.reject(results, &MapSet.member?(added, &1.id))
  end

  # Expiry lives on a string column for some buckets and is filtered in memory,
  # so when a filter is on we pull a wider candidate set and trim afterwards —
  # otherwise the first @result_limit rows alphabetically could all be filtered
  # out and the list would look empty.
  defp search_limit(false), do: @result_limit
  defp search_limit(true), do: @filtered_candidate_limit

  # Belt and braces over the input's `max` and the changeset's own check: the
  # browser attribute is trivially bypassed, and the flash here names the
  # remaining quantity instead of showing a bare changeset error.
  defp check_available(attrs, quantity) do
    available = attrs.available_quantity || 0

    if quantity > available,
      do: {:error, :exceeds_available, available, attrs.uom || "units"},
      else: :ok
  end

  # ── State helpers ────────────────────────────────────────────────────────────

  defp open_disposal(socket, id) do
    disposal = InventoryDisposals.get_disposal!(id)

    if disposal.requested_by_id == socket.assigns.current_user.id do
      socket
      |> assign(:disposal, disposal)
      |> assign(:view, :build_disposal)
      |> reset_search()
    else
      put_flash(socket, :error, "That request was not found.")
    end
  end

  defp open_stock_take(socket, id) do
    stock_take = StockTakes.get_stock_take!(id)

    if stock_take.requested_by_id == socket.assigns.current_user.id do
      socket
      |> assign(:stock_take, stock_take)
      |> assign(:view, :build_stock_take)
      |> reset_search()
    else
      put_flash(socket, :error, "That stock take was not found.")
    end
  end

  defp reload_disposal(socket),
    do: assign(socket, :disposal, InventoryDisposals.get_disposal!(socket.assigns.disposal.id))

  defp reload_stock_take(socket),
    do: assign(socket, :stock_take, StockTakes.get_stock_take!(socket.assigns.stock_take.id))

  defp reset_search(socket),
    do:
      socket
      |> assign(:search_query, "")
      |> assign(:search_results, [])
      |> assign(:expiry_filter, "")
      |> assign(:expiry_from, "")
      |> assign(:expiry_to, "")

  defp run_search(bucket, kind, query, limit) do
    raw =
      case bucket do
        "drug_batch" -> StockTakes.search_drug_batches(query, limit)
        "lab_allocation" -> StockTakes.search_lab_allocations(query, limit)
        "nursing_allocation" -> StockTakes.search_nursing_allocations(query, limit)
        "inventory_received" -> StockTakes.search_inventory_received(query, limit)
        _ -> []
      end

    # Donations/expiry can only remove stock that exists; stock takes can
    # recount an item down to (or up from) any level.
    if kind == "stock_take",
      do: raw,
      else: Enum.filter(raw, &((&1.remaining_quantity || 0) > 0))
  end

  # Expiry presets and the custom range, both resolved through
  # `Medcamp.ExpiryFilter` so they mean the same here as on every other listing.
  # Items with no (or unparseable) expiry match no filter — an unknown expiry is
  # not evidence that stock is still good.
  defp filter_by_expiry(results, bucket, filter, from, to) do
    if Medcamp.ExpiryFilter.bounds(filter, from, to) == {nil, nil} do
      results
    else
      Enum.filter(results, fn result ->
        bucket
        |> InventoryDisposals.source_expiry(result)
        |> Medcamp.ExpiryFilter.matches?(filter, from, to)
      end)
    end
  end

  defp expiry_filter_active?(assigns) do
    Medcamp.ExpiryFilter.bounds(assigns.expiry_filter, assigns.expiry_from, assigns.expiry_to) !=
      {nil, nil}
  end

  # auto_upload: true means this fires as soon as the transfer completes,
  # with no separate "Attach document" click needed.
  defp handle_document_progress(:supporting_document, entry, socket) do
    if entry.done? do
      disposal = socket.assigns.disposal

      socket =
        case consume_document_upload(socket) do
          {:ok, attrs} ->
            case InventoryDisposals.attach_supporting_document(disposal, attrs) do
              {:ok, _updated} ->
                socket
                |> reload_disposal()
                |> put_flash(:info, "Supporting document attached.")

              {:error, :not_draft} ->
                put_flash(socket, :error, "This request can no longer be edited.")

              {:error, %Ecto.Changeset{} = changeset} ->
                put_flash(socket, :error, changeset_error(changeset))
            end

          {:error, :document_required} ->
            socket
        end

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  defp consume_document_upload(socket) do
    case socket.assigns.uploads.supporting_document.entries do
      [] ->
        {:error, :document_required}

      _ ->
        [attrs] =
          consume_uploaded_entries(socket, :supporting_document, fn %{path: path}, entry ->
            File.mkdir_p!(@upload_dir)
            filename = "donation_#{System.unique_integer([:positive])}.pdf"
            File.cp!(path, Path.join(@upload_dir, filename))

            {:ok,
             %{
               "supporting_document_path" => "/uploads/donations/#{filename}",
               "supporting_document_name" => entry.client_name
             }}
          end)

        {:ok, attrs}
    end
  end

  defp changeset_error(%Ecto.Changeset{} = changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, _} -> msg end)
    |> Enum.map(fn {field, msgs} ->
      "#{Phoenix.Naming.humanize(field)} #{Enum.join(msgs, ", ")}"
    end)
    |> Enum.join("; ")
  end

  # ── Render ────────────────────────────────────────────────────────────────

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="rounded-xl border border-slate-200 bg-white px-6 py-5 shadow-sm print:hidden">
        <div class="flex flex-wrap items-center gap-3">
          <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-indigo-100">
            <Heroicons.icon name="arrow-up-tray" type="outline" class="h-5 w-5 text-indigo-700" />
          </div>
          <div class="flex-1">
            <h1 class="text-lg font-semibold text-slate-900">Stock Change Requests</h1>
            <p class="text-sm text-slate-500">
              Raise donations, expiry write-offs and stock takes for your {@bucket_label}s.
              An admin approves before any stock changes.
            </p>
          </div>
          <%= if @view == :list do %>
            <button
              phx-click="show_new_form"
              class="rounded-lg bg-[#373896] px-4 py-2 text-sm font-semibold text-white hover:bg-[#2d2e7b]"
            >
              New {kind_label(@kind)} request
            </button>
          <% end %>
        </div>

        <%= if @view == :list do %>
          <div class="mt-5 flex gap-1 border-b border-slate-200">
            <%= for {kind, label} <- [{"donation", "Donations"}, {"expiry", "Expiry"}, {"stock_take", "Stock Takes"}] do %>
              <button
                phx-click="select_kind"
                phx-value-kind={kind}
                class={[
                  "border-b-2 px-5 py-2.5 text-sm font-semibold",
                  @kind == kind && "border-[#373896] text-[#373896]",
                  @kind != kind && "border-transparent text-slate-500 hover:text-slate-700"
                ]}
              >
                {label}
              </button>
            <% end %>
          </div>
        <% end %>
      </div>

      <%= cond do %>
        <% @view == :build_disposal -> %>
          {disposal_builder(assigns)}
        <% @view == :build_stock_take -> %>
          {stock_take_builder(assigns)}
        <% true -> %>
          {list_view(assigns)}
      <% end %>
    </div>
    """
  end

  # ── List view ────────────────────────────────────────────────────────────────

  defp list_view(assigns) do
    ~H"""
    <div class="space-y-6">
      <%= if @show_new_form do %>
        {new_request_form(assigns)}
      <% end %>

      <%= if @kind == "stock_take" do %>
        <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-slate-200 text-sm">
              <thead class="bg-slate-50 text-left text-xs uppercase tracking-wide text-slate-500">
                <tr>
                  <th class="px-5 py-3">Reference</th>
                  <th class="px-5 py-3">Date</th>
                  <th class="px-5 py-3">Items</th>
                  <th class="px-5 py-3">Status</th>
                  <th class="px-5 py-3"></th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100">
                <%= for st <- @stock_takes do %>
                  <tr class="hover:bg-slate-50">
                    <td class="px-5 py-4 font-semibold text-slate-800">#{st.id}</td>
                    <td class="px-5 py-4">{format_date(st.date)}</td>
                    <td class="px-5 py-4">{length(st.entries)}</td>
                    <td class="px-5 py-4">{status_badge(assigns, st.status)}</td>
                    <td class="px-5 py-4 text-right">
                      <div class="flex items-center justify-end gap-3">
                        <button
                          phx-click="open_stock_take"
                          phx-value-id={st.id}
                          class="font-semibold text-[#373896] hover:underline"
                        >
                          {if st.status == "draft", do: "Continue", else: "View"}
                        </button>
                        <button
                          :if={deletable?(st.status)}
                          phx-click="delete_stock_take"
                          phx-value-id={st.id}
                          data-confirm="Delete this stock take? This cannot be undone."
                          class="font-semibold text-red-600 hover:underline"
                        >
                          Delete
                        </button>
                      </div>
                    </td>
                  </tr>
                <% end %>
                <%= if @stock_takes == [] do %>
                  <tr>
                    <td colspan="5" class="px-5 py-12 text-center text-slate-500">
                      No stock takes raised yet.
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      <% else %>
        <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-slate-200 text-sm">
              <thead class="bg-slate-50 text-left text-xs uppercase tracking-wide text-slate-500">
                <tr>
                  <th class="px-5 py-3">Reference</th>
                  <th class="px-5 py-3">Date</th>
                  <th class="px-5 py-3">Items</th>
                  <th class="px-5 py-3">Status</th>
                  <th class="px-5 py-3">Evidence</th>
                  <th class="px-5 py-3"></th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100">
                <%= for disposal <- Enum.filter(@disposals, &(&1.kind == @kind)) do %>
                  <tr class="hover:bg-slate-50">
                    <td class="px-5 py-4 font-semibold text-slate-800">#{disposal.id}</td>
                    <td class="px-5 py-4">{format_date(disposal.date)}</td>
                    <td class="px-5 py-4">{length(disposal.items)}</td>
                    <td class="px-5 py-4">{status_badge(assigns, disposal.status)}</td>
                    <td class="px-5 py-4">
                      <%= if disposal.supporting_document_path do %>
                        <a
                          href={disposal.supporting_document_path}
                          target="_blank"
                          class="font-medium text-[#373896] hover:underline"
                        >
                          View PDF
                        </a>
                      <% else %>
                        <span class="text-slate-400">—</span>
                      <% end %>
                    </td>
                    <td class="px-5 py-4 text-right">
                      <div class="flex items-center justify-end gap-3">
                        <button
                          phx-click="open_disposal"
                          phx-value-id={disposal.id}
                          class="font-semibold text-[#373896] hover:underline"
                        >
                          {if disposal.status == "draft", do: "Continue", else: "View"}
                        </button>
                        <button
                          :if={deletable?(disposal.status)}
                          phx-click="delete_disposal"
                          phx-value-id={disposal.id}
                          data-confirm="Delete this request? This cannot be undone."
                          class="font-semibold text-red-600 hover:underline"
                        >
                          Delete
                        </button>
                      </div>
                    </td>
                  </tr>
                <% end %>
                <%= if Enum.filter(@disposals, &(&1.kind == @kind)) == [] do %>
                  <tr>
                    <td colspan="6" class="px-5 py-12 text-center text-slate-500">
                      No {String.downcase(kind_label(@kind))} requests yet.
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp new_request_form(assigns) do
    ~H"""
    <div class="rounded-xl border border-indigo-200 bg-white p-6 shadow-sm">
      <h2 class="mb-4 font-semibold text-slate-900">New {kind_label(@kind)} request</h2>

      <%= if @kind == "stock_take" do %>
        <form phx-change="validate" phx-submit="create_stock_take">
          <div class="grid gap-4 md:grid-cols-3">
            <div>
              <label class="mb-1 block text-sm font-medium text-slate-700">Department</label>
              <select
                name="department_id"
                class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
              >
                <option value="" selected={is_nil(@default_department_id)}>
                  Select department
                </option>
                <option
                  :for={{name, id} <- @departments}
                  value={id}
                  selected={id == @default_department_id}
                >
                  {name}
                </option>
              </select>
            </div>
            <div>
              <label class="mb-1 block text-sm font-medium text-slate-700">Date</label>
              <input
                type="date"
                name="date"
                value={Date.to_iso8601(Date.utc_today())}
                class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
              />
            </div>
            <div>
              <label class="mb-1 block text-sm font-medium text-slate-700">Notes (optional)</label>
              <input
                type="text"
                name="notes"
                placeholder="e.g. Monthly count"
                class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
              />
            </div>
          </div>
          {new_form_actions(assigns)}
        </form>
      <% else %>
        <form phx-change="validate" phx-submit="create_disposal">
          <div class="grid gap-4 md:grid-cols-2">
            <div>
              <label class="mb-1 block text-sm font-medium text-slate-700">Date</label>
              <input
                type="date"
                name="date"
                value={Date.to_iso8601(Date.utc_today())}
                class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
              />
            </div>
            <div class="md:col-span-2">
              <label class="mb-1 block text-sm font-medium text-slate-700">
                {if @kind == "donation", do: "Recipient / reason", else: "Expiry notes"}
              </label>
              <textarea
                name="reason"
                rows="2"
                class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
              ></textarea>
            </div>
            <p :if={@kind == "donation"} class="text-xs text-slate-500 md:col-span-2">
              You'll attach the donation request PDF once you've added the items.
            </p>
          </div>
          {new_form_actions(assigns)}
        </form>
      <% end %>
    </div>
    """
  end

  defp new_form_actions(assigns) do
    ~H"""
    <div class="mt-5 flex justify-end gap-3">
      <button type="button" phx-click="cancel_new" class="rounded-lg border px-4 py-2 text-sm">
        Cancel
      </button>
      <button class="rounded-lg bg-[#373896] px-4 py-2 text-sm font-semibold text-white">
        Create and add items
      </button>
    </div>
    """
  end

  # ── Disposal builder ─────────────────────────────────────────────────────────

  defp disposal_builder(assigns) do
    assigns = assign(assigns, :editable, assigns.disposal.status == "draft")

    ~H"""
    <div class="space-y-6 print:hidden">
      <button
        phx-click="back_to_list"
        class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-800"
      >
        <Heroicons.icon name="arrow-left" type="outline" class="h-4 w-4" /> Back to requests
      </button>

      <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <div class="flex flex-wrap items-center justify-between gap-3">
          <div class="flex flex-wrap items-center gap-3">
            <h1 class="text-xl font-semibold text-slate-900">
              {kind_label(@disposal.kind)} request #{@disposal.id}
            </h1>
            {status_badge(assigns, @disposal.status)}
          </div>
          <button
            :if={@disposal.kind == "donation" and @disposal.items != []}
            type="button"
            phx-click={show_modal("print-modal")}
            class="inline-flex items-center gap-2 rounded-lg border border-slate-200 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
          >
            <Heroicons.icon name="printer" type="outline" class="h-4 w-4" /> Print
          </button>
        </div>
        <p class="mt-1 text-sm text-slate-500">Raised on {format_date(@disposal.date)}</p>
        <%= if @disposal.reason not in [nil, ""] do %>
          <p class="mt-2 text-sm text-slate-700">{@disposal.reason}</p>
        <% end %>
        <%= if @disposal.status != "draft" do %>
          <p class="mt-3 text-sm text-slate-500">
            {status_explanation(@disposal.status)}
          </p>
        <% end %>
      </div>

      <%= if @editable do %>
        {add_stock_panel(assigns, "add_source", true)}
      <% end %>

      <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
        <div class="border-b border-slate-200 px-5 py-4">
          <h2 class="font-semibold text-slate-900">Items</h2>
        </div>
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="bg-slate-50 text-left text-xs uppercase text-slate-500">
              <tr>
                <th class="px-5 py-3">Item</th>
                <th class="px-5 py-3">Available when added</th>
                <th class="px-5 py-3">Quantity</th>
                <th class="px-5 py-3">Notes</th>
                <th class="px-5 py-3">Applied</th>
                <th class="px-5 py-3"></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
              <%= for item <- @disposal.items do %>
                <tr>
                  <td class="px-5 py-4 font-medium text-slate-800">{item.entity_name}</td>
                  <td class="whitespace-nowrap px-5 py-4">{item.available_quantity} {item.uom}</td>
                  <td class="whitespace-nowrap px-5 py-4 font-semibold">
                    {item.quantity} {item.uom}
                  </td>
                  <td class="px-5 py-4 text-slate-600">{item.notes || "—"}</td>
                  <td class="px-5 py-4">
                    <%= if item.has_been_applied do %>
                      <span class="font-semibold text-emerald-700">Yes</span>
                    <% else %>
                      <span class="text-slate-400">No</span>
                    <% end %>
                  </td>
                  <td class="px-5 py-4 text-right">
                    <%= if @editable do %>
                      <button
                        phx-click="delete_item"
                        phx-value-id={item.id}
                        data-confirm="Remove this item?"
                        class="font-semibold text-red-600 hover:underline"
                      >
                        Remove
                      </button>
                    <% end %>
                  </td>
                </tr>
              <% end %>
              <%= if @disposal.items == [] do %>
                <tr>
                  <td colspan="6" class="px-5 py-12 text-center text-slate-500">
                    No items added yet.
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>

      <%= if @disposal.kind == "donation" do %>
        <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 class="font-semibold text-slate-900">Donation request PDF (optional)</h2>
          <p class="mt-1 text-sm text-slate-500">
            Attach supporting paperwork if you have it - not required to submit.
          </p>

          <%= if @disposal.supporting_document_path do %>
            <div class="mt-4 flex flex-wrap items-center gap-3 rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3">
              <Heroicons.icon name="document-check" type="outline" class="h-5 w-5 text-emerald-700" />
              <a
                href={@disposal.supporting_document_path}
                target="_blank"
                class="text-sm font-medium text-emerald-800 underline"
              >
                {@disposal.supporting_document_name || "View attached document"}
              </a>
              <button
                :if={@editable}
                type="button"
                phx-click="remove_supporting_document"
                data-confirm="Remove this document?"
                class="ml-auto text-sm font-semibold text-red-600 hover:underline"
              >
                Remove
              </button>
            </div>
          <% else %>
            <div class="mt-4 flex items-center gap-2 rounded-lg border border-slate-200 bg-slate-50 px-4 py-3">
              <Heroicons.icon name="document" type="outline" class="h-5 w-5 text-slate-400" />
              <p class="text-sm text-slate-500">No document attached.</p>
            </div>
          <% end %>

          <%= if @editable do %>
            <form id="supporting-document-form" phx-change="validate" class="mt-4">
              <.live_file_input
                upload={@uploads.supporting_document}
                class="block w-full rounded-lg border border-slate-300 p-2 text-sm"
              />
              <p class="mt-1 text-xs text-slate-500">
                PDF only, up to 20 MB. Uploads automatically once selected.
              </p>
              <%= for entry <- @uploads.supporting_document.entries do %>
                <p class="mt-2 text-sm text-slate-700">
                  {entry.client_name}
                  <%= if not entry.done? do %>
                    ({entry.progress}%)
                  <% end %>
                </p>
                <%= for err <- upload_errors(@uploads.supporting_document, entry) do %>
                  <p class="text-sm text-red-600">{upload_error(err)}</p>
                <% end %>
              <% end %>
            </form>
          <% end %>
        </div>
      <% end %>

      <%= if @editable or deletable?(@disposal.status) do %>
        <div class="flex justify-end gap-3 rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
          <button
            :if={deletable?(@disposal.status)}
            phx-click="delete_disposal"
            phx-value-id={@disposal.id}
            data-confirm="Delete this request? This cannot be undone."
            class="rounded-lg border border-red-200 px-4 py-2 text-sm font-semibold text-red-600 hover:bg-red-50"
          >
            Delete request
          </button>
          <button
            :if={@editable}
            phx-click="submit_disposal"
            data-confirm="Submit this request for admin approval? You will no longer be able to edit it."
            class="rounded-lg bg-[#373896] px-4 py-2 text-sm font-semibold text-white"
          >
            Submit for approval
          </button>
        </div>
      <% end %>
    </div>

    <.modal :if={@disposal.kind == "donation" and @disposal.items != []} id="print-modal">
      <div class="mb-4 flex justify-end print:hidden">
        <button
          type="button"
          onclick="window.print()"
          class="inline-flex items-center gap-2 rounded-lg bg-[#373896] px-4 py-2 text-sm font-semibold text-white hover:bg-[#2d2d7a]"
        >
          <Heroicons.icon name="printer" type="outline" class="h-4 w-4" /> Print
        </button>
      </div>
      {MedcampWeb.StockRequests.Print.voucher(assigns)}
    </.modal>
    """
  end

  # ── Stock take builder ───────────────────────────────────────────────────────

  defp stock_take_builder(assigns) do
    assigns = assign(assigns, :editable, assigns.stock_take.status == "draft")

    ~H"""
    <div class="space-y-6">
      <button
        phx-click="back_to_list"
        class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-800"
      >
        <Heroicons.icon name="arrow-left" type="outline" class="h-4 w-4" /> Back to requests
      </button>

      <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <div class="flex flex-wrap items-center gap-3">
          <h1 class="text-xl font-semibold text-slate-900">Stock take #{@stock_take.id}</h1>
          {status_badge(assigns, @stock_take.status)}
        </div>
        <p class="mt-1 text-sm text-slate-500">Raised on {format_date(@stock_take.date)}</p>
        <%= if @stock_take.notes not in [nil, ""] do %>
          <p class="mt-2 text-sm text-slate-700">{@stock_take.notes}</p>
        <% end %>
        <%= if @stock_take.status != "draft" do %>
          <p class="mt-3 text-sm text-slate-500">{status_explanation(@stock_take.status)}</p>
        <% end %>

        <%= if @editable or deletable?(@stock_take.status) do %>
          <div class="mt-5 flex justify-end gap-3 border-t border-slate-100 pt-4">
            <button
              :if={deletable?(@stock_take.status)}
              phx-click="delete_stock_take"
              phx-value-id={@stock_take.id}
              data-confirm="Delete this stock take? This cannot be undone."
              class="rounded-lg border border-red-200 px-4 py-2 text-sm font-semibold text-red-600 hover:bg-red-50"
            >
              Delete stock take
            </button>
            <button
              :if={@editable}
              phx-click="submit_stock_take"
              data-confirm="Submit this stock take for admin approval?"
              class="rounded-lg bg-[#373896] px-4 py-2 text-sm font-semibold text-white"
            >
              Submit for approval
            </button>
          </div>
        <% end %>
      </div>

      <%= if @editable do %>
        {add_stock_panel(assigns, "add_entry", false)}
      <% end %>

      <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
        <div class="border-b border-slate-200 px-5 py-4">
          <h2 class="font-semibold text-slate-900">Counted items</h2>
        </div>
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="bg-slate-50 text-left text-xs uppercase text-slate-500">
              <tr>
                <th class="px-5 py-3">Item</th>
                <th class="px-5 py-3 text-right">System qty</th>
                <th class="px-5 py-3 text-right">Counted qty</th>
                <th class="px-5 py-3 text-right">Difference</th>
                <th class="px-5 py-3"></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
              <%= for entry <- @stock_take.entries do %>
                <tr>
                  <td class="px-5 py-4 font-medium text-slate-800">
                    {entry.entity_name}
                    <span class="ml-1 text-xs text-slate-400">{entry.uom}</span>
                  </td>
                  <td class="px-5 py-4 text-right font-mono">{entry.previous_quantity}</td>
                  <td class="px-5 py-4 text-right">
                    <%= if @editing_entry_id == entry.id and @editable do %>
                      <form
                        id={"save_count_#{entry.id}"}
                        phx-submit="save_count"
                        class="flex items-center justify-end gap-2"
                      >
                        <input type="hidden" name="entry_id" value={entry.id} />
                        <input type="hidden" name="notes" value={entry.notes || ""} />
                        <input type="hidden" name="uom" value={entry.uom || ""} />
                        <input
                          type="number"
                          name="counted_quantity"
                          value={entry.counted_quantity}
                          min="0"
                          autofocus
                          class="w-24 rounded-md border border-indigo-400 px-2 py-1 text-right text-sm font-mono"
                        />
                        <button
                          type="submit"
                          class="rounded bg-[#373896] px-2 py-1 text-xs font-semibold text-white"
                        >
                          Save
                        </button>
                        <button
                          type="button"
                          phx-click="cancel_edit"
                          class="rounded border px-2 py-1 text-xs text-slate-600"
                        >
                          ✕
                        </button>
                      </form>
                    <% else %>
                      <span class={[
                        "font-mono text-sm",
                        is_nil(entry.counted_quantity) && "text-slate-400",
                        entry.counted_quantity && "font-semibold text-blue-700"
                      ]}>
                        {entry.counted_quantity || "—"}
                      </span>
                    <% end %>
                  </td>
                  <td class="px-5 py-4 text-right">
                    <%= if entry.difference != nil do %>
                      <span class={[
                        "inline-flex rounded-full px-2.5 py-0.5 text-sm font-bold",
                        entry.difference > 0 && "bg-emerald-50 text-emerald-700",
                        entry.difference < 0 && "bg-red-50 text-red-700",
                        entry.difference == 0 && "bg-slate-100 text-slate-600"
                      ]}>
                        {if entry.difference > 0, do: "+", else: ""}{entry.difference}
                      </span>
                    <% else %>
                      <span class="text-slate-400">—</span>
                    <% end %>
                  </td>
                  <td class="px-5 py-4 text-right">
                    <%= if @editable and @editing_entry_id != entry.id do %>
                      <div class="flex items-center justify-end gap-1">
                        <button
                          phx-click="edit_entry"
                          phx-value-id={entry.id}
                          class="rounded-md p-1.5 text-slate-400 hover:bg-blue-50 hover:text-blue-600"
                          title="Enter count"
                        >
                          <Heroicons.icon name="pencil-square" type="outline" class="h-4 w-4" />
                        </button>
                        <button
                          phx-click="delete_entry"
                          phx-value-id={entry.id}
                          data-confirm="Remove this item?"
                          class="rounded-md p-1.5 text-slate-400 hover:bg-red-50 hover:text-red-600"
                          title="Remove"
                        >
                          <Heroicons.icon name="trash" type="outline" class="h-4 w-4" />
                        </button>
                      </div>
                    <% end %>
                  </td>
                </tr>
              <% end %>
              <%= if @stock_take.entries == [] do %>
                <tr>
                  <td colspan="5" class="px-5 py-12 text-center text-slate-500">
                    No items added yet.
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  # Shared search + add panel for both flows. `disposal_flow` toggles the
  # per-row quantity/notes form (disposals) versus a simple Add button (stock
  # takes).
  defp add_stock_panel(assigns, add_event, disposal_flow) do
    assigns = assign(assigns, add_event: add_event, disposal_flow: disposal_flow)

    ~H"""
    <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
      <h2 class="font-semibold text-slate-900">Add {@bucket_label}s</h2>
      <p class="mt-1 text-sm text-slate-500">
        Search your {@bucket_label}s or filter by expiry, then add them.
      </p>

      <form phx-change="search" class="mt-4 flex flex-wrap items-end gap-3">
        <input
          type="search"
          name="q"
          value={@search_query}
          phx-debounce="300"
          placeholder="Search by item, generic name, GTIN, or batch..."
          class="min-w-64 flex-1 rounded-lg border border-slate-300 px-4 py-2.5 text-sm focus:border-[#373896] focus:ring-[#373896]"
        />
        <select
          name="expiry_filter"
          class="rounded-lg border border-slate-300 px-3 py-2.5 text-sm focus:border-[#373896] focus:ring-[#373896]"
        >
          <option
            :for={{value, label} <- Medcamp.ExpiryFilter.options()}
            value={value}
            selected={@expiry_filter == value}
          >
            {label}
          </option>
        </select>
        <div>
          <label class="mb-1 block text-xs font-medium text-slate-500">Expiry from</label>
          <input
            type="date"
            name="expiry_from"
            value={@expiry_from}
            max={@expiry_to != "" && @expiry_to}
            class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-[#373896] focus:ring-[#373896]"
          />
        </div>
        <div>
          <label class="mb-1 block text-xs font-medium text-slate-500">Expiry to</label>
          <input
            type="date"
            name="expiry_to"
            value={@expiry_to}
            min={@expiry_from != "" && @expiry_from}
            class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-[#373896] focus:ring-[#373896]"
          />
        </div>
      </form>

      <p
        :if={(@search_query != "" or expiry_filter_active?(assigns)) and @search_results == []}
        class="mt-3 text-sm text-slate-500"
      >
        No {@bucket_label}s match that search{if expiry_filter_active?(assigns),
          do: " with the selected expiry filter",
          else: ""}.
      </p>

      <%= if @search_results != [] do %>
        <div class="mt-4 overflow-x-auto rounded-lg border border-slate-200">
          <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="bg-slate-50 text-left text-xs uppercase text-slate-500">
              <tr>
                <th class="px-4 py-3">Item</th>
                <th class="px-4 py-3">Batch</th>
                <th class="px-4 py-3">Available</th>
                <th class="px-4 py-3">Expiry</th>
                <th class="px-4 py-3"></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
              <%= for result <- @search_results do %>
                <% attrs = InventoryDisposals.source_attributes(@bucket, result) %>
                <tr>
                  <td class="px-4 py-3 font-medium text-slate-800">{attrs.entity_name}</td>
                  <td class="whitespace-nowrap px-4 py-3 text-slate-700">
                    {InventoryDisposals.source_batch(@bucket, result)}
                  </td>
                  <td class="whitespace-nowrap px-4 py-3">
                    {attrs.available_quantity} {attrs.uom}
                  </td>
                  <% expiry = InventoryDisposals.source_expiry(@bucket, result) %>
                  <td class="whitespace-nowrap px-4 py-3">
                    <span class={["font-medium", expiry_class(expiry)]}>
                      {format_expiry(expiry)}
                    </span>
                    <span :if={expiry_note(expiry)} class={["block text-xs", expiry_class(expiry)]}>
                      {expiry_note(expiry)}
                    </span>
                  </td>
                  <td class="px-4 py-3 text-right">
                    <%= if @disposal_flow do %>
                      <form phx-submit={@add_event} class="flex min-w-[380px] items-center gap-2">
                        <input type="hidden" name="source_id" value={result.id} />
                        <input
                          type="number"
                          name="quantity"
                          min="1"
                          max={attrs.available_quantity}
                          required
                          placeholder="Qty"
                          class="w-24 rounded-lg border border-slate-300 px-3 py-2"
                        />
                        <input
                          type="text"
                          name="notes"
                          placeholder="Optional notes"
                          class="min-w-32 flex-1 rounded-lg border border-slate-300 px-3 py-2"
                        />
                        <button class="rounded-lg bg-[#373896] px-3 py-2 font-semibold text-white">
                          Add
                        </button>
                      </form>
                    <% else %>
                      <button
                        phx-click={@add_event}
                        phx-value-id={result.id}
                        class="rounded-md bg-indigo-50 px-3 py-1.5 text-xs font-semibold text-[#373896] hover:bg-indigo-100"
                      >
                        Add
                      </button>
                    <% end %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>
    </div>
    """
  end

  # ── Small helpers ────────────────────────────────────────────────────────────

  defp kind_label("donation"), do: "Donation"
  defp kind_label("expiry"), do: "Expiry"
  defp kind_label("stock_take"), do: "Stock take"

  # Mirrors the context guards: anything an admin has not approved yet can still
  # be thrown away by its requester.
  defp deletable?(status), do: status in ["draft", "pending", "rejected"]

  defp status_explanation("pending"), do: "Submitted — awaiting admin approval."
  defp status_explanation("approved"), do: "Approved. Stock has been adjusted."
  defp status_explanation("completed"), do: "Approved. Stock has been adjusted."
  defp status_explanation("rejected"), do: "Rejected by the admin. No stock was changed."
  defp status_explanation(_), do: ""

  defp format_date(nil), do: "—"
  defp format_date(date), do: Calendar.strftime(date, "%d %b %Y")

  # Expiry is colour-coded so an expired or soon-to-expire batch is obvious at
  # the point of picking it. Unparseable values are shown verbatim, uncoloured.
  defp format_expiry(nil), do: "—"
  defp format_expiry(%Date{} = date), do: Calendar.strftime(date, "%d %b %Y")
  defp format_expiry(raw) when is_binary(raw), do: raw

  defp expiry_class(%Date{} = date) do
    case Date.diff(date, Date.utc_today()) do
      days when days < 0 -> "text-red-600"
      days when days <= 30 -> "text-amber-600"
      _ -> "text-slate-700"
    end
  end

  defp expiry_class(_), do: "text-slate-500"

  defp expiry_note(%Date{} = date) do
    case Date.diff(date, Date.utc_today()) do
      days when days < 0 -> "Expired #{abs(days)}d ago"
      0 -> "Expires today"
      days when days <= 30 -> "Expires in #{days}d"
      _ -> nil
    end
  end

  defp expiry_note(_), do: nil

  defp upload_error(:too_large), do: "File is too large."
  defp upload_error(:not_accepted), do: "Only PDF files are accepted."
  defp upload_error(error), do: inspect(error)

  defp status_badge(assigns, status) do
    assigns = assign(assigns, :status, status)

    ~H"""
    <span class={[
      "inline-flex rounded-full px-2.5 py-1 text-xs font-semibold capitalize",
      @status in ["draft"] && "bg-slate-100 text-slate-700",
      @status == "pending" && "bg-amber-100 text-amber-800",
      @status in ["approved", "completed"] && "bg-emerald-100 text-emerald-800",
      @status == "rejected" && "bg-red-100 text-red-800"
    ]}>
      {if @status == "completed", do: "approved", else: @status}
    </span>
    """
  end

  defp get_department_id_for_bucket(bucket) do
    code =
      case bucket do
        "drug_batch" -> "PHARM"
        "lab_allocation" -> "LAB"
        "nursing_allocation" -> "NURSE"
        "inventory_received" -> "STORES"
        _ -> nil
      end

    if code do
      case Medcamp.Repo.get_by(Medcamp.Departments.Department, code: code) do
        %Medcamp.Departments.Department{id: id} -> id
        _ -> nil
      end
    end
  end
end
