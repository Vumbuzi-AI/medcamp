defmodule MedcampWeb.Procurement.GrnFormLive do
  use MedcampWeb, :procurement_live_view

  import MedcampWeb.ProcurementComponents,
    only: [
      condition_toggle: 1,
      grn_summary_strip: 1,
      confirmation_modal: 1,
      pipeline_tracker: 1,
      status_badge: 1,
      portal_form_shell: 1
    ]

  alias Phoenix.LiveView.JS

  alias Medcamp.Procurement.{GoodsReceived, Shipments}
  alias MedcampWeb.Procurement.LiveHelpers

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "GRN Form")
     |> assign(:shipment, nil)
     |> assign(:grn, nil)
     |> assign(:grn_form, default_grn_form())
     |> assign(:grn_items, [])
     |> assign(:summary, %{accepted: 0, partial: 0, quantity: "0.00", value: "KES 0.00"})}
  end

  @impl true
  def handle_params(%{"shipment_id" => shipment_id}, _uri, socket) do
    shipment = Shipments.get_shipment!(shipment_id)

    existing_grn =
      GoodsReceived.list_grns()
      |> Enum.find(&(&1.shipment_advice_id == shipment.id))
      |> case do
        nil -> nil
        grn -> GoodsReceived.get_grn!(grn.id)
      end

    socket =
      if existing_grn && existing_grn.status == "finalised" do
        push_navigate(socket, to: "/procurement/grn/#{existing_grn.id}")
      else
        assign_grn_form(socket, shipment, existing_grn)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("change", %{"grn" => params}, socket) do
    form = grn_form_from_params(params, socket.assigns.grn_form)
    items = grn_items_from_params(params, socket.assigns.grn_items)
    {:noreply, assign_form_state(socket, form, items)}
  end

  def handle_event("set_condition", %{"id" => id, "condition" => condition}, socket) do
    items =
      Enum.map(socket.assigns.grn_items, fn item ->
        if "#{Map.get(item, "id")}" == id do
          item |> Map.put("condition", condition) |> LiveHelpers.normalize_grn_item()
        else
          item
        end
      end)

    {:noreply, assign_form_state(socket, socket.assigns.grn_form, items)}
  end

  def handle_event("save_draft", _params, socket) do
    case persist_grn(socket) do
      {:ok, grn} ->
        {:noreply,
         socket
         |> put_flash(:info, "GRN draft saved.")
         |> assign_grn_form(socket.assigns.shipment, grn)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, grn_error_message(reason))}
    end
  end

  def handle_event("flag", _params, socket) do
    with {:ok, grn} <- persist_grn(socket),
         {:ok, flagged} <- GoodsReceived.flag_for_review(grn) do
      {:noreply,
       socket
       |> put_flash(:info, "GRN flagged for procurement review.")
       |> assign_grn_form(socket.assigns.shipment, flagged)}
    else
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, grn_error_message(reason))}

      _ ->
        {:noreply, put_flash(socket, :error, "Unable to flag this GRN right now.")}
    end
  end

  def handle_event("finalise", _params, socket) do
    with {:ok, grn} <- persist_grn(socket),
         {:ok, _shipment} <- Shipments.mark_received(socket.assigns.shipment),
         {:ok, finalised} <- GoodsReceived.finalise(grn, socket.assigns.current_user) do
      {:noreply,
       socket
       |> put_flash(:info, "GRN finalised successfully.")
       |> push_navigate(to: "/procurement/grn/#{finalised.id}")}
    else
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, grn_error_message(reason))}

      _ ->
        {:noreply, put_flash(socket, :error, "Unable to finalise this GRN right now.")}
    end
  end

  defp assign_grn_form(socket, shipment, nil) do
    items = build_grn_items_from_shipment(shipment)

    socket
    |> assign(:shipment, shipment)
    |> assign(:grn, nil)
    |> assign_form_state(default_grn_form(), items)
  end

  defp assign_grn_form(socket, shipment, grn) do
    items =
      grn.items
      |> Enum.with_index(1)
      |> Enum.map(fn {item, index} -> grn_item_map(item, index) end)

    socket
    |> assign(:shipment, shipment)
    |> assign(:grn, grn)
    |> assign_form_state(grn_form_from_record(grn), items)
  end

  defp assign_form_state(socket, form, items) do
    summary = LiveHelpers.grn_summary(items)

    socket
    |> assign(:grn_form, form)
    |> assign(:grn_items, items)
    |> assign(:summary, summary)
  end

  defp cancel_path(%{shipment: %{invoice_id: invoice_id}}),
    do: "/procurement/invoices/#{invoice_id}"

  defp cancel_path(_assigns), do: "/procurement/invoices"

  defp persist_grn(socket) do
    attrs = build_grn_attrs(socket)

    case socket.assigns.grn do
      nil ->
        with {:ok, grn} <- GoodsReceived.create(attrs, socket.assigns.current_user) do
          {:ok, GoodsReceived.get_grn!(grn.id)}
        end

      grn ->
        with {:ok, updated_grn} <- GoodsReceived.update_grn(grn, Map.delete(attrs, :items)),
             {:ok, _items} <- update_grn_items(grn, socket.assigns.grn_items) do
          {:ok, GoodsReceived.get_grn!(updated_grn.id)}
        end
    end
  end

  defp update_grn_items(grn, items) do
    results =
      Enum.map(items, fn item ->
        existing =
          Enum.find(grn.items, &(&1.purchase_order_item_id == item["purchase_order_item_id"]))

        GoodsReceived.update_item(existing, %{
          quantity_received: item["quantity_received"],
          variance: item["variance"],
          batch_number: item["batch_number"],
          expiry_date: blank_to_nil(item["expiry_date"]),
          condition: item["condition"],
          inventory_received_id: blank_to_nil(item["inventory_received_id"])
        })
      end)

    if Enum.all?(results, &match?({:ok, _}, &1)), do: {:ok, results}, else: {:error, results}
  end

  defp build_grn_attrs(socket) do
    %{
      purchase_order_id: socket.assigns.shipment.purchase_order_id,
      invoice_id: socket.assigns.shipment.invoice_id,
      shipment_advice_id: socket.assigns.shipment.id,
      supplier_id: socket.assigns.shipment.supplier_id,
      received_date: blank_to_nil(socket.assigns.grn_form["received_date"]),
      received_time: blank_to_nil(socket.assigns.grn_form["received_time"]),
      overall_condition: socket.assigns.grn_form["overall_condition"],
      delivery_remarks: socket.assigns.grn_form["delivery_remarks"],
      discrepancy_description: socket.assigns.grn_form["discrepancy_description"],
      discrepancy_action: socket.assigns.grn_form["discrepancy_action"],
      resolution_deadline: blank_to_nil(socket.assigns.grn_form["resolution_deadline"]),
      packages_received: blank_to_nil(socket.assigns.grn_form["packages_received"]),
      items:
        Enum.map(socket.assigns.grn_items, fn item ->
          %{
            purchase_order_item_id: item["purchase_order_item_id"],
            inventory_received_id: blank_to_nil(item["inventory_received_id"]),
            position: item["position"],
            description: item["description"],
            po_quantity: item["po_quantity"],
            quantity_received: item["quantity_received"],
            variance: item["variance"],
            batch_number: item["batch_number"],
            expiry_date: blank_to_nil(item["expiry_date"]),
            condition: item["condition"]
          }
        end)
    }
    |> LiveHelpers.prune_blank_values()
  end

  defp build_grn_items_from_shipment(shipment) do
    shipment.items
    |> Enum.with_index(1)
    |> Enum.map(fn {item, index} ->
      item
      |> LiveHelpers.grn_item_from_shipment_item()
      |> Map.put(:id, index)
      |> Map.put(:unit_price, item.purchase_order_item && item.purchase_order_item.unit_price)
      |> Map.new(fn {key, value} -> {to_string(key), value} end)
      |> LiveHelpers.normalize_grn_item()
    end)
  end

  defp grn_form_from_record(grn) do
    %{
      "received_date" => grn.received_date && Date.to_iso8601(grn.received_date),
      "received_time" => grn.received_time && Time.to_iso8601(grn.received_time),
      "overall_condition" => grn.overall_condition || "good",
      "delivery_remarks" => grn.delivery_remarks,
      "discrepancy_description" => grn.discrepancy_description,
      "discrepancy_action" => grn.discrepancy_action,
      "resolution_deadline" =>
        grn.resolution_deadline && Date.to_iso8601(grn.resolution_deadline),
      "packages_received" => to_string(grn.packages_received || "")
    }
  end

  defp grn_form_from_params(params, current) do
    Map.merge(
      current,
      Map.take(
        params,
        ~w(received_date received_time overall_condition delivery_remarks discrepancy_description discrepancy_action resolution_deadline packages_received)
      )
    )
  end

  defp grn_items_from_params(params, current) do
    params
    |> Map.get("items", %{})
    |> LiveHelpers.listify_indexed_params()
    |> case do
      [] ->
        current

      items ->
        Enum.with_index(items, 1)
        |> Enum.map(fn {item, index} ->
          item
          |> Map.put("id", index)
          |> Map.put(
            "unit_price",
            current |> Enum.at(index - 1) |> then(&(&1 && &1["unit_price"]))
          )
          |> LiveHelpers.normalize_grn_item()
        end)
    end
  end

  defp grn_item_map(item, index) do
    %{
      "id" => index,
      "purchase_order_item_id" => item.purchase_order_item_id,
      "inventory_received_id" => item.inventory_received_id,
      "position" => item.position,
      "description" => item.description,
      "po_quantity" => item.po_quantity,
      "quantity_received" => item.quantity_received,
      "variance" => item.variance,
      "batch_number" => item.batch_number,
      "expiry_date" => item.expiry_date && Date.to_iso8601(item.expiry_date),
      "condition" => item.condition,
      "unit_price" => item.purchase_order_item && item.purchase_order_item.unit_price
    }
  end

  defp default_grn_form do
    %{
      "received_date" => Date.utc_today() |> Date.to_iso8601(),
      "received_time" => Time.utc_now() |> Time.truncate(:second) |> Time.to_iso8601(),
      "overall_condition" => "good",
      "delivery_remarks" => "",
      "discrepancy_description" => "",
      "discrepancy_action" => "back_delivery",
      "resolution_deadline" => "",
      "packages_received" => ""
    }
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp grn_error_message(%Ecto.Changeset{} = changeset) do
    case first_changeset_error(changeset) do
      {field, message} -> "#{humanize_field(field)} #{message}."
      nil -> "Please review the GRN details and try again."
    end
  end

  defp grn_error_message(results) when is_list(results) do
    results
    |> Enum.find_value(fn
      {:error, %Ecto.Changeset{} = changeset} -> grn_error_message(changeset)
      _ -> nil
    end)
    |> case do
      nil -> "Please review the GRN item details and try again."
      message -> message
    end
  end

  defp grn_error_message(_), do: "Please review the GRN details and try again."

  defp first_changeset_error(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(&replace_error_placeholders/1)
    |> Enum.find_value(fn {field, messages} ->
      case List.first(messages) do
        nil -> nil
        message -> {field, message}
      end
    end)
  end

  defp replace_error_placeholders({message, opts}) do
    Enum.reduce(opts, message, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end

  defp humanize_field(field) do
    field
    |> to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.portal_form_shell
      eyebrow="GRN Form"
      title="Receive shipment goods"
      subtitle="Inspect line items, capture quantities and condition, then finalise the GRN once the receipt is confirmed."
      cancel_path={cancel_path(assigns)}
      max_width="max-w-[96rem]"
    >
      <:actions>
        <.status_badge :if={@grn} status={@grn.status} />
      </:actions>

      <div class="space-y-6">
        <.pipeline_tracker
          steps={LiveHelpers.pipeline_steps()}
          current={:grn}
          document_ids={
            %{
              invoice: @shipment && "/procurement/invoices/#{@shipment.invoice_id}",
              grn: @grn && "/procurement/grn/#{@grn.id}"
            }
            |> Enum.reject(fn {_key, value} -> LiveHelpers.blank?(value) end)
            |> Map.new()
          }
        />

        <.grn_summary_strip summary={@summary} />

        <form phx-change="change" class="space-y-6">
          <div class="grid gap-6 xl:grid-cols-[minmax(0,1.25fr)_minmax(24rem,0.95fr)]">
            <div class="space-y-6">
              <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
                <div class="mb-5">
                  <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                    Receipt details
                  </p>
                  <h2 class="mt-2 text-xl font-semibold text-slate-900">Delivery check-in</h2>
                  <p class="mt-2 max-w-2xl text-sm leading-6 text-slate-500">
                    Record when the goods arrived, package count, overall delivery condition, and any notes from the receiving desk.
                  </p>
                </div>

                <div class="grid gap-4 md:grid-cols-2">
                  <label class="block text-sm font-medium text-slate-700">
                    Received date
                    <input
                      type="date"
                      name="grn[received_date]"
                      value={@grn_form["received_date"]}
                      class="mt-2 w-full rounded-xl border border-slate-200 px-4 py-2.5"
                    />
                  </label>
                  <label class="block text-sm font-medium text-slate-700">
                    Received time
                    <input
                      type="time"
                      name="grn[received_time]"
                      value={@grn_form["received_time"]}
                      class="mt-2 w-full rounded-xl border border-slate-200 px-4 py-2.5"
                    />
                  </label>
                  <label class="block text-sm font-medium text-slate-700">
                    Packages received
                    <input
                      type="number"
                      min="0"
                      name="grn[packages_received]"
                      value={@grn_form["packages_received"]}
                      inputmode="numeric"
                      class="mt-2 w-full rounded-xl border border-slate-200 px-4 py-2.5"
                    />
                  </label>
                  <label class="block text-sm font-medium text-slate-700">
                    Overall condition
                    <select
                      name="grn[overall_condition]"
                      class="mt-2 w-full rounded-xl border border-slate-200 px-4 py-2.5"
                    >
                      <option value="good" selected={@grn_form["overall_condition"] == "good"}>
                        Good
                      </option>
                      <option
                        value="minor_damage"
                        selected={@grn_form["overall_condition"] == "minor_damage"}
                      >
                        Minor damage
                      </option>
                      <option
                        value="significant_damage"
                        selected={@grn_form["overall_condition"] == "significant_damage"}
                      >
                        Significant damage
                      </option>
                    </select>
                  </label>
                </div>

                <label class="mt-4 block text-sm font-medium text-slate-700">
                  Delivery remarks <textarea
                    name="grn[delivery_remarks]"
                    rows="4"
                    class="mt-2 w-full rounded-xl border border-slate-200 px-4 py-2.5"
                  >{@grn_form["delivery_remarks"]}</textarea>
                </label>
              </div>

              <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
                <div class="mb-5 flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
                  <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                      Item verification
                    </p>
                    <h2 class="mt-2 text-xl font-semibold text-slate-900">
                      Match delivery against the PO
                    </h2>
                    <p class="mt-2 max-w-3xl text-sm leading-6 text-slate-500">
                      Confirm received quantity for each line, capture batch and expiry, and mark the condition before finalising the GRN.
                    </p>
                  </div>
                </div>

                <div class="overflow-x-auto">
                  <table class="w-full min-w-[1120px] table-auto text-left text-sm">
                    <colgroup>
                      <col class="w-[32%]" />
                      <col class="w-[10%]" />
                      <col class="w-[12%]" />
                      <col class="w-[10%]" />
                      <col class="w-[18%]" />
                      <col class="w-[18%]" />
                    </colgroup>
                    <thead class="border-b border-slate-200 text-slate-500">
                      <tr>
                        <th class="pb-3 pr-6 font-semibold">Description</th>
                        <th class="pb-3 pr-6 text-right font-semibold">PO qty</th>
                        <th class="pb-3 pr-6 text-right font-semibold">Received qty</th>
                        <th class="pb-3 pr-6 text-right font-semibold">Variance</th>
                        <th class="pb-3 pr-6 font-semibold">Condition</th>
                        <th class="pb-3 font-semibold">Batch</th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                      <tr :for={item <- @grn_items} class="align-top hover:bg-slate-50/60">
                        <td class="py-4 pr-6">
                          <p
                            class="whitespace-normal break-words font-medium leading-6 text-slate-900"
                            title={item["description"]}
                          >
                            {item["description"]}
                          </p>
                          <input
                            type="hidden"
                            name={"grn[items][#{item["id"] - 1}][purchase_order_item_id]"}
                            value={item["purchase_order_item_id"]}
                          />
                          <input
                            type="hidden"
                            name={"grn[items][#{item["id"] - 1}][inventory_received_id]"}
                            value={item["inventory_received_id"]}
                          />
                          <input
                            type="hidden"
                            name={"grn[items][#{item["id"] - 1}][position]"}
                            value={item["position"]}
                          />
                          <input
                            type="hidden"
                            name={"grn[items][#{item["id"] - 1}][description]"}
                            value={item["description"]}
                          />
                          <input
                            type="hidden"
                            name={"grn[items][#{item["id"] - 1}][po_quantity]"}
                            value={item["po_quantity"]}
                          />
                          <input
                            type="hidden"
                            name={"grn[items][#{item["id"] - 1}][condition]"}
                            value={item["condition"]}
                          />
                        </td>
                        <td class="py-4 pr-6 text-right tabular-nums text-slate-600">
                          {LiveHelpers.decimal_to_string(item["po_quantity"])}
                        </td>
                        <td class="py-4 pr-6">
                          <input
                            name={"grn[items][#{item["id"] - 1}][quantity_received]"}
                            value={LiveHelpers.decimal_to_string(item["quantity_received"])}
                            inputmode="decimal"
                            class="w-full rounded-xl border border-slate-200 px-3 py-2 text-right tabular-nums"
                          />
                        </td>
                        <td class="py-4 pr-6 text-right tabular-nums text-slate-600">
                          {LiveHelpers.decimal_to_string(item["variance"])}
                        </td>
                        <td class="py-4 pr-6">
                          <.condition_toggle item={item} on_change="set_condition" />
                        </td>
                        <td class="py-4">
                          <input
                            name={"grn[items][#{item["id"] - 1}][batch_number]"}
                            value={item["batch_number"]}
                            class="mb-2 w-full rounded-xl border border-slate-200 px-3 py-2"
                          />
                          <input
                            type="date"
                            name={"grn[items][#{item["id"] - 1}][expiry_date]"}
                            value={item["expiry_date"]}
                            class="w-full rounded-xl border border-slate-200 px-3 py-2"
                          />
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>

            <div class="space-y-6 xl:sticky xl:top-4 xl:self-start">
              <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
                <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                  Finalisation guide
                </p>
                <div class="mt-4 space-y-3 text-sm text-slate-600">
                  <div class="rounded-2xl bg-slate-50 px-4 py-3">
                    1. Confirm quantities and condition for every line item.
                  </div>
                  <div class="rounded-2xl bg-slate-50 px-4 py-3">
                    2. Add discrepancy details only when there is a variance or damaged stock.
                  </div>
                  <div class="rounded-2xl bg-slate-50 px-4 py-3">
                    3. Save draft if receiving is still in progress, or finalise once the physical check is complete.
                  </div>
                </div>
              </div>

              <div
                :if={LiveHelpers.has_grn_variances?(@grn_items)}
                class="rounded-[2rem] border border-amber-200 bg-amber-50 p-6 shadow-sm"
              >
                <p class="text-xs font-semibold uppercase tracking-[0.24em] text-amber-700">
                  Discrepancy section
                </p>
                <p class="mt-3 text-sm leading-6 text-amber-900/80">
                  This appears because one or more received quantities differ from the PO, or the condition needs follow-up.
                </p>
                <div class="mt-4 space-y-4">
                  <label class="block text-sm font-medium text-amber-900">
                    Discrepancy description <textarea
                      name="grn[discrepancy_description]"
                      rows="5"
                      class="mt-2 w-full rounded-xl border border-amber-200 px-4 py-2.5 text-slate-700"
                    >{@grn_form["discrepancy_description"]}</textarea>
                  </label>
                  <label class="block text-sm font-medium text-amber-900">
                    Discrepancy action
                    <select
                      name="grn[discrepancy_action]"
                      class="mt-2 w-full rounded-xl border border-amber-200 px-4 py-2.5 text-slate-700"
                    >
                      <option
                        value="back_delivery"
                        selected={@grn_form["discrepancy_action"] == "back_delivery"}
                      >
                        Back delivery
                      </option>
                      <option
                        value="credit_note"
                        selected={@grn_form["discrepancy_action"] == "credit_note"}
                      >
                        Credit note
                      </option>
                      <option
                        value="accept_as_is"
                        selected={@grn_form["discrepancy_action"] == "accept_as_is"}
                      >
                        Accept as is
                      </option>
                    </select>
                  </label>
                  <label class="block text-sm font-medium text-amber-900">
                    Resolution deadline
                    <input
                      type="date"
                      name="grn[resolution_deadline]"
                      value={@grn_form["resolution_deadline"]}
                      class="mt-2 w-full rounded-xl border border-amber-200 px-4 py-2.5 text-slate-700"
                    />
                  </label>
                </div>
              </div>

              <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
                <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                  Signature block
                </p>
                <p class="mt-3 text-sm leading-6 text-slate-500">
                  Leave space for sign-off after the physical receiving check is complete.
                </p>
                <div class="mt-4 space-y-4 text-sm text-slate-500">
                  <div class="border-b border-dashed border-slate-300 pb-3">
                    Received by signature
                  </div>
                  <div class="border-b border-dashed border-slate-300 pb-3">
                    Stores officer signature
                  </div>
                  <div class="border-b border-dashed border-slate-300 pb-3">
                    Supplier representative signature
                  </div>
                </div>
              </div>

              <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
                <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                  Actions
                </p>
                <div class="mt-4 grid gap-3">
                  <button
                    type="button"
                    phx-click="save_draft"
                    class="w-full rounded-xl border border-slate-200 px-4 py-3 text-sm font-semibold text-slate-700 transition hover:bg-slate-50"
                  >
                    Save draft
                  </button>
                  <button
                    type="button"
                    phx-click="flag"
                    class="w-full rounded-xl border border-amber-200 px-4 py-3 text-sm font-semibold text-amber-700 transition hover:bg-amber-50"
                  >
                    Flag for review
                  </button>
                  <button
                    type="button"
                    phx-click={show_modal("grn-finalise-confirm")}
                    class="w-full rounded-xl bg-[#373896] px-4 py-3 text-sm font-semibold text-white transition hover:bg-[#2d2d7a]"
                  >
                    Finalise GRN
                  </button>
                </div>
              </div>
            </div>
          </div>
        </form>
      </div>
    </.portal_form_shell>

    <.confirmation_modal
      id="grn-finalise-confirm"
      title="Finalise GRN?"
      body="Finalising the GRN is irreversible. The related invoice will move to GRN confirmed and the supplier will be notified."
      confirm_label="Finalise GRN"
      on_confirm={JS.push("finalise")}
    />
    """
  end
end
