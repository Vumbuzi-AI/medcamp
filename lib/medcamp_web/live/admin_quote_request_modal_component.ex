defmodule MedcampWeb.AdminQuoteRequestModalComponent do
  @moduledoc """
  Modal to request a quote. Two modes:
  - With supplier: quantity + notes → send to supplier email.
  - No supplier: quantity, notes, recipient email, prefilled subject/body → user can edit and send.
  """
  use MedcampWeb, :live_component

  @impl true
  def update(assigns, socket) do
    quantity = Map.get(assigns, :quantity, "1")
    notes = Map.get(assigns, :notes, "")
    item_name = assigns.item_name
    {subject, body} = build_subject_and_body(item_name, quantity, notes)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:quantity, quantity)
     |> assign(:notes, notes)
     |> assign(:recipient_email, Map.get(assigns, :recipient_email, ""))
     |> assign(:subject, subject)
     |> assign(:body, body)}
  end

  @impl true
  def render(assigns) do
    if assigns.supplier do
      render_with_supplier(assigns)
    else
      render_no_supplier(assigns)
    end
  end

  defp render_with_supplier(assigns) do
    ~H"""
    <div class="space-y-4">
      <.header>
        Request quote
        <:subtitle>
          How many units do you need? An email will be sent to the supplier ({@supplier.name}) asking for a quote.
        </:subtitle>
      </.header>
      <p class="text-sm text-gray-600">
        Item: <strong>{@item_name}</strong>
      </p>
      <form
        id="quote-request-form"
        phx-submit="submit_quote_request"
        phx-target={@myself}
        class="space-y-4"
      >
        <div>
          <label for="quote_quantity" class="block text-sm font-medium text-gray-700 mb-1">
            Quantity needed
          </label>
          <input
            type="number"
            name="quantity"
            id="quote_quantity"
            min="1"
            required
            class="w-full rounded-lg border border-gray-300 focus:ring-[#6667ab] focus:border-[#6667ab] px-3 py-2"
            placeholder="e.g. 100"
          />
        </div>
        <div>
          <label for="quote_notes" class="block text-sm font-medium text-gray-700 mb-1">
            Notes (optional)
          </label>
          <textarea
            name="notes"
            id="quote_notes"
            rows="3"
            class="w-full rounded-lg border border-gray-300 focus:ring-[#6667ab] focus:border-[#6667ab] px-3 py-2"
            placeholder="Delivery date, packaging preferences, etc."
          ></textarea>
        </div>
        <div class="flex gap-2">
          <.button type="submit" phx-disable-with="Sending...">Send quote request</.button>
          <button
            type="button"
            phx-click="cancel_quote_request"
            phx-target={@myself}
            class="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50"
          >
            Cancel
          </button>
        </div>
      </form>
    </div>
    """
  end

  defp render_no_supplier(assigns) do
    ~H"""
    <div class="space-y-4">
      <.header>
        Request quote (no supplier linked)
        <:subtitle>
          Enter quantity and notes, then the recipient email. Subject and body are prefilled; you can edit them before sending.
        </:subtitle>
      </.header>
      <p class="text-sm text-gray-600">
        Item: <strong>{@item_name}</strong>
      </p>
      <form
        id="quote-request-no-supplier-form"
        phx-change="update_preview"
        phx-submit="submit_quote_request_no_supplier"
        phx-target={@myself}
        class="space-y-4"
      >
        <div>
          <label for="quote_quantity_ns" class="block text-sm font-medium text-gray-700 mb-1">
            Quantity needed
          </label>
          <input
            type="number"
            name="quantity"
            id="quote_quantity_ns"
            min="1"
            value={@quantity}
            required
            class="w-full rounded-lg border border-gray-300 focus:ring-[#6667ab] focus:border-[#6667ab] px-3 py-2"
            placeholder="e.g. 100"
          />
        </div>
        <div>
          <label for="quote_notes_ns" class="block text-sm font-medium text-gray-700 mb-1">
            Notes (optional)
          </label>
          <textarea
            name="notes"
            id="quote_notes_ns"
            rows="2"
            class="w-full rounded-lg border border-gray-300 focus:ring-[#6667ab] focus:border-[#6667ab] px-3 py-2"
            placeholder="Delivery date, packaging preferences, etc."
          >{@notes}</textarea>
        </div>
        <div>
          <label for="quote_recipient_email" class="block text-sm font-medium text-gray-700 mb-1">
            Send to (email)
          </label>
          <input
            type="email"
            name="recipient_email"
            id="quote_recipient_email"
            value={@recipient_email}
            required
            class="w-full rounded-lg border border-gray-300 focus:ring-[#6667ab] focus:border-[#6667ab] px-3 py-2"
            placeholder="supplier@example.com"
          />
        </div>
        <div>
          <label for="quote_subject" class="block text-sm font-medium text-gray-700 mb-1">
            Subject
          </label>
          <input
            type="text"
            name="subject"
            id="quote_subject"
            value={@subject}
            class="w-full rounded-lg border border-gray-300 focus:ring-[#6667ab] focus:border-[#6667ab] px-3 py-2"
          />
        </div>
        <div>
          <label for="quote_body" class="block text-sm font-medium text-gray-700 mb-1">
            Body (prefilled – edit as needed)
          </label>
          <textarea
            name="body"
            id="quote_body"
            rows="8"
            class="w-full rounded-lg border border-gray-300 focus:ring-[#6667ab] focus:border-[#6667ab] px-3 py-2 font-mono text-sm"
          >{@body}</textarea>
        </div>
        <div class="flex gap-2">
          <.button type="submit" phx-disable-with="Sending...">Send</.button>
          <button
            type="button"
            phx-click="cancel_quote_request"
            phx-target={@myself}
            class="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50"
          >
            Cancel
          </button>
        </div>
      </form>
    </div>
    """
  end

  defp build_subject_and_body(item_name, quantity, notes) do
    qty_str = if is_binary(quantity), do: quantity, else: to_string(quantity)
    notes_str = if is_binary(notes), do: notes, else: ""
    subject = "Quote Request – #{item_name} (#{qty_str} units)"

    body = """
    Hello,

    Glocal Health Centre would like to request a quote for the following:

    Item: #{item_name}
    Quantity requested: #{qty_str} units
    #{if notes_str != "", do: "Notes: #{notes_str}\n", else: ""}

    Please provide your quote at your earliest convenience.

    — Glocal Health Centre
    """

    {subject, String.trim(body)}
  end

  @impl true
  def handle_event("update_preview", params, socket) do
    qty = Map.get(params, "quantity", socket.assigns.quantity)
    notes = Map.get(params, "notes", socket.assigns.notes)
    recipient = Map.get(params, "recipient_email", socket.assigns.recipient_email)
    {subject, body} = build_subject_and_body(socket.assigns.item_name, qty, notes)

    {:noreply,
     socket
     |> assign(:quantity, qty)
     |> assign(:notes, notes)
     |> assign(:recipient_email, recipient)
     |> assign(:subject, subject)
     |> assign(:body, body)}
  end

  def handle_event("submit_quote_request", %{"quantity" => qty, "notes" => notes}, socket) do
    send(
      self(),
      {:submit_quote_request, %{quantity: String.trim(qty), notes: String.trim(notes)}}
    )

    {:noreply, socket}
  end

  def handle_event(
        "submit_quote_request_no_supplier",
        %{"recipient_email" => email, "subject" => subject, "body" => body},
        socket
      ) do
    send(
      self(),
      {:submit_quote_request_no_supplier,
       %{
         recipient_email: String.trim(email),
         subject: String.trim(subject),
         body: String.trim(body)
       }}
    )

    {:noreply, socket}
  end

  def handle_event("cancel_quote_request", _, socket) do
    send(self(), :cancel_quote_request)
    {:noreply, socket}
  end
end
