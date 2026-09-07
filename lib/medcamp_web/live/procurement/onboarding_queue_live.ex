defmodule MedcampWeb.Procurement.OnboardingQueueLive do
  use MedcampWeb, :procurement_live_view

  import MedcampWeb.ProcurementComponents, only: [status_badge: 1]

  alias Medcamp.Procurement.Suppliers
  alias Medcamp.Suppliers.SupplierDocument
  alias MedcampWeb.Procurement.LiveHelpers

  @refresh_events ~w(
    registration_submitted supplier_approved supplier_rejected supplier_info_requested
    supplier_document_verified
  )a

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Onboarding Queue")
     |> assign(:review_note, "")
     |> assign_queue(nil)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    selected_id =
      case socket.assigns.live_action do
        :review -> params["id"]
        _ -> nil
      end

    current_selected_id =
      socket.assigns.selected_supplier &&
        socket.assigns.selected_supplier.id &&
        to_string(socket.assigns.selected_supplier.id)

    socket =
      if selected_id != current_selected_id do
        assign(socket, :review_note, "")
      else
        socket
      end

    {:noreply, assign_queue(socket, selected_id)}
  end

  @impl true
  def handle_event("note", %{"review_note" => note}, socket) do
    {:noreply, assign(socket, :review_note, note)}
  end

  def handle_event("approve", %{"id" => id}, socket) do
    with supplier when not is_nil(supplier) <- Suppliers.get_supplier(id),
         {:ok, _supplier} <- Suppliers.approve(supplier, socket.assigns.current_user) do
      {:noreply,
       socket
       |> put_flash(:info, "Supplier registration approved.")
       |> assign(:review_note, "")
       |> assign_queue(nil)
       |> push_patch(to: ~p"/procurement/onboarding")}
    else
      _ -> {:noreply, put_flash(socket, :error, "Unable to approve that registration.")}
    end
  end

  def handle_event("approve_document", %{"id" => id}, socket) do
    selected_id = socket.assigns.selected_supplier && socket.assigns.selected_supplier.id

    with document when not is_nil(document) <- Suppliers.get_document(id),
         {:ok, _document} <- Suppliers.verify_document(document, socket.assigns.current_user) do
      {:noreply,
       socket
       |> put_flash(:info, "Supplier document approved.")
       |> assign_queue(selected_id)}
    else
      _ -> {:noreply, put_flash(socket, :error, "Unable to approve that document right now.")}
    end
  end

  def handle_event("reject", %{"id" => id}, socket) do
    reason = String.trim(socket.assigns.review_note || "")

    cond do
      reason == "" ->
        {:noreply,
         put_flash(socket, :error, "Add a rejection reason before rejecting this registration.")}

      supplier = Suppliers.get_supplier(id) ->
        case Suppliers.reject(supplier, socket.assigns.current_user, reason) do
          {:ok, _supplier} ->
            {:noreply,
             socket
             |> put_flash(:info, "Supplier registration rejected.")
             |> assign(:review_note, "")
             |> assign_queue(nil)
             |> push_patch(to: ~p"/procurement/onboarding")}

          _ ->
            {:noreply, put_flash(socket, :error, "Unable to reject that registration.")}
        end

      true ->
        {:noreply, put_flash(socket, :error, "Supplier registration not found.")}
    end
  end

  def handle_event("request_info", %{"id" => id}, socket) do
    note = String.trim(socket.assigns.review_note || "")

    cond do
      note == "" ->
        {:noreply, put_flash(socket, :error, "Add a note before requesting more information.")}

      supplier = Suppliers.get_supplier(id) ->
        case Suppliers.request_more_info(supplier, socket.assigns.current_user, note) do
          {:ok, _supplier} ->
            {:noreply,
             socket
             |> put_flash(:info, "More information request sent to the supplier.")
             |> assign(:review_note, "")
             |> assign_queue(id)}

          _ ->
            {:noreply, put_flash(socket, :error, "Unable to request more information right now.")}
        end

      true ->
        {:noreply, put_flash(socket, :error, "Supplier registration not found.")}
    end
  end

  @impl true
  def handle_info({event, _payload}, socket) when event in @refresh_events do
    selected_id = socket.assigns.selected_supplier && socket.assigns.selected_supplier.id
    {:noreply, assign_queue(socket, selected_id)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp assign_queue(socket, selected_id) do
    queue = Suppliers.list_pending_registrations() |> Enum.map(&Suppliers.get_supplier!(&1.id))

    selected_supplier =
      cond do
        LiveHelpers.blank?(selected_id) -> nil
        true -> Suppliers.get_supplier(selected_id)
      end

    socket
    |> assign(:queue, queue)
    |> assign(:selected_supplier, selected_supplier)
    |> assign(
      :page_title,
      if(selected_supplier, do: "Onboarding Review", else: "Onboarding Queue")
    )
  end

  defp document_status(supplier) do
    "#{length(supplier.supplier_documents)}/4"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="space-y-2">
        <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">Onboarding</p>
        <h1 class="text-3xl font-semibold tracking-tight text-slate-900">
          Supplier onboarding queue
        </h1>
        <p class="max-w-3xl text-sm leading-6 text-slate-500">
          Review supplier applications, inspect submitted documents, and respond inline without leaving the queue.
        </p>
      </div>

      <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
        <div class="flex items-center justify-between gap-3">
          <div>
            <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
              Applications
            </p>
            <h2 class="mt-2 text-xl font-semibold text-slate-900">Pending registrations</h2>
          </div>
          <span class="rounded-full bg-slate-100 px-3 py-2 text-sm font-semibold text-slate-700">
            {length(@queue)} pending
          </span>
        </div>

        <div
          :if={Enum.empty?(@queue)}
          class="mt-5 rounded-2xl border border-dashed border-slate-200 px-4 py-8 text-sm text-slate-500"
        >
          No supplier registrations are waiting in the onboarding queue.
        </div>

        <div :if={!Enum.empty?(@queue)} class="mt-5 space-y-3">
          <.link
            :for={supplier <- @queue}
            patch={~p"/procurement/onboarding/#{supplier.id}"}
            class={[
              "block rounded-2xl border px-4 py-4 transition",
              if(@selected_supplier && @selected_supplier.id == supplier.id,
                do: "border-[#373896] bg-[#f0f0ff]",
                else: "border-slate-100 bg-slate-50 hover:border-[#d2d3ff]"
              )
            ]}
          >
            <div class="flex items-start justify-between gap-3">
              <div>
                <p class="text-sm font-semibold text-slate-900">
                  {supplier.legal_name || supplier.name || "Supplier"}
                </p>
                <p class="mt-1 text-sm text-slate-500">
                  {supplier.contact_email || supplier.email}
                </p>
              </div>
              <.status_badge status={supplier.status} />
            </div>

            <div class="mt-4 grid gap-3 md:grid-cols-3">
              <div class="rounded-xl bg-white px-3 py-2">
                <p class="text-[11px] font-semibold uppercase tracking-[0.2em] text-slate-400">
                  Documents
                </p>
                <p class="mt-1 text-sm font-medium text-slate-700">{document_status(supplier)}</p>
              </div>
              <div class="rounded-xl bg-white px-3 py-2">
                <p class="text-[11px] font-semibold uppercase tracking-[0.2em] text-slate-400">
                  Reference
                </p>
                <p class="mt-1 text-sm font-medium text-slate-700">
                  {supplier.reference || "Pending"}
                </p>
              </div>
              <div class="rounded-xl bg-white px-3 py-2">
                <p class="text-[11px] font-semibold uppercase tracking-[0.2em] text-slate-400">
                  Score
                </p>
                <p class="mt-1 text-sm font-medium text-slate-700">
                  {supplier.compliance_score || 0}%
                </p>
              </div>
            </div>
          </.link>
        </div>
      </div>

      <.modal
        :if={@selected_supplier}
        id="supplier-onboarding-review"
        show={!!@selected_supplier}
        on_cancel={JS.patch(~p"/procurement/onboarding")}
      >
        <div class="space-y-5">
          <div class="flex items-start justify-between gap-3">
            <div>
              <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                Review panel
              </p>
              <h2 class="mt-2 text-xl font-semibold text-slate-900">
                {@selected_supplier.legal_name || @selected_supplier.name}
              </h2>
            </div>
            <.status_badge status={@selected_supplier.status} />
          </div>

          <div class="grid gap-4 sm:grid-cols-2">
            <.detail_tile label="Reference" value={@selected_supplier.reference} />
            <.detail_tile label="Country" value={@selected_supplier.country} />
            <.detail_tile label="Business" value={@selected_supplier.nature_of_business} />
            <.detail_tile
              label="Contact"
              value={@selected_supplier.contact_email || @selected_supplier.email}
            />
          </div>

          <div>
            <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
              Documents
            </p>
            <div class="mt-3 space-y-3">
              <div
                :for={document <- @selected_supplier.supplier_documents}
                class="flex flex-col gap-3 rounded-2xl border border-slate-100 bg-slate-50 px-4 py-3 sm:flex-row sm:items-center sm:justify-between"
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
                <div class="flex flex-wrap items-center gap-3">
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
                :if={Enum.empty?(@selected_supplier.supplier_documents)}
                class="rounded-2xl border border-dashed border-slate-200 px-4 py-6 text-sm text-slate-500"
              >
                No supplier documents uploaded yet.
              </div>
            </div>
          </div>

          <div class="space-y-3">
            <label class="block text-sm font-medium text-slate-700">
              Review notes <textarea
                name="review_note"
                rows="5"
                phx-change="note"
                phx-debounce="200"
                class="mt-2 w-full rounded-2xl border border-slate-200 px-4 py-3 text-sm"
              ><%= @review_note %></textarea>
            </label>
          </div>

          <div class="flex flex-wrap gap-3">
            <button
              type="button"
              phx-click="reject"
              phx-value-id={@selected_supplier.id}
              class="rounded-xl bg-rose-600 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-rose-700"
            >
              Reject
            </button>
            <button
              type="button"
              phx-click="request_info"
              phx-value-id={@selected_supplier.id}
              class="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50"
            >
              Request more info
            </button>
            <button
              type="button"
              phx-click="approve"
              phx-value-id={@selected_supplier.id}
              class="rounded-xl bg-[#373896] px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-[#2d2d7a]"
            >
              Approve
            </button>
          </div>
        </div>
      </.modal>
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
