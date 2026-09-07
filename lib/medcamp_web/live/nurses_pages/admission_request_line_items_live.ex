defmodule MedcampWeb.NursesPages.AdmissionRequestLineItemsLive do
  use MedcampWeb, :live_component

  alias Medcamp.AdmissionRequests
  alias Medcamp.AdmissionRequests.LineItem

  @impl true
  def update(assigns, socket) do
    line_items =
      AdmissionRequests.list_line_items_for_admission_request(assigns.admission_request.id)

    total = AdmissionRequests.total_line_items_amount(assigns.admission_request.id)
    form = to_form(AdmissionRequests.change_line_item(%LineItem{}), as: "line_item")
    prefix = Map.get(assigns, :line_item_trigger_prefix)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:line_items, line_items)
     |> assign(:line_items_total, total)
     |> assign(:form, form)
     |> assign(:line_item_trigger_prefix, prefix)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <p class="text-sm text-gray-600">
        Add costs / line items for this admission. Total is used when prompting payment (M-Pesa or wallet).
      </p>

      <.simple_form
        for={@form}
        id="line-item-form"
        phx-target={@myself}
        phx-change="validate_line_item"
        phx-submit="add_line_item"
        class="space-y-3"
      >
        <input type="hidden" name="line_item[admission_request_id]" value={@admission_request.id} />
        <div class="grid grid-cols-1 md:grid-cols-3 gap-3 items-end">
          <.input
            field={@form[:item_type]}
            type="select"
            label="Type"
            options={Enum.map(LineItem.item_types(), &{LineItem.item_type_label(&1), &1})}
          />
          <.input field={@form[:price]} type="number" label="Price (KSh)" min="0" />
          <div>
            <button
              type="submit"
              class="w-full px-4 py-2 bg-[#373896] text-white text-sm font-medium rounded-md hover:bg-[#2a2a70]"
            >
              Add
            </button>
          </div>
        </div>
      </.simple_form>

      <div class="border rounded-lg overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Type</th>
              <th class="px-4 py-2 text-right text-xs font-medium text-gray-500 uppercase">
                Price (KSh)
              </th>
              <th class="px-4 py-2 text-right text-xs font-medium text-gray-500 uppercase">
                Paid (KSh)
              </th>
              <th class="px-4 py-2 text-center text-xs font-medium text-gray-500 uppercase">
                Status
              </th>
              <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <%= for li <- @line_items do %>
              <% paid = (li.amount_paid || 0) >= (li.price || 0) %>
              <tr>
                <td class="px-4 py-2 text-sm text-gray-900">
                  {LineItem.item_type_label(li.item_type)}
                </td>
                <td class="px-4 py-2 text-sm text-right font-medium">{li.price}</td>
                <td class="px-4 py-2 text-sm text-right text-gray-600">{li.amount_paid || 0}</td>
                <td class="px-4 py-2 text-center">
                  <%= if paid do %>
                    <span class="px-2 py-0.5 bg-green-100 text-green-800 text-xs rounded-full">
                      Paid
                    </span>
                  <% else %>
                    <span class="px-2 py-0.5 bg-amber-100 text-amber-800 text-xs rounded-full">
                      Unpaid
                    </span>
                  <% end %>
                </td>
                <td class="px-4 py-2 space-x-2">
                  <%= if @line_item_trigger_prefix && !paid do %>
                    <.link
                      patch={"#{@line_item_trigger_prefix}/#{li.id}/trigger_payment"}
                      class="text-sm font-medium text-green-600 hover:text-green-800"
                    >
                      Pay
                    </.link>
                    <span class="text-gray-300">|</span>
                  <% end %>
                  <button
                    type="button"
                    phx-click="delete_line_item"
                    phx-target={@myself}
                    phx-value-id={li.id}
                    data-confirm="Remove this line item?"
                    class="text-red-600 hover:text-red-800 text-sm"
                  >
                    Remove
                  </button>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
        <%= if Enum.empty?(@line_items) do %>
          <div class="px-4 py-6 text-center text-sm text-gray-500">
            No line items yet. Add one above.
          </div>
        <% end %>
      </div>

      <div class="flex justify-between items-center pt-2 border-t">
        <span class="font-semibold text-gray-900">Total</span>
        <span class="text-lg font-bold text-[#373896]">KSh {@line_items_total}</span>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("validate_line_item", %{"line_item" => params}, socket) do
    params = Map.put(params, "admission_request_id", socket.assigns.admission_request.id)

    # When item_type changes, update price to that type's default so prefilled amount follows the selection
    params =
      case params["item_type"] do
        type when is_binary(type) and type != "" ->
          case LineItem.default_price(type) do
            nil -> params
            default -> Map.put(params, "price", to_string(default))
          end

        _ ->
          params
      end

    changeset =
      %LineItem{}
      |> LineItem.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: "line_item"))}
  end

  def handle_event("add_line_item", %{"line_item" => params}, socket) do
    params = Map.put(params, "admission_request_id", socket.assigns.admission_request.id)

    case AdmissionRequests.create_line_item(params) do
      {:ok, _} ->
        line_items =
          AdmissionRequests.list_line_items_for_admission_request(
            socket.assigns.admission_request.id
          )

        total = AdmissionRequests.total_line_items_amount(socket.assigns.admission_request.id)

        {:noreply,
         socket
         |> put_flash(:info, "Line item added")
         |> assign(:line_items, line_items)
         |> assign(:line_items_total, total)
         |> assign(
           :form,
           to_form(AdmissionRequests.change_line_item(%LineItem{}), as: "line_item")
         )}

      {:error, %Ecto.Changeset{} = cs} ->
        {:noreply, assign(socket, :form, to_form(cs, as: "line_item"))}
    end
  end

  def handle_event("delete_line_item", %{"id" => id}, socket) do
    li = AdmissionRequests.get_line_item!(id)
    {:ok, _} = AdmissionRequests.delete_line_item(li)

    line_items =
      AdmissionRequests.list_line_items_for_admission_request(socket.assigns.admission_request.id)

    total = AdmissionRequests.total_line_items_amount(socket.assigns.admission_request.id)

    {:noreply,
     socket
     |> put_flash(:info, "Line item removed")
     |> assign(:line_items, line_items)
     |> assign(:line_items_total, total)}
  end
end
