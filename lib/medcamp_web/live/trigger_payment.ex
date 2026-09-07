defmodule MedcampWeb.TriggerPayment do
  use MedcampWeb, :live_component

  alias Medcamp.Mpesas
  alias Medcamp.Mpesas.Mpesa
  alias Medcamp.Pay
  alias Medcamp.Costings
  alias Medcamp.WalletDeposits
  alias Medcamp.WalletWithdrawals
  alias Medcamp.AdmissionRequests

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Add Patient Details and Choose Payment Method
      </.header>

      <p
        :if={@payment_error}
        class="bg-red-200 text-red-500 flex justify-between items-center rounded-md p-2 w-[100%] mb-4"
      >
        <span class="w-[90%]">
          {@payment_error}
        </span>
        <span
          phx-click="clear_payment_error"
          phx-target={@myself}
          class="w-[10%] cursor-pointer flex justify-end items-center"
        >
          <Heroicons.icon name="x-mark" type="outline" class="h-4 w-4 text-darkblue" />
        </span>
      </p>
      
    <!-- Wallet Summary -->
      <%= if @available_wallets != [] do %>
        <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
          <div class="flex items-center mb-3">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5 mr-2 text-blue-600"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1"
              />
            </svg>
            <h3 class="text-lg font-semibold text-blue-800">Available Wallet Balance</h3>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
            <div class="bg-white p-3 rounded border">
              <p class="text-sm text-gray-600">Total Available</p>
              <p class="text-xl font-bold text-green-600">
                KES {format_currency(@total_wallet_balance)}
              </p>
            </div>
            <div class="bg-white p-3 rounded border">
              <p class="text-sm text-gray-600">Required Amount</p>
              <p class="text-xl font-bold text-blue-600">KES {format_currency(@required_amount)}</p>
            </div>
            <div class="bg-white p-3 rounded border">
              <p class="text-sm text-gray-600">After Payment</p>
              <p class={"text-xl font-bold " <> if(@total_wallet_balance >= @required_amount, do: "text-green-600", else: "text-red-600")}>
                KES {format_currency(@total_wallet_balance - @required_amount)}
              </p>
            </div>
          </div>

          <%= if @total_wallet_balance >= @required_amount do %>
            <div class="bg-green-100 border border-green-200 rounded p-3 mb-4">
              <div class="flex items-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5 mr-2 text-green-600"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
                <span class="text-green-800 font-medium">Sufficient wallet balance available!</span>
              </div>
            </div>
          <% else %>
            <div class="bg-yellow-100 border border-yellow-200 rounded p-3 mb-4">
              <div class="flex items-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5 mr-2 text-yellow-600"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.98-.833-2.75 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"
                  />
                </svg>
                <span class="text-yellow-800 font-medium">
                  Insufficient wallet balance. Please use M-Pesa payment.
                </span>
              </div>
            </div>
          <% end %>
        </div>
        
    <!-- Payment Method Selection -->
        <div class="bg-white border border-gray-200 rounded-lg p-4 mb-6">
          <h3 class="text-lg font-semibold text-gray-800 mb-4">Choose Payment Method</h3>

          <div class="space-y-3">
            <!-- Wallet Payment Option - Only show if sufficient balance -->
            <%= if @total_wallet_balance >= @required_amount do %>
              <label class="flex items-center p-3 border rounded-lg cursor-pointer hover:bg-gray-50 transition-colors">
                <input
                  type="radio"
                  name="payment_method"
                  value="wallet"
                  phx-click="select_payment_method"
                  phx-value-method="wallet"
                  phx-target={@myself}
                  checked={@selected_payment_method == "wallet"}
                  class="mr-3"
                />
                <div class="flex items-center">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-5 w-5 mr-2 text-blue-600"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1"
                    />
                  </svg>
                  <div>
                    <p class="font-medium text-gray-900">Pay from Wallet</p>
                    <p class="text-sm text-gray-600">
                      Use available wallet balance (KES {format_currency(@total_wallet_balance)})
                    </p>
                  </div>
                </div>
              </label>
            <% end %>
            
    <!-- M-Pesa Payment Option -->
            <label class="flex items-center p-3 border rounded-lg cursor-pointer hover:bg-gray-50 transition-colors">
              <input
                type="radio"
                name="payment_method"
                value="mpesa"
                phx-click="select_payment_method"
                phx-value-method="mpesa"
                phx-target={@myself}
                checked={@selected_payment_method == "mpesa"}
                class="mr-3"
              />
              <div class="flex items-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5 mr-2 text-green-600"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"
                  />
                </svg>
                <div>
                  <p class="font-medium text-gray-900">M-Pesa Payment</p>
                  <p class="text-sm text-gray-600">
                    Pay full amount via M-Pesa (KES {format_currency(@required_amount)})
                  </p>
                </div>
              </div>
            </label>
          </div>
        </div>
      <% end %>
      
    <!-- Payment Form -->
      <.simple_form
        for={@form}
        id="patient_visit-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.phone_number_input
          field={@form[:formatted_phone_number]}
          type="number"
          class="w-[100%]"
          required={@selected_payment_method == "mpesa"}
          value={@formatted_patient_number}
        />
        
    <!-- Amount display based on payment method -->
        <%= case @selected_payment_method do %>
          <% "wallet" -> %>
            <.input
              field={@form[:amount]}
              type="number"
              label="Amount (Wallet Payment)"
              value={@required_amount}
              readonly={true}
              class="bg-blue-50"
            />
          <% "mpesa" -> %>
            <.input
              field={@form[:amount]}
              type="number"
              label="Amount (M-Pesa Payment)"
              value={@required_amount}
              readonly={@initial_price != nil}
            />
          <% _ -> %>
            <.input
              field={@form[:amount]}
              type="number"
              label="Amount"
              value={@required_amount}
              readonly={@initial_price != nil}
            />
        <% end %>

        <:actions>
          <%= if @form.source.valid? == false or @selected_payment_method == nil do %>
            <.button class="cursor-not-allowed bg-gray-400" disabled>
              {get_button_text(@selected_payment_method)}
            </.button>
          <% else %>
            <.button phx-disable-with="Processing..." class="bg-[#6667ab] hover:bg-[#5556a0]">
              {get_button_text(@selected_payment_method)}
            </.button>
          <% end %>
        </:actions>
      </.simple_form>
      
    <!-- Wallet Usage Preview -->
      <%= if @selected_payment_method == "wallet" and @wallet_usage_plan != [] do %>
        <div class="mt-6 bg-gray-50 border border-gray-200 rounded-lg p-4">
          <h4 class="font-medium text-gray-800 mb-3">Wallet Usage Plan:</h4>
          <div class="space-y-2">
            <%= for {wallet, amount} <- @wallet_usage_plan do %>
              <div class="flex justify-between items-center text-sm">
                <span class="text-gray-600">
                  Deposit from {Calendar.strftime(wallet.inserted_at, "%b %d, %Y")}
                </span>
                <span class="font-medium text-red-600">
                  -KES {format_currency(amount)}
                </span>
              </div>
            <% end %>
          </div>
          <div class="border-t pt-2 mt-2">
            <div class="flex justify-between items-center font-medium">
              <span>Total from Wallet:</span>
              <span class="text-red-600">
                -KES {format_currency(@wallet_usage_plan |> Enum.map(&elem(&1, 1)) |> Enum.sum())}
              </span>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    initial_price = get_initial_price(assigns.action_to_perform, assigns.actionable_type)
    available_wallets = get_available_wallets(assigns.patient_id)
    total_wallet_balance = calculate_total_balance(available_wallets)

    default_payment_method =
      if total_wallet_balance >= initial_price do
        "wallet"
      else
        "mpesa"
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:initial_price, initial_price)
     |> assign(:required_amount, initial_price || 0)
     |> assign(:payment_error, nil)
     |> assign(:mpesa, %Mpesa{})
     |> assign(:formatted_patient_number, assigns.patient.phone_number |> String.slice(1..-1//-1))
     |> assign(:available_wallets, available_wallets)
     |> assign(:total_wallet_balance, total_wallet_balance)
     |> assign(:selected_payment_method, default_payment_method)
     |> assign(:wallet_usage_plan, [])
     |> calculate_wallet_usage_plan()
     |> assign_new(:form, fn ->
       to_form(
         Mpesas.change_trigger_mpesa(%Mpesa{}, %{
           "amount" => initial_price,
           "formatted_phone_number" => assigns.patient.phone_number |> String.slice(1..-1//-1)
         }),
         action: :validate
       )
     end)}
  end

  defp get_initial_price(action_to_perform, actionable_type) do
    case action_to_perform do
      "create_nurse_procedure" ->
        actionable_type.procedure.price

      "create_doctor_procedure" ->
        actionable_type.procedure.price

      "create_patient_visit" ->
        actionable_type.total_amount_paid || Costings.get_costings_by_type("Consultation").price

      "create_patient_visit_for_triage" ->
        actionable_type.total_amount_paid || Costings.get_costings_by_type("Triage Only").price

      "create_patient_visit_subsidized" ->
        actionable_type.total_amount_paid || 350

      "create_admission_request" ->
        total = AdmissionRequests.total_line_items_amount(actionable_type.id)
        if total > 0, do: total, else: nil

      "admission_line_item" ->
        unpaid = AdmissionRequests.LineItem.amount_unpaid(actionable_type)
        if unpaid > 0, do: unpaid, else: nil

      "patient_charge_batch" ->
        actionable_type.total_amount

      _ ->
        nil
    end
  end

  defp get_available_wallets(patient_id) do
    import Ecto.Query

    # Get all wallet deposits for the patient with current usage
    deposits =
      from(d in WalletDeposits.WalletDeposit,
        where: d.patient_id == ^patient_id,
        preload: [:patient],
        # Use older deposits first
        order_by: [asc: d.inserted_at]
      )
      |> Medcamp.Repo.all()

    # Calculate balance for each deposit
    deposits
    |> Enum.map(fn deposit ->
      amount_used =
        from(w in WalletWithdrawals.WalletWithdrawal,
          where: w.wallet_deposit_id == ^deposit.id,
          select: coalesce(sum(w.amount), 0)
        )
        |> Medcamp.Repo.one() || 0

      balance = deposit.amount - amount_used

      Map.merge(deposit, %{
        amount_used: amount_used,
        balance: balance
      })
    end)
    # Only deposits with remaining balance
    |> Enum.filter(fn deposit -> deposit.balance > 0 end)
  end

  defp calculate_total_balance(wallets) do
    wallets
    |> Enum.map(& &1.balance)
    |> Enum.sum()
  end

  defp calculate_wallet_usage_plan(socket) do
    if socket.assigns.selected_payment_method == "wallet" do
      plan =
        distribute_amount_across_wallets(
          socket.assigns.available_wallets,
          socket.assigns.required_amount
        )

      assign(socket, :wallet_usage_plan, plan)
    else
      assign(socket, :wallet_usage_plan, [])
    end
  end

  defp distribute_amount_across_wallets(wallets, amount_needed) do
    wallets
    # Use oldest first
    |> Enum.sort_by(& &1.inserted_at)
    |> Enum.reduce({[], amount_needed}, fn wallet, {plan, remaining} ->
      if remaining <= 0 do
        {plan, remaining}
      else
        amount_to_use = min(wallet.balance, remaining)
        {[{wallet, amount_to_use} | plan], remaining - amount_to_use}
      end
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  defp format_currency(amount) when is_integer(amount) do
    Number.Delimit.number_to_delimited(amount, delimiter: ",")
  end

  defp format_currency(nil), do: "0"

  defp get_button_text(payment_method) do
    case payment_method do
      "wallet" -> "Pay from Wallet"
      "mpesa" -> "Trigger M-Pesa Payment"
      _ -> "Select Payment Method"
    end
  end

  defp format_action_for_reason(action, actionable_type) do
    case action do
      "create_nurse_procedure" ->
        "Payment for Nurse Procedure"

      "create_doctor_procedure" ->
        "Payment for Doctor Procedure"

      "create_patient_visit" ->
        "Payment for #{patient_visit_service_details(actionable_type)}"

      "create_patient_visit_for_triage" ->
        "Payment for Triage"

      "create_patient_visit_subsidized" ->
        "Payment for Subsidized Doctor Consultation for Students"

      "create_admission_request" ->
        "Payment for Hospital Admission"

      "admission_line_item" ->
        "Payment for Hospital Admission (line item)"

      "patient_charge_batch" ->
        "Payment for Emergency Nursing Charges"

      _ ->
        "Payment for Service"
    end
  end

  defp patient_visit_service_details(%{visit_type: "Full"}), do: "General Consultation"
  defp patient_visit_service_details(%{visit_type: nil}), do: "General Consultation"
  defp patient_visit_service_details(%{visit_type: ""}), do: "General Consultation"
  defp patient_visit_service_details(%{visit_type: visit_type}), do: visit_type
  defp patient_visit_service_details(_), do: "General Consultation"

  @impl true
  def handle_event("select_payment_method", %{"method" => method}, socket) do
    {:noreply,
     socket
     |> assign(:selected_payment_method, method)
     |> calculate_wallet_usage_plan()}
  end

  def handle_event("validate", %{"mpesa" => mpesa_params}, socket) do
    changeset = Mpesas.change_trigger_mpesa(socket.assigns.mpesa, mpesa_params)

    {:noreply,
     socket
     |> assign(:payment_error, nil)
     |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("clear_payment_error", _, socket) do
    {:noreply, assign(socket, payment_error: nil)}
  end

  def handle_event("save", %{"mpesa" => mpesa_params}, socket) do
    case socket.assigns.selected_payment_method do
      "wallet" ->
        process_wallet_payment(socket, mpesa_params)

      "mpesa" ->
        process_mpesa_payment(socket, mpesa_params)

      _ ->
        {:noreply, assign(socket, :payment_error, "Please select a payment method")}
    end
  end

  defp process_wallet_payment(socket, mpesa_params) do
    reason =
      format_action_for_reason(
        socket.assigns.action_to_perform,
        socket.assigns.actionable_type
      )

    case create_wallet_withdrawals(
           socket.assigns.wallet_usage_plan,
           socket.assigns.patient.id,
           reason
         ) do
      :ok ->
        raw =
          case (mpesa_params["formatted_phone_number"] || "") |> String.trim() do
            "" -> socket.assigns.patient.phone_number || ""
            s -> s
          end

        phone =
          cond do
            String.starts_with?(raw, "254") ->
              raw

            String.starts_with?(raw, "0") and byte_size(raw) >= 10 ->
              "254" <> String.slice(raw, 1..-1//1)

            byte_size(raw) >= 9 ->
              "254" <> raw

            true ->
              "254000000000"
          end

        case Mpesas.create_mpesa_for_wallet(%{
               "patient_id" => socket.assigns.patient_id,
               "prompter_id" => socket.assigns.current_user.id,
               "amount" => socket.assigns.required_amount,
               "phone" => phone,
               "actionable_type" => socket.assigns.action_to_perform,
               "actionable_id" => socket.assigns.actionable_type.id
             }) do
          {:ok, _mpesa} ->
            MedcampWeb.MpesaController.handle_after_action_for_wallet(
              socket.assigns.action_to_perform,
              socket.assigns.actionable_type.id,
              socket.assigns.initial_price
            )

            {:noreply,
             socket
             |> put_flash(:info, "Payment processed successfully from wallet")
             |> push_navigate(to: socket.assigns.return_url)}

          {:error, _changeset} ->
            MedcampWeb.MpesaController.handle_after_action_for_wallet(
              socket.assigns.action_to_perform,
              socket.assigns.actionable_type.id,
              socket.assigns.initial_price
            )

            {:noreply,
             socket
             |> put_flash(
               :warning,
               "Payment processed from wallet, but recording payment history failed"
             )
             |> push_navigate(to: socket.assigns.return_url)}
        end

      {:error, reason} ->
        {:noreply, assign(socket, :payment_error, "Failed to process wallet payment: #{reason}")}
    end
  end

  defp process_mpesa_payment(socket, mpesa_params) do
    phone_number = "254" <> mpesa_params["formatted_phone_number"]

    case Pay.make_request(mpesa_params["amount"], phone_number) do
      {:ok, params, 200} ->
        Mpesas.create_mpesa(%{
          "phone" => phone_number,
          "amount" => mpesa_params["amount"],
          "checkout_request_id" => params["CheckoutRequestID"],
          "merchant_request_id" => params["MerchantRequestID"],
          "actionable_id" => socket.assigns.actionable_type.id,
          "actionable_type" => socket.assigns.action_to_perform,
          "prompter_id" => socket.assigns.current_user.id,
          "patient_id" => socket.assigns.patient_id
        })

        {:noreply,
         socket
         |> put_flash(:info, "Payment triggered successfully")
         |> push_navigate(
           to:
             "/confirm?checkout_request_id=#{params["CheckoutRequestID"]}&return_url=#{socket.assigns.return_url}&action=#{socket.assigns.action_to_perform}"
         )}

      {:ok, params, _} ->
        {:noreply,
         assign(
           socket,
           :payment_error,
           "An error occurred while processing the payment, #{params["errorMessage"]}, please try again"
         )}

      {:error, "Request Timed Out"} ->
        {:noreply,
         assign(
           socket,
           :payment_error,
           "An error occurred while processing the payment, please try again"
         )}
    end
  end

  defp create_wallet_withdrawals(usage_plan, patient_id, reason) do
    try do
      Enum.each(usage_plan, fn {wallet, amount} ->
        case WalletWithdrawals.create_wallet_withdrawal(%{
               "wallet_deposit_id" => wallet.id,
               "patient_id" => patient_id,
               "amount" => amount,
               "reason" => reason,
               "date" => Date.utc_today()
             }) do
          {:ok, _} ->
            :ok

          {:error, changeset} ->
            throw({:error, "Validation failed: #{inspect(changeset.errors)}"})
        end
      end)

      :ok
    catch
      {:error, reason} -> {:error, reason}
    end
  end
end
