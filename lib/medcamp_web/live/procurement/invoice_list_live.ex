defmodule MedcampWeb.Procurement.InvoiceListLive do
  use MedcampWeb, :procurement_live_view

  import MedcampWeb.ProcurementComponents, only: [status_badge: 1]

  alias Medcamp.Procurement.Invoices
  alias MedcampWeb.Procurement.LiveHelpers

  @refresh_events ~w(invoice_submitted invoice_approved invoice_rejected invoice_grn_confirmed grn_finalised)a
  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Invoices")
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:total_count, 0)
     |> assign(:total_pages, 0)
     |> assign_invoices(1)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, assign_invoices(socket, page)}
  end

  @impl true
  def handle_event("approve", %{"id" => id}, socket) do
    case Invoices.get_invoice(id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Invoice not found.")}

      invoice ->
        case Invoices.approve(invoice, socket.assigns.current_user) do
          {:ok, _invoice} ->
            {:noreply,
             socket
             |> put_flash(:info, "Invoice approved successfully.")
             |> assign_invoices(socket.assigns.page)}

          {:error, :not_grn_confirmed} ->
            {:noreply, put_flash(socket, :error, "Only GRN-confirmed invoices can be approved.")}

          _ ->
            {:noreply, put_flash(socket, :error, "Unable to approve that invoice right now.")}
        end
    end
  end

  @impl true
  def handle_info({event, _payload}, socket) when event in @refresh_events do
    {:noreply, assign_invoices(socket, socket.assigns.page)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp assign_invoices(socket, page) do
    page = normalize_page(page)
    total_count = Invoices.count_invoices(%{})
    total_pages = max(1, div(total_count + @per_page - 1, @per_page))
    page = min(page, total_pages)

    invoices = Invoices.list_invoices_paginated(%{}, page, @per_page)

    socket
    |> assign(:page, page)
    |> assign(:per_page, @per_page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:invoices, invoices)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="space-y-2">
        <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">Invoices</p>
        <h1 class="text-3xl font-semibold tracking-tight text-slate-900">Incoming invoice queue</h1>
        <p class="max-w-3xl text-sm leading-6 text-slate-500">
          Review supplier invoices, watch due dates, and approve only after GRN confirmation.
        </p>
      </div>

      <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
        <div class="overflow-x-auto">
          <table class="min-w-full text-left text-sm">
            <thead class="border-b border-slate-200 text-slate-500">
              <tr>
                <th class="pb-3 pr-4 font-semibold">Reference</th>
                <th class="pb-3 pr-4 font-semibold">Supplier</th>
                <th class="pb-3 pr-4 font-semibold">Due date</th>
                <th class="pb-3 pr-4 font-semibold">Total</th>
                <th class="pb-3 pr-4 font-semibold">Status</th>
                <th class="pb-3 font-semibold text-right">Action</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
              <tr :for={invoice <- @invoices}>
                <td class="py-4 pr-4 font-medium text-slate-900">{invoice.reference}</td>
                <td class="py-4 pr-4 text-slate-500">
                  {invoice.supplier && (invoice.supplier.legal_name || invoice.supplier.name)}
                </td>
                <td class={["py-4 pr-4 font-medium", LiveHelpers.invoice_due_tone(invoice.due_date)]}>
                  {LiveHelpers.format_date(invoice.due_date)}
                </td>
                <td class="py-4 pr-4 text-slate-500">{LiveHelpers.money(invoice.total)}</td>
                <td class="py-4 pr-4"><.status_badge status={invoice.status} /></td>
                <td class="py-4 text-right">
                  <div class="flex justify-end gap-2">
                    <.link
                      navigate={~p"/procurement/invoices/#{invoice.id}"}
                      class="text-sm font-semibold text-[#373896] hover:text-[#2d2d7a]"
                    >
                      Open
                    </.link>
                    <button
                      :if={invoice.status == "grn_confirmed"}
                      type="button"
                      phx-click="approve"
                      phx-value-id={invoice.id}
                      class="rounded-xl bg-[#373896] px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-[#2d2d7a]"
                    >
                      Approve
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <.pagination
          page={@page}
          total_pages={@total_pages}
          total_count={@total_count}
          per_page={@per_page}
        />
      </div>
    </div>
    """
  end

  defp normalize_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {value, _} when value > 0 -> value
      _ -> 1
    end
  end

  defp normalize_page(page) when is_integer(page) and page > 0, do: page
  defp normalize_page(_), do: 1
end
