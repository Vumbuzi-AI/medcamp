defmodule MedcampWeb.Procurement.SupplierDetailLive do
  use MedcampWeb, :procurement_live_view

  import MedcampWeb.ProcurementComponents, only: [status_badge: 1, score_bar: 1]

  alias Medcamp.Procurement.{Invoices, PurchaseOrders, Quotes, Suppliers}
  alias Medcamp.Suppliers.SupplierDocument
  alias MedcampWeb.Procurement.LiveHelpers

  @refresh_events ~w(
    supplier_approved supplier_rejected supplier_info_requested supplier_document_verified
  )a

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Supplier Detail")}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    supplier = Suppliers.get_supplier!(id)
    quotes = Quotes.list_quotes(supplier_id: supplier.id)
    purchase_orders = PurchaseOrders.list_purchase_orders(supplier_id: supplier.id)
    invoices = Invoices.list_invoices(supplier_id: supplier.id)

    {:noreply,
     socket
     |> assign(:page_title, supplier.legal_name || supplier.name)
     |> assign(:supplier, supplier)
     |> assign(:quotes, quotes)
     |> assign(:purchase_orders, purchase_orders)
     |> assign(:invoices, invoices)}
  end

  @impl true
  def handle_event("approve_document", %{"id" => id}, socket) do
    with document when not is_nil(document) <- Suppliers.get_document(id),
         {:ok, _document} <- Suppliers.verify_document(document, socket.assigns.current_user) do
      {:noreply,
       socket
       |> assign(:supplier, Suppliers.get_supplier!(socket.assigns.supplier.id))
       |> put_flash(:info, "Supplier document approved.")}
    else
      _ -> {:noreply, put_flash(socket, :error, "Unable to approve that document right now.")}
    end
  end

  @impl true
  def handle_info({event, _payload}, socket) when event in @refresh_events do
    {:noreply, assign(socket, :supplier, Suppliers.get_supplier!(socket.assigns.supplier.id))}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
        <div class="space-y-2">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Supplier detail
          </p>
          <h1 class="text-3xl font-semibold tracking-tight text-slate-900">
            {@supplier.legal_name || @supplier.name}
          </h1>
          <p class="max-w-3xl text-sm leading-6 text-slate-500">
            Full supplier profile, verified document view, and linked procurement history.
          </p>
        </div>
        <.status_badge status={@supplier.status} />
      </div>

      <div
        :if={@supplier.status == "approved"}
        class="rounded-2xl border border-emerald-200 bg-emerald-50 px-5 py-4 text-sm text-emerald-800"
      >
        <span class="font-semibold">Approved supplier.</span>
        <%= if @supplier.approved_at do %>
          Approved on {LiveHelpers.format_datetime(@supplier.approved_at)}.
        <% end %>
      </div>

      <div class="grid gap-4 md:grid-cols-3">
        <MedcampWeb.ProcurementComponents.stat_card
          label="Quotes"
          value={length(@quotes)}
          sub="Quotes linked to this supplier"
        />
        <MedcampWeb.ProcurementComponents.stat_card
          label="POs"
          value={length(@purchase_orders)}
          sub="Purchase orders linked to this supplier"
        />
        <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
          <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">Compliance</p>
          <div class="mt-4">
            <.score_bar score={@supplier.compliance_score || 0} />
          </div>
        </div>
      </div>

      <div class="grid gap-6 xl:grid-cols-2">
        <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">Company</p>
          <div class="mt-5 grid gap-4 sm:grid-cols-2">
            <.detail_tile label="Reference" value={@supplier.reference} />
            <.detail_tile label="Business type" value={@supplier.nature_of_business} />
            <.detail_tile label="Years in operation" value={@supplier.years_in_operation} />
            <.detail_tile label="Country" value={@supplier.country} />
            <.detail_tile
              label="Categories"
              value={LiveHelpers.maybe_join_list(@supplier.product_categories)}
            />
            <.detail_tile label="KRA PIN" value={@supplier.kra_pin} />
          </div>
        </div>

        <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Contact and bank
          </p>
          <div class="mt-5 grid gap-4 sm:grid-cols-2">
            <.detail_tile
              label="Contact person"
              value={
                Enum.join(
                  Enum.reject(
                    [@supplier.contact_first_name, @supplier.contact_last_name],
                    &LiveHelpers.blank?/1
                  ),
                  " "
                )
              }
            />
            <.detail_tile label="Contact email" value={@supplier.contact_email || @supplier.email} />
            <.detail_tile label="Telephone" value={@supplier.contact_telephone || @supplier.contact} />
            <.detail_tile label="Physical address" value={@supplier.street_address} />
            <.detail_tile label="Bank" value={@supplier.bank_name} />
            <.detail_tile label="Account number" value={@supplier.account_number} />
          </div>
        </div>
      </div>

      <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
        <div class="flex items-center justify-between gap-3">
          <div>
            <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">Documents</p>
            <h2 class="mt-2 text-xl font-semibold text-slate-900">Verified document list</h2>
          </div>
        </div>

        <div class="mt-5 space-y-3">
          <div
            :for={document <- @supplier.supplier_documents}
            class="flex items-center justify-between rounded-2xl border border-slate-100 bg-slate-50 px-4 py-3"
          >
            <div>
              <p class="text-sm font-semibold text-slate-800">
                {SupplierDocument.document_type_label(document.document_type)}
              </p>
              <p class="mt-1 text-xs text-slate-500">
                {document.file_name || document.original_filename || "Uploaded file"}
              </p>
              <p :if={document.verified_by} class="mt-1 text-xs text-emerald-700">
                Approved by {document.verified_by.email}
              </p>
            </div>
            <div class="flex items-center gap-3">
              <.status_badge status={if document.verified, do: :approved, else: :pending} />
              <.link
                href={document.file_path}
                target="_blank"
                rel="noopener noreferrer"
                class="text-sm font-semibold text-[#373896]"
              >
                View
              </.link>
              <button
                :if={!document.verified}
                type="button"
                phx-click="approve_document"
                phx-value-id={document.id}
                class="rounded-xl bg-[#373896] px-3 py-2 text-sm font-semibold text-white transition hover:bg-[#2d2d7a]"
              >
                Approve document
              </button>
            </div>
          </div>

          <div
            :if={Enum.empty?(@supplier.supplier_documents)}
            class="rounded-2xl border border-dashed border-slate-200 px-4 py-8 text-sm text-slate-500"
          >
            No supplier documents are attached to this profile yet.
          </div>
        </div>
      </div>

      <div class="grid gap-6 xl:grid-cols-3">
        <.history_card title="Quotes" records={@quotes} path_prefix="/procurement/quotes" />
        <.history_card
          title="Purchase Orders"
          records={@purchase_orders}
          path_prefix="/procurement/purchase-orders"
        />
        <.history_card title="Invoices" records={@invoices} path_prefix="/procurement/invoices" />
      </div>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :records, :list, default: []
  attr :path_prefix, :string, required: true

  defp history_card(assigns) do
    ~H"""
    <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
      <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">{@title}</p>
      <div class="mt-4 space-y-3">
        <div
          :for={record <- @records}
          class="rounded-2xl border border-slate-100 bg-slate-50 px-4 py-3"
        >
          <div class="flex items-center justify-between gap-3">
            <div>
              <p class="text-sm font-semibold text-slate-800">{record.reference}</p>
              <p class="mt-1 text-xs text-slate-500">
                {LiveHelpers.format_datetime(record.inserted_at)}
              </p>
            </div>
            <.status_badge status={record.status} />
          </div>
        </div>
        <div
          :if={Enum.empty?(@records)}
          class="rounded-2xl border border-dashed border-slate-200 px-4 py-6 text-sm text-slate-500"
        >
          No records yet.
        </div>
      </div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, default: nil

  defp detail_tile(assigns) do
    ~H"""
    <div class="rounded-2xl bg-slate-50 px-4 py-3">
      <p class="text-[11px] font-semibold uppercase tracking-[0.2em] text-slate-400">{@label}</p>
      <p class="mt-2 text-sm font-medium text-slate-800">
        {if LiveHelpers.blank?(@value), do: "Not provided", else: @value}
      </p>
    </div>
    """
  end
end
