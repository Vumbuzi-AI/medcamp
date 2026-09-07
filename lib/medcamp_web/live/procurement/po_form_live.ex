defmodule MedcampWeb.Procurement.PoFormLive do
  use MedcampWeb, :procurement_live_view

  import MedcampWeb.ProcurementComponents, only: [portal_form_shell: 1]

  alias Medcamp.Procurement.{PurchaseOrders, Quotes, Rfqs}
  alias MedcampWeb.Procurement.LiveHelpers

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Create Purchase Order")
     |> assign(:rfq, nil)
     |> assign(:quote, nil)
     |> assign(:po_form, default_form())
     |> assign(:po_items, [blank_po_item(1)])
     |> assign(:suppliers, LiveHelpers.search_suppliers(nil, status: "approved"))}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("change", %{"purchase_order" => params}, socket) do
    form = po_form_from_params(params, socket.assigns.po_form)
    items = po_items_from_params(params, socket.assigns.po_items)

    {:noreply,
     socket
     |> assign(:po_form, form)
     |> assign(:po_items, items)}
  end

  def handle_event("add_item", _params, socket) do
    next_position = length(socket.assigns.po_items) + 1

    {:noreply,
     assign(socket, :po_items, socket.assigns.po_items ++ [blank_po_item(next_position)])}
  end

  def handle_event("remove_item", %{"index" => index}, socket) do
    idx = String.to_integer(index)

    items =
      socket.assigns.po_items
      |> Enum.with_index()
      |> Enum.reject(fn {_item, item_index} -> item_index == idx end)
      |> Enum.map(fn {item, item_index} -> Map.put(item, "position", item_index + 1) end)

    {:noreply, assign(socket, :po_items, if(items == [], do: [blank_po_item(1)], else: items))}
  end

  def handle_event("submit", _params, socket) do
    result =
      case socket.assigns.quote do
        nil ->
          with {:ok, po} <-
                 PurchaseOrders.create(build_po_attrs(socket), socket.assigns.current_user),
               {:ok, po} <- PurchaseOrders.submit_for_approval(po) do
            {:ok, po}
          end

        quote ->
          with {:ok, po} <-
                 PurchaseOrders.create_from_quote(
                   quote,
                   build_po_form_attrs(socket.assigns.po_form),
                   socket.assigns.current_user
                 ),
               {:ok, po} <- PurchaseOrders.submit_for_approval(po) do
            {:ok, po}
          end
      end

    case result do
      {:ok, po} ->
        {:noreply,
         socket
         |> put_flash(:info, "Purchase order created and submitted for approval.")
         |> push_navigate(to: ~p"/procurement/purchase-orders/#{po.id}")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Unable to create that purchase order right now.")}
    end
  end

  defp apply_action(socket, :new_from_rfq, %{"rfq_id" => rfq_id}) do
    rfq = Rfqs.get_rfq!(rfq_id)

    case Quotes.list_quotes(rfq_id: rfq.id, status: "accepted") |> List.first() do
      nil ->
        socket
        |> put_flash(:error, "No accepted quote exists for this request for quotation yet.")
        |> push_navigate(to: "/procurement/quotes/#{rfq.id}")

      quote ->
        full_quote = Quotes.get_quote!(quote.id)

        socket
        |> assign(:page_title, "Create Purchase Order")
        |> assign(:rfq, rfq)
        |> assign(:quote, full_quote)
        |> assign(:po_form, prefilled_form_from_quote(full_quote))
        |> assign(:po_items, show_po_items_from_quote(full_quote))
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Create Purchase Order")
    |> assign(:rfq, nil)
    |> assign(:quote, nil)
    |> assign(:po_form, default_form())
    |> assign(:po_items, [blank_po_item(1)])
  end

  defp default_form do
    %{
      "supplier_id" => "",
      "expected_delivery_date" => "",
      "currency" => "KES",
      "payment_terms" => "",
      "delivery_address" => ""
    }
  end

  defp prefilled_form_from_quote(quote) do
    %{
      "supplier_id" => "#{quote.supplier_id}",
      "expected_delivery_date" => "",
      "currency" => "KES",
      "payment_terms" => quote.delivery_terms || "",
      "delivery_address" => ""
    }
  end

  defp po_form_from_params(params, current) do
    current
    |> Map.merge(
      Map.take(
        params,
        ~w(supplier_id expected_delivery_date currency payment_terms delivery_address)
      )
    )
  end

  defp po_items_from_params(params, current) do
    params
    |> Map.get("items", %{})
    |> LiveHelpers.listify_indexed_params()
    |> case do
      [] ->
        current

      items ->
        Enum.with_index(items, 1)
        |> Enum.map(fn {item, position} -> Map.put(item, "position", position) end)
    end
  end

  defp blank_po_item(position) do
    %{
      "position" => position,
      "description" => "",
      "unit" => "",
      "quantity" => "",
      "unit_price" => "",
      "inventory_received_id" => ""
    }
  end

  defp show_po_items_from_quote(quote) do
    Enum.map(quote.items, fn item ->
      %{
        "position" => item.position,
        "inventory_received_id" =>
          item.inventory_received_id || (item.rfq_item && item.rfq_item.inventory_received_id),
        "description" => item.rfq_item && item.rfq_item.description,
        "unit" => item.unit,
        "quantity" => LiveHelpers.decimal_to_string(item.quantity_available),
        "unit_price" => LiveHelpers.decimal_to_string(item.unit_price)
      }
    end)
  end

  defp build_po_form_attrs(form) do
    %{
      expected_delivery_date: blank_to_nil(form["expected_delivery_date"]),
      currency: form["currency"],
      payment_terms: form["payment_terms"],
      delivery_address: form["delivery_address"]
    }
  end

  defp build_po_attrs(socket) do
    build_po_form_attrs(socket.assigns.po_form)
    |> Map.merge(%{
      supplier_id: blank_to_nil(socket.assigns.po_form["supplier_id"]),
      items:
        Enum.map(socket.assigns.po_items, fn item ->
          %{
            position: item["position"],
            inventory_received_id: blank_to_nil(item["inventory_received_id"]),
            description: item["description"],
            unit: item["unit"],
            quantity: blank_to_nil(item["quantity"]),
            unit_price: blank_to_nil(item["unit_price"])
          }
        end)
    })
    |> LiveHelpers.prune_blank_values()
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp cancel_path(%{rfq: %{id: id}}), do: "/procurement/quotes/#{id}"
  defp cancel_path(_assigns), do: "/procurement/dashboard"

  @impl true
  def render(assigns) do
    ~H"""
    <.portal_form_shell
      eyebrow="Purchase Order Form"
      title="Create purchase order"
      subtitle="Use this after quote review. Best practice is request for quotation -> accepted quote -> purchase order."
      cancel_path={cancel_path(assigns)}
      max_width="max-w-7xl"
    >
      <form phx-change="change" phx-submit="submit" class="space-y-6">
        <div class="grid gap-6 xl:grid-cols-[1.1fr_0.9fr]">
          <div class="space-y-6">
            <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
              <div class="mb-5 rounded-2xl border border-sky-200 bg-sky-50 px-4 py-4 text-sm text-sky-800">
                Procurement flow reminder: create the PO after supplier quote review, not at the same time as the request for quotation.
              </div>

              <div
                :if={@quote}
                class="mb-5 rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-4 text-sm text-emerald-800"
              >
                This purchase order is prefilled from accepted quote <span class="font-semibold">{@quote.reference}</span>.
              </div>

              <div
                :if={@rfq}
                class="mb-5 grid gap-3 rounded-2xl bg-slate-50 p-4 text-sm text-slate-600 md:grid-cols-2"
              >
                <div>
                  <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
                    Source request for quotation
                  </p>
                  <p class="mt-2 font-semibold text-slate-900">{@rfq.reference}</p>
                  <p class="mt-1">{@rfq.title}</p>
                </div>

                <div>
                  <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
                    Accepted quote
                  </p>
                  <p class="mt-2 font-semibold text-slate-900">{@quote && @quote.reference}</p>
                  <p class="mt-1">
                    This PO will inherit the accepted supplier pricing from the quote above.
                  </p>
                </div>
              </div>

              <div class="grid gap-4 md:grid-cols-2">
                <label class="block text-sm font-medium text-slate-700">
                  Supplier
                  <select
                    name="purchase_order[supplier_id]"
                    disabled={not is_nil(@quote)}
                    class="mt-2 w-full rounded-xl border border-slate-200 px-4 py-2.5"
                  >
                    <option value="">Select supplier</option>
                    <option
                      :for={supplier <- @suppliers}
                      value={supplier.id}
                      selected={@po_form["supplier_id"] == "#{supplier.id}"}
                    >
                      {supplier.legal_name || supplier.name}
                    </option>
                  </select>
                </label>
                <label class="block text-sm font-medium text-slate-700">
                  Expected delivery date
                  <input
                    type="date"
                    name="purchase_order[expected_delivery_date]"
                    value={@po_form["expected_delivery_date"]}
                    class="mt-2 w-full rounded-xl border border-slate-200 px-4 py-2.5"
                  />
                </label>
                <label class="block text-sm font-medium text-slate-700">
                  Currency
                  <input
                    name="purchase_order[currency]"
                    value={@po_form["currency"]}
                    class="mt-2 w-full rounded-xl border border-slate-200 px-4 py-2.5"
                  />
                </label>
                <label class="block text-sm font-medium text-slate-700">
                  Payment terms
                  <input
                    name="purchase_order[payment_terms]"
                    value={@po_form["payment_terms"]}
                    class="mt-2 w-full rounded-xl border border-slate-200 px-4 py-2.5"
                  />
                </label>
              </div>

              <label class="mt-4 block text-sm font-medium text-slate-700">
                Delivery address <textarea
                  name="purchase_order[delivery_address]"
                  rows="4"
                  class="mt-2 w-full rounded-xl border border-slate-200 px-4 py-2.5"
                >{@po_form["delivery_address"]}</textarea>
              </label>
            </div>

            <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
              <div class="flex items-center justify-between gap-3">
                <div>
                  <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                    Line items
                  </p>
                  <h2 class="mt-2 text-xl font-semibold text-slate-900">Purchase order items</h2>
                </div>
                <button
                  :if={!@quote}
                  type="button"
                  phx-click="add_item"
                  class="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700"
                >
                  Add item
                </button>
              </div>

              <div class="mt-5 space-y-4">
                <div
                  :for={{item, index} <- Enum.with_index(@po_items)}
                  class="rounded-2xl border border-slate-100 bg-slate-50 p-4"
                >
                  <div class="grid gap-4 md:grid-cols-2">
                    <input
                      type="hidden"
                      name={"purchase_order[items][#{index}][inventory_received_id]"}
                      value={item["inventory_received_id"]}
                    />
                    <label class="block text-sm font-medium text-slate-700">
                      Description
                      <input
                        name={"purchase_order[items][#{index}][description]"}
                        value={item["description"]}
                        class="mt-2 w-full rounded-xl border border-slate-200 px-4 py-2.5"
                      />
                    </label>
                    <label class="block text-sm font-medium text-slate-700">
                      Unit
                      <input
                        name={"purchase_order[items][#{index}][unit]"}
                        value={item["unit"]}
                        class="mt-2 w-full rounded-xl border border-slate-200 px-4 py-2.5"
                      />
                    </label>
                    <label class="block text-sm font-medium text-slate-700">
                      Quantity
                      <input
                        name={"purchase_order[items][#{index}][quantity]"}
                        value={item["quantity"]}
                        class="mt-2 w-full rounded-xl border border-slate-200 px-4 py-2.5"
                      />
                    </label>
                    <label class="block text-sm font-medium text-slate-700">
                      Unit price
                      <input
                        name={"purchase_order[items][#{index}][unit_price]"}
                        value={item["unit_price"]}
                        class="mt-2 w-full rounded-xl border border-slate-200 px-4 py-2.5"
                      />
                    </label>
                  </div>
                  <button
                    :if={!@quote}
                    type="button"
                    phx-click="remove_item"
                    phx-value-index={index}
                    class="mt-4 text-sm font-semibold text-rose-600"
                  >
                    Remove item
                  </button>
                </div>
              </div>
            </div>
          </div>

          <button
            type="submit"
            class="w-full rounded-xl bg-[#373896] px-4 py-3 text-sm font-semibold text-white transition hover:bg-[#2d2d7a]"
          >
            Create and submit PO
          </button>
        </div>
      </form>
    </.portal_form_shell>
    """
  end
end
