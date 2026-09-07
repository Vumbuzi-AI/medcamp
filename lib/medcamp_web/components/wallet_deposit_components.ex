defmodule MedcampWeb.WalletDepositComponents do
  use Phoenix.Component
  use Gettext, backend: MedcampWeb.Gettext

  alias Phoenix.LiveView.JS
  import MedcampWeb.CoreComponents

  def wallet_deposits_header(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-6 mb-6">
      <.header class="text-[#373896] border-b border-gray-100 pb-4 mb-4">
        <div class="flex items-center">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-6 w-6 mr-3 text-[#6667ab]"
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
            <h1 class="text-2xl font-bold text-[#373896]">Wallet Deposits</h1>
            <p class="text-gray-600 mt-1">Manage patient wallet deposits and track usage</p>
          </div>
        </div>
        <:actions>
          <.link patch={"/reception/#{@patient.id}/wallet_deposits/trigger_payment"}>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">
              <div class="flex items-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-2"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 4v16m8-8H4"
                  />
                </svg>
                New Deposit
              </div>
            </.button>
          </.link>
        </:actions>
      </.header>

      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div class="bg-gradient-to-r from-blue-50 to-blue-100 p-4 rounded-lg border border-blue-200">
          <div class="flex items-center">
            <div class="p-2 bg-blue-500 rounded-lg">
              <svg class="h-6 w-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1"
                />
              </svg>
            </div>
            <div class="ml-3">
              <p class="text-sm font-medium text-blue-800">Total Deposits</p>
              <p class="text-lg font-bold text-blue-900">
                KES {format_currency(@statistics.total_deposits)}
              </p>
            </div>
          </div>
        </div>

        <div class="bg-gradient-to-r from-green-50 to-green-100 p-4 rounded-lg border border-green-200">
          <div class="flex items-center">
            <div class="p-2 bg-green-500 rounded-lg">
              <svg class="h-6 w-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            <div class="ml-3">
              <p class="text-sm font-medium text-green-800">Available Balance</p>
              <p class="text-lg font-bold text-green-900">
                KES {format_currency(@statistics.available_balance)}
              </p>
            </div>
          </div>
        </div>

        <div class="bg-gradient-to-r from-orange-50 to-orange-100 p-4 rounded-lg border border-orange-200">
          <div class="flex items-center">
            <div class="p-2 bg-orange-500 rounded-lg">
              <svg class="h-6 w-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M13 17h8m0 0V9m0 8l-8-8-4 4-6-6"
                />
              </svg>
            </div>
            <div class="ml-3">
              <p class="text-sm font-medium text-orange-800">Total Used</p>
              <p class="text-lg font-bold text-orange-900">
                KES {format_currency(@statistics.total_used)}
              </p>
            </div>
          </div>
        </div>

        <div class="bg-gradient-to-r from-slate-50 to-purple-100 p-4 rounded-lg border border-purple-200">
          <div class="flex items-center">
            <div class="p-2 bg-slate-500 rounded-lg">
              <svg class="h-6 w-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
                />
              </svg>
            </div>
            <div class="ml-3">
              <p class="text-sm font-medium text-purple-800">Active Wallets</p>
              <p class="text-lg font-bold text-purple-900">{@statistics.active_wallets}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, default: nil
  attr :streams, :map, required: true
  attr :patient, :map, required: true
  attr :count, :integer, required: true

  def wallet_deposits_table(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-6">
      <.blank_state
        :if={@count == 0}
        icon_path="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
        title="No wallet deposits found"
        description="This patient has no wallet deposits recorded yet."
      />

      <.table
        :if={@count > 0}
        id="wallet_deposits"
        rows={@wallet_deposits}
        row_click={
          fn deposit ->
            JS.navigate("/reception/#{@patient.id}/wallet_deposits/#{deposit.id}")
          end
        }
        row_id={&"wallet_deposits-#{&1.id}"}
      >
        <:col :let={deposit} label="Patient">
          <div class="flex items-center py-3">
            <div class="flex-shrink-0 h-10 w-10">
              <div class="h-10 w-10 rounded-full bg-[#e7e7ff] flex items-center justify-center">
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
            </div>
            <div class="ml-4">
              <div class="text-sm font-medium text-gray-900">
                {[
                  deposit.patient.first_name,
                  deposit.patient.middle_name,
                  deposit.patient.last_name
                ]
                |> Enum.filter(&(&1 != nil))
                |> Enum.join(" ")}
              </div>
              <div class="text-sm text-gray-500">{deposit.patient.gsrn}</div>
            </div>
          </div>
        </:col>

        <:col :let={deposit} label="Phone Number">
          <div class="flex items-center py-3">
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
                d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"
              />
            </svg>
            <span class="text-gray-700">{deposit.phone_number}</span>
          </div>
        </:col>

        <:col :let={deposit} label="Amount Deposited">
          <div class="py-3">
            <span class="px-3 py-1 text-sm font-semibold rounded-full bg-green-100 text-green-800">
              KES {format_currency(deposit.amount)}
            </span>
          </div>
        </:col>

        <:col :let={deposit} label="Amount Used">
          <div class="py-3">
            <span class="px-3 py-1 text-sm font-semibold rounded-full bg-orange-100 text-orange-800">
              KES {format_currency(deposit.amount_used)}
            </span>
          </div>
        </:col>

        <:col :let={deposit} label="Balance">
          <div class="py-3">
            <% balance = deposit.amount - (deposit.amount_used || 0) %>
            <span class={"px-3 py-1 text-sm font-semibold rounded-full " <>
                  if(balance > 0, do: "bg-blue-100 text-blue-800", else: "bg-red-100 text-red-800")}>
              KES {format_currency(balance)}
            </span>
          </div>
        </:col>
        <:col :let={deposit} label="Status">
          <div class="py-3">
            <% balance = deposit.amount - (deposit.amount_used || 0) %>
            <% status = get_balance_status(balance, deposit.amount) %>
            <span class={"px-2 py-1 text-xs rounded-full font-medium " <> status.class}>
              {status.text}
            </span>
          </div>
        </:col>

        <:col :let={deposit} label="Date">
          <div class="flex items-center py-3">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-4 w-4 mr-1 text-[#6667ab]"
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
            <span class="text-gray-700">
              <%= if deposit.inserted_at do %>
                {Calendar.strftime(deposit.inserted_at, "%Y-%m-%d")}
              <% else %>
                N/A
              <% end %>
            </span>
          </div>
        </:col>
      </.table>
    </div>
    """
  end

  defp format_currency(amount) when is_integer(amount) do
    Number.Delimit.number_to_delimited(amount, delimiter: ",")
  end

  defp format_currency(nil), do: "0"

  defp get_balance_status(balance, total_amount) do
    cond do
      balance <= 0 ->
        %{class: "bg-red-100 text-red-800", text: "Depleted"}

      balance < total_amount * 0.2 ->
        %{class: "bg-yellow-100 text-yellow-800", text: "Low Balance"}

      true ->
        %{class: "bg-green-100 text-green-800", text: "Active"}
    end
  end
end
