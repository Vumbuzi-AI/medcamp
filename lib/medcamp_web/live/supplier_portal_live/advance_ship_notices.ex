defmodule MedcampWeb.SupplierPortalLive.AdvanceShipNotices do
  @moduledoc """
  Supplier portal: submit and manage Advance Ship Notices (ASNs).
  """
  use MedcampWeb, :supplier_live_view

  alias Medcamp.Suppliers
  alias Medcamp.Suppliers.SupplierAdvanceShipNotice

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    if is_nil(user.supplier_id) do
      {:ok,
       socket
       |> put_flash(:error, "Your account is not linked to a supplier.")
       |> push_navigate(to: ~p"/users/log_out")}
    else
      supplier = Suppliers.get_supplier!(user.supplier_id)

      {:ok,
       socket
       |> assign(:page_title, "Advance Ship Notices")
       |> assign(:active_tab, :advance_ship_notices)
       |> assign(:supplier, supplier)
       |> assign(:page, 1)
       |> assign(:per_page, @per_page)
       |> load_asns()
       |> assign(:form, nil)
       |> assign(:editing, nil)
       |> allow_upload(:asn_file,
         accept: ~w(.pdf .jpg .jpeg .png),
         max_entries: 1,
         max_file_size: 10_000_000
       )}
    end
  end

  defp load_asns(socket) do
    all = Suppliers.list_supplier_advance_ship_notices(socket.assigns.supplier.id)
    total_count = length(all)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)
    asns = Enum.slice(all, (page - 1) * socket.assigns.per_page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:asns, asns)
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_asns()}
  end

  def handle_event("validate", %{"supplier_advance_ship_notice" => params}, socket) do
    changeset =
      case socket.assigns.editing do
        nil -> Suppliers.change_supplier_advance_ship_notice(%SupplierAdvanceShipNotice{}, params)
        asn -> Suppliers.change_supplier_advance_ship_notice(asn, params)
      end

    {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"supplier_advance_ship_notice" => params}, socket) do
    supplier_id = socket.assigns.supplier.id

    uploaded =
      consume_uploaded_entries(socket, :asn_file, fn %{path: path}, entry ->
        ext = Path.extname(entry.client_name)
        filename = "asn_#{supplier_id}_#{System.unique_integer([:positive])}#{ext}"
        dest_dir = Path.join(Application.app_dir(:medcamp, "priv/uploads"), "supplier_asns")
        File.mkdir_p!(dest_dir)
        File.cp!(path, Path.join(dest_dir, filename))
        {:ok, %{path: "/uploads/supplier_asns/#{filename}", original: entry.client_name}}
      end)

    file_params =
      case uploaded do
        [%{path: p, original: o} | _] -> %{"file_path" => p, "original_filename" => o}
        _ -> %{}
      end

    full_params = Map.merge(params, Map.merge(file_params, %{"supplier_id" => supplier_id}))

    result =
      case socket.assigns.editing do
        nil -> Suppliers.create_supplier_advance_ship_notice(full_params)
        asn -> Suppliers.update_supplier_advance_ship_notice(asn, full_params)
      end

    case result do
      {:ok, _} ->
        action = if socket.assigns.editing, do: "updated", else: "submitted"

        {:noreply,
         socket
         |> put_flash(:info, "Advance ship notice #{action} successfully.")
         |> load_asns()
         |> assign(:form, nil)
         |> assign(:editing, nil)
         |> push_patch(to: ~p"/supplier/advance_ship_notices")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :asn_file, ref)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    Suppliers.delete_supplier_advance_ship_notice(Suppliers.get_supplier_advance_ship_notice!(id))

    {:noreply,
     socket
     |> put_flash(:info, "Advance ship notice deleted.")
     |> load_asns()}
  end

  def handle_event("close-form", _params, socket) do
    {:noreply,
     socket
     |> assign(:form, nil)
     |> assign(:editing, nil)
     |> push_patch(to: ~p"/supplier/advance_ship_notices")}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(
      :form,
      to_form(Suppliers.change_supplier_advance_ship_notice(%SupplierAdvanceShipNotice{}))
    )
    |> assign(:editing, nil)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    asn = Suppliers.get_supplier_advance_ship_notice!(id)

    socket
    |> assign(:form, to_form(Suppliers.change_supplier_advance_ship_notice(asn)))
    |> assign(:editing, asn)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:form, nil)
    |> assign(:editing, nil)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header class="text-[#373896] border-b border-gray-100 pb-4">
        <div class="flex items-center gap-2">
          <Heroicons.icon name="paper-airplane" type="outline" class="h-6 w-6 text-[#6667ab]" />
          Advance Ship Notices
        </div>
        <:subtitle>
          Notify the facility in advance of upcoming shipments so they can prepare for receipt.
        </:subtitle>
        <:actions>
          <.link patch={~p"/supplier/advance_ship_notices/new"}>
            <.button class="bg-[#373896] hover:bg-[#6667ab]">
              <Heroicons.icon name="plus" type="outline" class="h-4 w-4 mr-1" /> New ASN
            </.button>
          </.link>
        </:actions>
      </.header>

      <%= if @form do %>
        <.modal id="asn-modal" show on_cancel={JS.push("close-form")}>
          <h2 class="text-lg font-semibold text-[#373896] mb-6">
            {if @editing, do: "Edit ASN", else: "Submit Advance Ship Notice"}
          </h2>
          <.simple_form for={@form} phx-submit="save" phx-change="validate">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <.input field={@form[:asn_number]} label="ASN Number" placeholder="ASN-001" />
              <.input field={@form[:ship_date]} label="Ship Date" type="date" />
              <.input
                field={@form[:expected_delivery_date]}
                label="Expected Delivery Date"
                type="date"
              />
              <.input
                field={@form[:status]}
                label="Status"
                type="select"
                options={
                  Enum.map(
                    SupplierAdvanceShipNotice.statuses(),
                    &{SupplierAdvanceShipNotice.status_label(&1), &1}
                  )
                }
              />
            </div>
            <.input
              field={@form[:notes]}
              label="Notes"
              type="textarea"
              rows="3"
              placeholder="Shipment contents, carrier details, tracking number, etc."
            />
            <div>
              <label class="block text-sm font-medium text-zinc-700 mb-1">
                Attach ASN Document (PDF / image, max 10 MB)
              </label>
              <.live_file_input
                upload={@uploads.asn_file}
                class="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-medium file:bg-[#e7e7ff] file:text-[#373896] hover:file:bg-[#d2d3ff]"
              />
              <%= for entry <- @uploads.asn_file.entries do %>
                <div class="flex items-center gap-2 mt-2 p-2 bg-slate-50 rounded-lg">
                  <span class="text-sm flex-1 truncate">{entry.client_name}</span>
                  <button
                    type="button"
                    phx-click="cancel-upload"
                    phx-value-ref={entry.ref}
                    class="text-rose-500"
                  >
                    <Heroicons.icon name="x-mark" type="outline" class="h-4 w-4" />
                  </button>
                </div>
              <% end %>
            </div>
            <:actions>
              <.button type="submit" class="bg-[#373896] hover:bg-[#6667ab]">
                {if @editing, do: "Update ASN", else: "Submit ASN"}
              </.button>
              <button
                type="button"
                phx-click="close-form"
                class="px-4 py-2 text-sm text-gray-600 hover:text-gray-800"
              >
                Cancel
              </button>
            </:actions>
          </.simple_form>
        </.modal>
      <% end %>

      <div class="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
          <h3 class="text-base font-semibold text-[#373896]">All Advance Ship Notices</h3>
          <span class="text-sm text-gray-500">{@total_count} notice(s)</span>
        </div>

        <%= if Enum.empty?(@asns) do %>
          <div class="flex flex-col items-center justify-center py-16 text-center">
            <Heroicons.icon name="paper-airplane" type="outline" class="h-12 w-12 text-gray-300 mb-3" />
            <p class="text-gray-500 font-medium">No advance ship notices submitted yet</p>
            <p class="text-gray-400 text-sm mt-1">
              Click "New ASN" to notify the facility of an upcoming shipment.
            </p>
          </div>
        <% else %>
          <div class="overflow-x-auto">
            <table class="w-full min-w-[900px]">
              <thead class="border-b border-slate-200 bg-slate-50/80">
                <tr>
                  <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                    ASN #
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Ship Date
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Expected Delivery
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Status
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Notes
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                    File
                  </th>
                  <th class="px-6 py-4 text-right text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 bg-white">
                <tr :for={asn <- @asns} class="group transition-colors hover:bg-slate-50/50">
                  <td class="px-6 py-3 text-sm font-medium text-gray-900">{asn.asn_number}</td>
                  <td class="px-6 py-3 text-sm text-gray-600">{asn.ship_date || "—"}</td>
                  <td class="px-6 py-3 text-sm text-gray-600">{asn.expected_delivery_date || "—"}</td>
                  <td class="px-6 py-3 text-sm">
                    <span class={"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{SupplierAdvanceShipNotice.status_color(asn.status)}"}>
                      {SupplierAdvanceShipNotice.status_label(asn.status)}
                    </span>
                  </td>
                  <td class="px-6 py-3 text-sm text-gray-600 max-w-[160px] truncate">
                    {asn.notes || "—"}
                  </td>
                  <td class="px-6 py-3 text-sm">
                    <%= if asn.file_path do %>
                      <a
                        href={asn.file_path}
                        target="_blank"
                        class="text-[#6667ab] hover:text-[#373896] flex items-center gap-1"
                      >
                        <Heroicons.icon name="paper-clip" type="outline" class="h-4 w-4" />
                        <span class="truncate max-w-[100px]">{asn.original_filename || "File"}</span>
                      </a>
                    <% else %>
                      <span class="text-gray-400">—</span>
                    <% end %>
                  </td>
                  <td class="px-6 py-3 text-sm text-right">
                    <div class="flex items-center justify-end gap-3">
                      <.link
                        patch={~p"/supplier/advance_ship_notices/#{asn.id}/edit"}
                        class="text-[#6667ab] hover:text-[#373896] font-medium"
                      >
                        Edit
                      </.link>
                      <button
                        phx-click="delete"
                        phx-value-id={asn.id}
                        data-confirm="Delete this ASN?"
                        class="text-rose-500 hover:text-rose-700 font-medium"
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
            <.pagination
              page={@page}
              total_pages={@total_pages}
              total_count={@total_count}
              per_page={@per_page}
              class="px-6 pb-4"
            />
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
