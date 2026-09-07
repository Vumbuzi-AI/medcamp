defmodule MedcampWeb.ConfirmPaymentLive.Index do
  use MedcampWeb, :live_view
  alias Phoenix.PubSub
  alias Medcamp.Mpesas
  alias Medcamp.Pay

  @impl true
  def mount(params, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(Medcamp.PubSub, "confirm_payment_for:#{params["checkout_request_id"]}")
    end

    case Mpesas.get_mpesa_by_checkout_request_id(params["checkout_request_id"]) do
      nil ->
        {:ok,
         socket
         |> push_navigate(to: "/")}

      mpesa ->
        {:ok,
         socket
         |> assign(:mpesa, mpesa)
         |> assign(:action_to_perform, params["action"])
         |> assign(:return_url, params["return_url"])
         |> assign(:payment_error, nil)
         |> assign(:mpesa_error, mpesa.description)
         |> assign(:payment_pending, mpesa.payment_pending)}
    end
  end

  @impl true

  def handle_info({:payment_confirmed, mpesa}, socket) do
    Logger.info("Payment confirmed")

    {:noreply,
     socket
     |> assign(:mpesa, mpesa)
     |> assign(:payment_pending, false)}
  end

  def handle_info({:payment_failed, mpesa}, socket) do
    Logger.error("Payment failed")

    {:noreply,
     socket
     |> assign(:mpesa, mpesa)
     |> assign(:mpesa_error, mpesa.description)
     |> assign(:payment_pending, false)}
  end

  @impl true
  def handle_event("retry_payment", _, socket) do
    case Pay.make_request(socket.assigns.mpesa.amount, socket.assigns.mpesa.phone) do
      {:ok, params, 200} ->
        {:ok, mpesa} =
          Mpesas.update_mpesa(socket.assigns.mpesa, %{
            "payment_pending" => true,
            "checkout_request_id" => params["CheckoutRequestID"],
            "merchant_request_id" => params["MerchantRequestID"]
          })

        {:noreply,
         socket
         |> push_navigate(
           to:
             "/confirm?checkout_request_id=#{mpesa.checkout_request_id}&return_url=#{socket.assigns.return_url}&action=#{socket.assigns.action_to_perform}"
         )}

      {:ok, params, _} ->
        {:noreply,
         socket
         |> assign(
           :payment_error,
           "An error occured while processing the payment, #{params["errorMessage"]} , please try again"
         )}

      {:error, "Request Timed Out"} ->
        {:noreply,
         socket
         |> assign(
           :payment_error,
           "An error occured while processing the payment, please try again"
         )}
    end
  end

  def handle_event("clear_payment_error", _, socket) do
    {:noreply, assign(socket, payment_error: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-[100%] h-[100vh] flex items-center justify-center">
      <%= if @payment_pending do %>
        <div
          id="loadingState"
          class="w-[60%] h-[50vh] flex justify-center items-center flex-col bg-white rounded-lg shadow-md p-8 text-center"
        >
          <div class="mx-auto mb-8 w-20 h-20 border-4 border-blue-100 border-t-blue-500 rounded-full animate-spin">
          </div>

          <h2 class="text-2xl font-semibold text-gray-800 mb-4">Check Your Phone</h2>
          <p class="text-gray-600 mb-8 leading-relaxed">
            We're waiting for confirmation of your payment. Please check your phone for an  STK Push message from M-Pesa.
          </p>
        </div>
      <% else %>
        <%= if @mpesa.is_successful do %>
          <div
            id="successState"
            class="  w-[60%] h-[50vh] flex justify-center items-center flex-col bg-white rounded-lg shadow-md p-8 text-center"
          >
            <div class="mx-auto mb-8 w-20 h-20 bg-green-500 rounded-full flex items-center justify-center">
              <div class="w-6 h-12 border-r-4 border-b-4 border-white transform rotate-45 translate-y-[-6px]">
              </div>
            </div>

            <h2 class="text-2xl font-semibold text-gray-800 mb-4">Payment Successful!</h2>
            <p class="text-gray-600 mb-8 leading-relaxed">
              Your payment for
              <strong>
                {get_success_message(@action_to_perform)}
              </strong>
              has been processed successfully.
            </p>

            <a
              href={@return_url}
              class="inline-block px-5 py-3 bg-blue-500 text-white font-medium rounded-md hover:bg-blue-600 transition-colors"
            >
              {get_back_message(@action_to_perform)}
            </a>
          </div>
        <% else %>
          <div class="w-[60%] bg-white rounded-lg shadow-md p-8 text-center">
            <p
              :if={@payment_error}
              class="bg-red-200 my-4 text-red-500 flex justify-between items-center rounded-md p-2 w-[100%]"
            >
              <span class="w-[90%]">
                {@payment_error}
              </span>
              <span
                phx-click="clear_payment_error"
                class="w-[10%] cursor-pointer flex justify-end items-center"
              >
                <Heroicons.icon name="x-mark" type="outline" class="h-4 w-4 text-darkblue" />
              </span>
            </p>
            <div class="mx-auto mb-8 w-20 h-20 bg-red-500 rounded-full relative">
              <div class="absolute top-1/2 left-1/2 w-10 h-1 bg-white transform -translate-x-1/2 -translate-y-1/2 rotate-45">
              </div>
              <div class="absolute top-1/2 left-1/2 w-10 h-1 bg-white transform -translate-x-1/2 -translate-y-1/2 -rotate-45">
              </div>
            </div>

            <h2 class="text-2xl font-semibold text-gray-800 mb-4">Payment Failed</h2>
            <p class="text-gray-600 mb-8 leading-relaxed">
              We couldn't process your payment. The reason is {@mpesa_error}.
            </p>

            <div class="space-x-2">
              <button
                class="inline-block px-5 py-3 bg-blue-500 text-white font-medium rounded-md hover:bg-blue-600 transition-colors"
                phx-click="retry_payment"
                phx-disable-with="Retrying..."
              >
                Retry Payment
              </button>
              <a
                href={@return_url}
                class="inline-block px-5 py-3 bg-gray-500 text-white font-medium rounded-md hover:bg-gray-600 transition-colors"
              >
                {get_back_message(@action_to_perform)}
              </a>
            </div>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp get_back_message("create_lab_result") do
    "Back to Lab Result"
  end

  defp get_back_message("create_wallet_deposit") do
    "Back to Wallet Deposits"
  end

  defp get_back_message("create_admission_request") do
    "Back to Admitting Patient"
  end

  defp get_back_message("admission_line_item") do
    "Back to Line items"
  end

  defp get_back_message("create_drug_allocation") do
    "Back to Drug Allocation"
  end

  defp get_back_message("create_radiology_result") do
    "Back to Radiology Test"
  end

  defp get_back_message("create_room_allocation") do
    "Back to Room Allocation"
  end

  defp get_back_message("create_patient_visit") do
    "Back to Patient Visit"
  end

  defp get_back_message("create_patient_visit_for_triage") do
    "Back to Patient Visit"
  end

  defp get_back_message("create_patient_visit_subsidized") do
    "Back to Patient Visit"
  end

  defp get_back_message("create_nurse_procedure") do
    "Back to Nurse Procedure"
  end

  defp get_back_message("create_doctor_procedure") do
    "Back to Doctor Procedure"
  end

  defp get_back_message("patient_charge_batch") do
    "Back to Emergency Charges"
  end

  defp get_success_message("create_lab_result") do
    "A Lab Result"
  end

  defp get_success_message("create_wallet_deposit") do
    "A Wallet Deposit"
  end

  defp get_success_message("create_admission_request") do
    "A Patient Admission Request"
  end

  defp get_success_message("admission_line_item") do
    "Admission line item"
  end

  defp get_success_message("create_drug_allocation") do
    "A Drug Allocation"
  end

  defp get_success_message("create_room_allocation") do
    "A Room Allocation"
  end

  defp get_success_message("create_nurse_procedure") do
    "A Nurse Procedure"
  end

  defp get_success_message("create_doctor_procedure") do
    "A Doctor Procedure"
  end

  defp get_success_message("create_radiology_result") do
    "A Radiology Result"
  end

  defp get_success_message("patient_charge_batch") do
    "Emergency Nursing Charges"
  end

  defp get_success_message(nil) do
    "A Room Allocation"
  end

  defp get_success_message("create_patient_visit") do
    "A Patient Visit"
  end

  defp get_success_message("create_patient_visit_for_triage") do
    "A Patient Visit"
  end

  defp get_success_message("create_patient_visit_subsidized") do
    "Subsidized Doctor Consultation for Students"
  end
end
