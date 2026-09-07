defmodule MedcampWeb.AdminMpesaReconciliationLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.Mpesas
  alias Medcamp.Pay
  alias MedcampWeb.MpesaController

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :mpesa_reconciliation)
     |> assign(:transaction_code, "")
     |> assign(:search_results, [])
     |> assign(:mpesa, nil)
     |> assign(:linked_status, nil)
     |> assign(:query_response, nil)}
  end

  @impl true
  def handle_event("lookup", %{"transaction_code" => transaction_code}, socket) do
    transaction_code = String.trim(transaction_code || "")

    socket =
      socket
      |> assign(:transaction_code, transaction_code)
      |> assign(:search_results, [])
      |> assign(:query_response, nil)

    cond do
      transaction_code == "" ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Enter a receipt, checkout request id, or merchant request id."
         )}

      mpesa = Mpesas.get_mpesa_reconciliation_result(transaction_code) ->
        {:noreply, assign_payment(socket, mpesa)}

      true ->
        results = Mpesas.list_mpesa_reconciliation_results(transaction_code)

        socket =
          socket
          |> assign(:mpesa, nil)
          |> assign(:linked_status, nil)
          |> assign(:search_results, results)

        if Enum.empty?(results) do
          {:noreply, put_flash(socket, :error, "No M-Pesa transactions were found.")}
        else
          {:noreply, put_flash(socket, :info, "Select the matching triggered payment below.")}
        end
    end
  end

  @impl true
  def handle_event("select_payment", %{"id" => id}, socket) do
    mpesa = Mpesas.get_mpesa_reconciliation_result_by_id(id)

    {:noreply,
     socket
     |> assign(:search_results, [])
     |> assign(:query_response, nil)
     |> assign_payment(mpesa)}
  end

  @impl true
  def handle_event("query_mpesa", _params, %{assigns: %{mpesa: nil}} = socket) do
    {:noreply, put_flash(socket, :error, "Find a local M-Pesa transaction first.")}
  end

  def handle_event("query_mpesa", _params, socket) do
    mpesa = socket.assigns.mpesa

    case Pay.make_query(mpesa.checkout_request_id) do
      {:ok, response, 200} ->
        case MpesaController.apply_query_result(mpesa.checkout_request_id, response) do
          {:ok, updated_mpesa} ->
            updated_mpesa =
              Mpesas.get_mpesa_reconciliation_result(updated_mpesa.checkout_request_id)

            {:noreply,
             socket
             |> assign(:query_response, response)
             |> assign_payment(updated_mpesa)
             |> put_flash(:info, "M-Pesa status query completed.")}

          {:error, :not_found} ->
            {:noreply,
             put_flash(socket, :error, "The local M-Pesa transaction no longer exists.")}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Could not update the local M-Pesa record.")}
        end

      {:ok, response, status} ->
        {:noreply,
         socket
         |> assign(:query_response, response)
         |> put_flash(:error, "M-Pesa returned HTTP #{status}.")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "M-Pesa query failed: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("mark_linked_paid", _params, %{assigns: %{mpesa: nil}} = socket) do
    {:noreply, put_flash(socket, :error, "Find a local M-Pesa transaction first.")}
  end

  def handle_event("mark_linked_paid", _params, socket) do
    case MpesaController.mark_linked_record_paid(socket.assigns.mpesa) do
      {:ok, :marked_paid} ->
        mpesa = Mpesas.get_mpesa_reconciliation_result(socket.assigns.mpesa.checkout_request_id)

        {:noreply,
         socket
         |> assign_payment(mpesa)
         |> put_flash(:info, "Linked record has been marked paid.")}

      {:ok, :already_paid} ->
        {:noreply, put_flash(socket, :info, "Linked record is already marked paid.")}

      {:error, :mpesa_not_successful} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Only successful M-Pesa transactions can mark linked records paid."
         )}
    end
  end

  defp assign_payment(socket, mpesa) do
    socket
    |> assign(:mpesa, mpesa)
    |> assign(:search_results, [])
    |> assign(:linked_status, Mpesas.actionable_payment_status(mpesa))
  end

  defp patient_name(nil), do: "Unknown patient"

  defp patient_name(patient) do
    [patient.first_name, patient.middle_name, patient.last_name]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  defp status_text(%{payment_pending: true}), do: "Pending"
  defp status_text(%{is_successful: true}), do: "Successful"
  defp status_text(%{result_code: nil}), do: "Unknown"
  defp status_text(_mpesa), do: "Failed"

  defp status_classes(%{payment_pending: true}), do: "bg-amber-100 text-amber-800"
  defp status_classes(%{is_successful: true}), do: "bg-emerald-100 text-emerald-800"
  defp status_classes(%{result_code: nil}), do: "bg-slate-100 text-slate-700"
  defp status_classes(_mpesa), do: "bg-rose-100 text-rose-800"

  defp yes_no(true), do: "Yes"
  defp yes_no(_), do: "No"

  defp money(nil), do: "0 KES"
  defp money(amount), do: "#{amount} KES"

  defp payment_reference(mpesa) do
    mpesa.receipt || mpesa.checkout_request_id || mpesa.merchant_request_id || "No reference"
  end

  defp format_datetime(nil), do: "Not recorded"

  defp format_datetime(datetime) do
    datetime
    |> DateTime.shift_zone!("Africa/Nairobi")
    |> Calendar.strftime("%d %b %Y, %I:%M %p")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-6xl space-y-6">
      <.page_header
        icon_path="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 4V2m0 20v-2m8-8h2M2 12h2m14.364-6.364 1.414-1.414M4.222 19.778l1.414-1.414m0-12.728L4.222 4.222m15.556 15.556-1.414-1.414"
        title="M-Pesa Reconciliation"
        subtitle="Query STK transactions and repair linked payment records when callbacks do not arrive."
      />

      <section class="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
        <form phx-submit="lookup" class="group flex flex-col gap-3 md:flex-row md:items-end">
          <div class="flex-1">
            <label for="transaction_code" class="text-sm font-medium text-slate-700">
              Transaction code or phone number
            </label>
            <input
              id="transaction_code"
              name="transaction_code"
              value={@transaction_code}
              placeholder="Receipt, CheckoutRequestID, MerchantRequestID, or phone"
              class="mt-1 w-full rounded-md border border-slate-300 px-3 py-2 text-sm focus:border-[#6667ab] focus:outline-none focus:ring-2 focus:ring-[#d2d3ff]"
            />
          </div>

          <button
            type="submit"
            class="inline-flex items-center justify-center gap-2 rounded-md bg-[#6667ab] px-4 py-2 text-sm font-semibold text-white hover:bg-[#5556a0] disabled:cursor-wait disabled:opacity-80"
          >
            <span class="inline-flex items-center gap-2 group-[.phx-submit-loading]:hidden">
              <Heroicons.icon name="magnifying-glass" type="outline" class="h-4 w-4" />
              Find Transaction
            </span>
            <span class="hidden items-center gap-2 group-[.phx-submit-loading]:inline-flex">
              <Heroicons.icon name="arrow-path" type="outline" class="h-4 w-4 animate-spin" />
              Searching...
            </span>
          </button>
        </form>
      </section>

      <.blank_state
        :if={is_nil(@mpesa) and Enum.empty?(@search_results)}
        icon_path="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z"
        title="Search for an M-Pesa transaction"
        description="Use a receipt, checkout request id, merchant request id, or phone number from the customer confirmation."
      />

      <section
        :if={@search_results != []}
        class="rounded-lg border border-slate-200 bg-white p-5 shadow-sm"
      >
        <div class="mb-4">
          <h2 class="text-lg font-semibold text-slate-900">Triggered payments found</h2>
          <p class="mt-1 text-sm text-slate-500">
            Pick the payment that matches the customer, amount, and prompt time, then query M-Pesa.
          </p>
        </div>

        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="bg-slate-50 text-left text-xs font-semibold uppercase text-slate-500">
              <tr>
                <th class="px-3 py-2">Reference</th>
                <th class="px-3 py-2">Patient</th>
                <th class="px-3 py-2">Phone</th>
                <th class="px-3 py-2">Amount</th>
                <th class="px-3 py-2">Status</th>
                <th class="px-3 py-2">Prompted</th>
                <th class="px-3 py-2"></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
              <tr :for={result <- @search_results}>
                <td class="max-w-[220px] break-all px-3 py-3 text-slate-900">
                  {payment_reference(result)}
                </td>
                <td class="px-3 py-3 text-slate-700">{patient_name(result.patient)}</td>
                <td class="px-3 py-3 text-slate-700">{result.account_number || result.phone}</td>
                <td class="px-3 py-3 text-slate-700">{money(result.amount)}</td>
                <td class="px-3 py-3">
                  <span class={"inline-flex rounded-full px-2.5 py-1 text-xs font-semibold #{status_classes(result)}"}>
                    {status_text(result)}
                  </span>
                </td>
                <td class="px-3 py-3 text-slate-700">{format_datetime(result.inserted_at)}</td>
                <td class="px-3 py-3 text-right">
                  <button
                    type="button"
                    phx-click="select_payment"
                    phx-value-id={result.id}
                    class="inline-flex items-center gap-2 rounded-md border border-[#6667ab] px-3 py-1.5 text-xs font-semibold text-[#373896] hover:bg-[#f0f0ff]"
                  >
                    Select
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <div :if={@mpesa} class="grid gap-6 lg:grid-cols-[1.4fr_1fr]">
        <section class="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
          <div class="flex flex-col gap-3 border-b border-slate-100 pb-4 md:flex-row md:items-start md:justify-between">
            <div>
              <p class="text-sm font-medium text-slate-500">Local M-Pesa record</p>
              <h2 class="mt-1 text-xl font-semibold text-slate-900">
                {@mpesa.receipt || @mpesa.checkout_request_id}
              </h2>
            </div>
            <span class={"inline-flex w-fit rounded-full px-3 py-1 text-xs font-semibold #{status_classes(@mpesa)}"}>
              {status_text(@mpesa)}
            </span>
          </div>

          <dl class="mt-5 grid gap-4 md:grid-cols-2">
            <div>
              <dt class="text-xs font-semibold uppercase text-slate-500">Patient</dt>
              <dd class="mt-1 text-sm text-slate-900">{patient_name(@mpesa.patient)}</dd>
            </div>
            <div>
              <dt class="text-xs font-semibold uppercase text-slate-500">Amount</dt>
              <dd class="mt-1 text-sm text-slate-900">{money(@mpesa.amount)}</dd>
            </div>
            <div>
              <dt class="text-xs font-semibold uppercase text-slate-500">Phone</dt>
              <dd class="mt-1 text-sm text-slate-900">{@mpesa.account_number || @mpesa.phone}</dd>
            </div>
            <div>
              <dt class="text-xs font-semibold uppercase text-slate-500">Prompted By</dt>
              <dd class="mt-1 text-sm text-slate-900">{@mpesa.prompter && @mpesa.prompter.name}</dd>
            </div>
            <div>
              <dt class="text-xs font-semibold uppercase text-slate-500">Checkout Request ID</dt>
              <dd class="mt-1 break-all text-sm text-slate-900">{@mpesa.checkout_request_id}</dd>
            </div>
            <div>
              <dt class="text-xs font-semibold uppercase text-slate-500">Merchant Request ID</dt>
              <dd class="mt-1 break-all text-sm text-slate-900">{@mpesa.merchant_request_id}</dd>
            </div>
            <div>
              <dt class="text-xs font-semibold uppercase text-slate-500">Result</dt>
              <dd class="mt-1 text-sm text-slate-900">
                {@mpesa.result_code || "No result code"} - {@mpesa.description || "No description"}
              </dd>
            </div>
            <div>
              <dt class="text-xs font-semibold uppercase text-slate-500">Created</dt>
              <dd class="mt-1 text-sm text-slate-900">{format_datetime(@mpesa.inserted_at)}</dd>
            </div>
          </dl>

          <div class="mt-5 flex flex-wrap gap-3">
            <button
              type="button"
              phx-click="query_mpesa"
              disabled={is_nil(@mpesa.checkout_request_id)}
              class="group inline-flex items-center gap-2 rounded-md border border-[#6667ab] px-4 py-2 text-sm font-semibold text-[#373896] hover:bg-[#f0f0ff] disabled:cursor-not-allowed disabled:opacity-50"
            >
              <span class="inline-flex items-center gap-2 group-[.phx-click-loading]:hidden">
                <Heroicons.icon name="arrow-path" type="outline" class="h-4 w-4" />
                Query M-Pesa Status
              </span>
              <span class="hidden items-center gap-2 group-[.phx-click-loading]:inline-flex">
                <Heroicons.icon name="arrow-path" type="outline" class="h-4 w-4 animate-spin" />
                Querying...
              </span>
            </button>
          </div>
        </section>

        <section class="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
          <p class="text-sm font-medium text-slate-500">Linked record</p>
          <h2 class="mt-1 text-xl font-semibold text-slate-900">{@linked_status.label}</h2>

          <dl class="mt-5 space-y-4">
            <div>
              <dt class="text-xs font-semibold uppercase text-slate-500">Type</dt>
              <dd class="mt-1 text-sm text-slate-900">
                {@mpesa.actionable_type} {@mpesa.actionable_id}
              </dd>
            </div>
            <div>
              <dt class="text-xs font-semibold uppercase text-slate-500">Marked Paid</dt>
              <dd class="mt-1 text-sm text-slate-900">{yes_no(@linked_status.paid)}</dd>
            </div>
            <div>
              <dt class="text-xs font-semibold uppercase text-slate-500">Amount Recorded</dt>
              <dd class="mt-1 text-sm text-slate-900">{money(@linked_status.amount_paid)}</dd>
            </div>
            <div>
              <dt class="text-xs font-semibold uppercase text-slate-500">Detail</dt>
              <dd class="mt-1 text-sm text-slate-900">{@linked_status.detail}</dd>
            </div>
          </dl>

          <button
            :if={@mpesa.is_successful == true and @linked_status.paid == false}
            type="button"
            phx-click="mark_linked_paid"
            class="mt-5 inline-flex w-full items-center justify-center gap-2 rounded-md bg-emerald-600 px-4 py-2 text-sm font-semibold text-white hover:bg-emerald-700"
          >
            <.icon name="hero-check-circle" class="h-4 w-4" /> Mark Linked Record Paid
          </button>

          <p
            :if={@mpesa.is_successful != true and @linked_status.paid == false}
            class="mt-5 rounded-md bg-amber-50 px-3 py-2 text-sm text-amber-800"
          >
            Query M-Pesa first. The linked record can only be marked paid after the transaction is successful.
          </p>
        </section>
      </div>

      <section :if={@query_response} class="rounded-lg border border-slate-200 bg-slate-50 p-5">
        <h3 class="text-sm font-semibold uppercase text-slate-600">Latest M-Pesa Query Response</h3>
        <pre class="mt-3 max-h-72 overflow-auto rounded-md bg-slate-900 p-4 text-xs text-slate-100"><%= Jason.encode!(@query_response, pretty: true) %></pre>
      </section>
    </div>
    """
  end
end
