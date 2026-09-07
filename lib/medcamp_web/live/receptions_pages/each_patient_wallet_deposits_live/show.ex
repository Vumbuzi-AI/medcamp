defmodule MedcampWeb.ReceptionsPagePatientLive.EachPatientWalletDepositsShow do
  alias Medcamp.Patients
  use MedcampWeb, :reception_each_patient_live_view

  alias Medcamp.WalletDeposits
  alias Medcamp.Patients
  alias Medcamp.WalletWithdrawals

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :wallet_deposits)}
  end

  @impl true
  def handle_params(%{"wallet_deposit_id" => id, "patient_id" => patient_id}, _, socket) do
    deposit = get_wallet_deposit_with_usage(id)
    withdrawals = list_withdrawals_for_deposit(id)

    patient = Patients.get_patient!(patient_id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:wallet_deposit, deposit)
     |> assign(:patient, patient)
     |> assign(:withdrawals, withdrawals)
     |> stream(:withdrawals, withdrawals)}
  end

  @impl true
  def handle_event("delete_withdrawal", %{"id" => id}, socket) do
    withdrawal = WalletWithdrawals.get_wallet_withdrawal!(id)
    {:ok, _} = WalletWithdrawals.delete_wallet_withdrawal(withdrawal)

    # Refresh the deposit and withdrawals
    deposit = get_wallet_deposit_with_usage(socket.assigns.wallet_deposit.id)
    withdrawals = list_withdrawals_for_deposit(socket.assigns.wallet_deposit.id)

    {:noreply,
     socket
     |> assign(:wallet_deposit, deposit)
     |> assign(:withdrawals, withdrawals)
     |> stream(:withdrawals, withdrawals, reset: true)
     |> put_flash(:info, "Withdrawal deleted successfully")}
  end

  defp page_title(:show), do: "Wallet Deposit Details"
  defp page_title(:edit), do: "Edit Wallet Deposit"

  defp get_wallet_deposit_with_usage(id) do
    import Ecto.Query

    # Get the deposit with patient
    deposit = WalletDeposits.get_wallet_deposit!(id)

    # Get usage amount for this deposit
    amount_used =
      from(w in WalletWithdrawals.WalletWithdrawal,
        where: w.wallet_deposit_id == ^id,
        select: coalesce(sum(w.amount), 0)
      )
      |> Medcamp.Repo.one() || 0

    %{
      id: deposit.id,
      phone_number: deposit.phone_number,
      amount: deposit.amount,
      reason: deposit.reason,
      patient: deposit.patient,
      inserted_at: deposit.inserted_at,
      updated_at: deposit.updated_at,
      amount_used: amount_used,
      balance: deposit.amount - amount_used
    }
  end

  defp list_withdrawals_for_deposit(deposit_id) do
    import Ecto.Query

    from(w in WalletWithdrawals.WalletWithdrawal,
      where: w.wallet_deposit_id == ^deposit_id,
      preload: [:patient],
      order_by: [desc: w.date, desc: w.inserted_at]
    )
    |> Medcamp.Repo.all()
  end

  defp format_currency(amount) when is_integer(amount) do
    Number.Delimit.number_to_delimited(amount, delimiter: ",")
  end

  defp format_currency(nil), do: "0"

  defp calculate_usage_percentage(amount, amount_used) when is_integer(amount) and amount > 0 do
    round((amount_used || 0) / amount * 100)
  end

  defp calculate_usage_percentage(_, _), do: 0

  defp get_balance_status(balance, total_amount) do
    cond do
      balance <= 0 ->
        %{
          class: "bg-red-100 text-red-800 border-red-200",
          text: "Depleted",
          icon_color: "text-red-500"
        }

      balance < total_amount * 0.2 ->
        %{
          class: "bg-yellow-100 text-yellow-800 border-yellow-200",
          text: "Low Balance",
          icon_color: "text-yellow-500"
        }

      true ->
        %{
          class: "bg-green-100 text-green-800 border-green-200",
          text: "Active",
          icon_color: "text-green-500"
        }
    end
  end

  defp get_progress_color(percentage) do
    cond do
      percentage < 50 -> "bg-green-500"
      percentage < 80 -> "bg-yellow-500"
      true -> "bg-red-500"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-gray-50 min-h-screen">
      <div class="container mx-auto px-4 py-6">
        <div class="mb-6">
          <div class="flex items-center justify-between">
            <div class="flex items-center">
              <.link navigate="/wallet_deposits" class="mr-4 text-[#6667ab] hover:text-[#373896]">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-6 w-6"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M10 19l-7-7m0 0l7-7m-7 7h18"
                  />
                </svg>
              </.link>
              <div>
                <h1 class="text-2xl font-bold text-[#373896]">Wallet Deposit Details</h1>
                <p class="text-gray-600 mt-1">
                  {[
                    @wallet_deposit.patient.first_name,
                    @wallet_deposit.patient.middle_name,
                    @wallet_deposit.patient.last_name
                  ]
                  |> Enum.filter(&(&1 != nil))
                  |> Enum.join(" ")}
                </p>
              </div>
            </div>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-6">
            <div class="flex items-center">
              <div class="p-3 bg-blue-100 rounded-lg">
                <svg
                  class="h-6 w-6 text-blue-600"
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
              </div>
              <div class="ml-4">
                <p class="text-sm font-medium text-gray-600">Original Deposit</p>
                <p class="text-2xl font-bold text-gray-900">
                  KES {format_currency(@wallet_deposit.amount)}
                </p>
              </div>
            </div>
          </div>

          <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-6">
            <div class="flex items-center">
              <div class="p-3 bg-orange-100 rounded-lg">
                <svg
                  class="h-6 w-6 text-orange-600"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M13 17h8m0 0V9m0 8l-8-8-4 4-6-6"
                  />
                </svg>
              </div>
              <div class="ml-4">
                <p class="text-sm font-medium text-gray-600">Amount Used</p>
                <p class="text-2xl font-bold text-gray-900">
                  KES {format_currency(@wallet_deposit.amount_used)}
                </p>
              </div>
            </div>
          </div>

          <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-6">
            <div class="flex items-center">
              <div class="p-3 bg-green-100 rounded-lg">
                <svg
                  class="h-6 w-6 text-green-600"
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
              </div>
              <div class="ml-4">
                <p class="text-sm font-medium text-gray-600">Current Balance</p>
                <p class="text-2xl font-bold text-gray-900">
                  KES {format_currency(@wallet_deposit.balance)}
                </p>
              </div>
            </div>
          </div>
          
    <!-- Status -->
          <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-6">
            <% status = get_balance_status(@wallet_deposit.balance, @wallet_deposit.amount) %>
            <div class="flex items-center">
              <div class={"p-3 rounded-lg " <> status.class}>
                <svg
                  class={"h-6 w-6 " <> status.icon_color}
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
              </div>
              <div class="ml-4">
                <p class="text-sm font-medium text-gray-600">Status</p>
                <p class="text-lg font-bold text-gray-900">{status.text}</p>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Deposit Information -->
        <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-6 mb-8">
          <div class="border-b border-gray-100 pb-4 mb-6">
            <h2 class="text-xl font-semibold text-[#373896] flex items-center">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5 mr-2 text-[#6667ab]"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              Deposit Information
            </h2>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Patient Information
                </label>
                <div class="flex items-center p-3 bg-gray-50 rounded-lg">
                  <div class="h-10 w-10 rounded-full bg-[#e7e7ff] flex items-center justify-center mr-3">
                    <svg
                      class="h-6 w-6 text-[#6667ab]"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                      />
                    </svg>
                  </div>
                  <div>
                    <p class="font-medium text-gray-900">
                      {[
                        @wallet_deposit.patient.first_name,
                        @wallet_deposit.patient.middle_name,
                        @wallet_deposit.patient.last_name
                      ]
                      |> Enum.filter(&(&1 != nil))
                      |> Enum.join(" ")}
                    </p>
                    <p class="text-sm text-gray-500">Patient GSRN: {@wallet_deposit.patient.gsrn}</p>
                  </div>
                </div>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Phone Number</label>
                <div class="flex items-center p-3 bg-gray-50 rounded-lg">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-5 w-5 mr-2 text-[#6667ab]"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"
                    />
                  </svg>
                  <span class="text-gray-900">{@wallet_deposit.phone_number}</span>
                </div>
              </div>
            </div>

            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Deposit Date</label>
                <div class="flex items-center p-3 bg-gray-50 rounded-lg">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-5 w-5 mr-2 text-[#6667ab]"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                    />
                  </svg>
                  <span class="text-gray-900">
                    {Calendar.strftime(@wallet_deposit.inserted_at, "%B %d, %Y at %I:%M %p")}
                  </span>
                </div>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Usage Progress</label>
                <div class="p-3 bg-gray-50 rounded-lg">
                  <% usage_percentage =
                    calculate_usage_percentage(@wallet_deposit.amount, @wallet_deposit.amount_used) %>
                  <div class="flex items-center justify-between mb-2">
                    <span class="text-sm text-gray-600">{usage_percentage}% Used</span>
                    <span class="text-sm text-gray-600">{100 - usage_percentage}% Remaining</span>
                  </div>
                  <div class="w-full bg-gray-200 rounded-full h-3">
                    <div
                      class={"h-3 rounded-full transition-all duration-300 " <> get_progress_color(usage_percentage)}
                      style={"width: #{usage_percentage}%"}
                    >
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="mt-6">
            <label class="block text-sm font-medium text-gray-700 mb-2">Reason for Deposit</label>
            <div class="p-4 bg-gray-50 rounded-lg">
              <p class="text-gray-900">{@wallet_deposit.reason}</p>
            </div>
          </div>
        </div>
        
    <!-- Withdrawals History -->
        <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-6">
          <div class="border-b border-gray-100 pb-4 mb-6">
            <div class="flex items-center justify-between">
              <h2 class="text-xl font-semibold text-[#373896] flex items-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5 mr-2 text-[#6667ab]"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"
                  />
                </svg>
                Withdrawal History
                <span class="ml-2 text-sm font-normal text-gray-500">
                  ({length(@withdrawals)} withdrawals)
                </span>
              </h2>
            </div>
          </div>

          <%= if length(@withdrawals) > 0 do %>
            <.table id="withdrawals" rows={@streams.withdrawals}>
              <:col :let={{_id, withdrawal}} label="Date">
                <div class="flex items-center py-2">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-4 w-4 mr-2 text-[#6667ab]"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                    />
                  </svg>
                  <span class="text-gray-700">{Calendar.strftime(withdrawal.date, "%Y-%m-%d")}</span>
                </div>
              </:col>

              <:col :let={{_id, withdrawal}} label="Amount">
                <div class="py-2">
                  <span class="px-3 py-1 text-sm font-semibold rounded-full bg-red-100 text-red-800">
                    -KES {format_currency(withdrawal.amount)}
                  </span>
                </div>
              </:col>

              <:col :let={{_id, withdrawal}} label="Reason">
                <div class="py-2 max-w-xs">
                  <p class="text-gray-700 truncate" title={withdrawal.reason}>
                    {withdrawal.reason}
                  </p>
                </div>
              </:col>

              <:col :let={{_id, withdrawal}} label="Created">
                <div class="py-2">
                  <span class="text-sm text-gray-500">
                    {Calendar.strftime(withdrawal.inserted_at, "%b %d, %Y")}
                  </span>
                </div>
              </:col>
            </.table>
          <% else %>
            <div class="text-center py-12">
              <svg
                class="mx-auto h-12 w-12 text-gray-400"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 6h6m-6 4h6"
                />
              </svg>
              <h3 class="mt-4 text-lg font-medium text-gray-900">No withdrawals yet</h3>
              <p class="mt-2 text-gray-500">This wallet deposit hasn't been used yet.</p>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
