defmodule MedcampWeb.AdminPaymentsLive.Index do
  use MedcampWeb, :admin_live_view
  alias Medcamp.Mpesas

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :payments)
     |> assign(:view_mode, :data)
     |> assign(:prompter_filter, :active_only)
     |> assign(:analytics, compute_analytics())
     |> assign(:total_amount, Mpesas.total_successful_payments())
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:total_count, 0)
     |> assign(:total_pages, 0)
     |> assign(:search, "")
     |> assign_payments(1)}
  end

  @impl true
  def handle_event("search", %{"search" => query}, socket) do
    {:noreply,
     socket
     |> assign(:search, query)
     |> assign_payments(1)}
  end

  @impl true
  def handle_event("clear_search", _params, socket) do
    {:noreply,
     socket
     |> assign(:search, "")
     |> assign_payments(1)}
  end

  @impl true
  def handle_event("filter_prompters", %{"filter" => filter}, socket) do
    {:noreply, assign(socket, :prompter_filter, String.to_atom(filter))}
  end

  @impl true
  def handle_event("switch_view", %{"view" => view}, socket) do
    socket = assign(socket, :view_mode, String.to_atom(view))

    {:noreply,
     if socket.assigns.view_mode == :data do
       assign_payments(socket, socket.assigns.page)
     else
       socket
     end}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, assign_payments(socket, page)}
  end

  defp compute_analytics do
    payments = Mpesas.list_successful_payments()

    %{
      monthly_totals: compute_monthly_totals(payments),
      prompter_stats: compute_prompter_stats(payments),
      reason_stats: compute_reason_stats(payments),
      monthly_by_prompter: compute_monthly_by_prompter(payments),
      monthly_by_reason: compute_monthly_by_reason(payments)
    }
  end

  defp compute_monthly_totals(payments) do
    payments
    |> Enum.group_by(fn payment ->
      date = DateTime.shift_zone!(payment.inserted_at, "Africa/Nairobi")
      "#{date.year}-#{String.pad_leading(to_string(date.month), 2, "0")}"
    end)
    |> Enum.map(fn {month, month_payments} ->
      %{
        month: month,
        total: Enum.sum(Enum.map(month_payments, & &1.amount)),
        count: length(month_payments)
      }
    end)
    |> Enum.sort_by(& &1.month)
  end

  defp compute_prompter_stats(payments) do
    payments
    |> Enum.group_by(& &1.prompter.name)
    |> Enum.map(fn {name, prompter_payments} ->
      %{
        name: name,
        total: Enum.sum(Enum.map(prompter_payments, & &1.amount)),
        count: length(prompter_payments),
        is_active: List.first(prompter_payments).prompter.is_active
      }
    end)
    |> Enum.sort_by(& &1.total, :desc)
  end

  # Add this helper function
  defp filter_prompter_stats(prompter_stats, :active_only) do
    Enum.filter(prompter_stats, & &1.is_active)
  end

  defp filter_prompter_stats(prompter_stats, :all), do: prompter_stats

  defp assign_payments(socket, page) do
    page = normalize_page(page)
    search = socket.assigns.search
    total_count = Mpesas.count_successful_payments(search)
    total_pages = max(1, div(total_count + @per_page - 1, @per_page))
    page = min(page, total_pages)

    payments = Mpesas.list_successful_payments_paginated(page, @per_page, search)

    socket
    |> assign(:page, page)
    |> assign(:per_page, @per_page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:payments, payments)
  end

  defp normalize_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {value, _} when value > 0 -> value
      _ -> 1
    end
  end

  defp normalize_page(page) when is_integer(page) and page > 0, do: page
  defp normalize_page(_), do: 1

  defp compute_reason_stats(payments) do
    payments
    |> Enum.group_by(& &1.actionable_type)
    |> Enum.map(fn {reason, reason_payments} ->
      %{
        reason: reason,
        total: Enum.sum(Enum.map(reason_payments, & &1.amount)),
        count: length(reason_payments)
      }
    end)
    |> Enum.sort_by(& &1.total, :desc)
  end

  defp compute_monthly_by_prompter(payments) do
    payments
    |> Enum.group_by(fn payment ->
      date = DateTime.shift_zone!(payment.inserted_at, "Africa/Nairobi")
      {"#{date.year}-#{String.pad_leading(to_string(date.month), 2, "0")}", payment.prompter.name}
    end)
    |> Enum.map(fn {{month, prompter}, month_payments} ->
      %{
        month: month,
        prompter: prompter,
        total: Enum.sum(Enum.map(month_payments, & &1.amount)),
        count: length(month_payments)
      }
    end)
    |> Enum.sort_by(& &1.month)
  end

  defp compute_monthly_by_reason(payments) do
    payments
    |> Enum.group_by(fn payment ->
      date = DateTime.shift_zone!(payment.inserted_at, "Africa/Nairobi")

      {"#{date.year}-#{String.pad_leading(to_string(date.month), 2, "0")}",
       payment.actionable_type}
    end)
    |> Enum.map(fn {{month, reason}, month_payments} ->
      %{
        month: month,
        reason: reason,
        total: Enum.sum(Enum.map(month_payments, & &1.amount)),
        count: length(month_payments)
      }
    end)
    |> Enum.sort_by(& &1.month)
  end

  @impl true
  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="w-full">
      <div class="mb-6">
        <.page_header
          icon_path="M9 14l6-6m-5.5.5h.01m4.99 5h.01M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h14a2 2 0 012 2v14a2 2 0 01-2 2z"
          title="Payment Management Dashboard"
          subtitle={"Total: #{@total_amount} KES /="}
        />
        
    <!-- View Mode Tabs -->
        <div class="mt-6 border-b border-gray-200">
          <nav class="-mb-px flex space-x-8">
            <button
              phx-click="switch_view"
              phx-value-view="data"
              class={[
                "py-4 px-1 border-b-2 font-medium text-sm",
                if(@view_mode == :data,
                  do: "border-[#6667ab] text-[#373896]",
                  else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
                )
              ]}
            >
              Payment Data
            </button>
            <button
              phx-click="switch_view"
              phx-value-view="analysis"
              class={[
                "py-4 px-1 border-b-2 font-medium text-sm",
                if(@view_mode == :analysis,
                  do: "border-[#6667ab] text-[#373896]",
                  else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
                )
              ]}
            >
              Analytics Dashboard
            </button>
          </nav>
        </div>
      </div>
      
    <!-- Data View -->
      <div :if={@view_mode == :data}>
        <div class="mb-4 flex items-center gap-3">
          <form phx-change="search" class="flex-1">
            <.search_input
              name="search"
              value={@search}
              placeholder="Search by patient name, account number, or receipt"
            />
          </form>

          <.link
            href="/admin/payments/export"
            class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-[#6667ab] hover:bg-[#5556a0] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#6667ab] whitespace-nowrap"
          >
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
                d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              />
            </svg>
            Download as CSV
          </.link>
        </div>

        <.blank_state
          :if={@payments == []}
          icon_path="M9 14l6-6m-5.5.5h.01m4.99 5h.01M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h14a2 2 0 012 2v14a2 2 0 01-2 2z"
          title="No payments found"
          description={
            if @search != "",
              do: "No payments match \"#{@search}\".",
              else: "No successful payments recorded yet."
          }
        >
          <:actions :if={@search != ""}>
            <button phx-click="clear_search" class="text-xs text-[#6667ab] hover:underline">
              Clear filters
            </button>
          </:actions>
        </.blank_state>

        <.table :if={@payments != []} id="payments" rows={@payments}>
          <:col :let={payment} label="Patient">
            {[
              payment.patient.first_name,
              payment.patient.middle_name,
              payment.patient.last_name
            ]
            |> Enum.filter(&(&1 != nil))
            |> Enum.join(" ")}
          </:col>
          <:col :let={payment} label="Amount">{payment.amount} KES /=</:col>
          <:col :let={payment} label="Phone Number">{payment.account_number}</:col>
          <:col :let={payment} label="Reason">
            {payment.actionable_label || payment.actionable_type}
          </:col>
          <:col :let={payment} label="Prompter">{payment.prompter.name}</:col>
          <:col :let={payment} label="Date">
            {format_datetime(payment.inserted_at)}
          </:col>
        </.table>

        <.pagination
          page={@page}
          total_pages={@total_pages}
          total_count={@total_count}
          per_page={@per_page}
        />
      </div>
      
    <!-- Analytics View -->
      <div :if={@view_mode == :analysis} class="space-y-8">
        <!-- Summary Cards -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm">
            <h3 class="text-sm font-medium text-gray-500">Total Payments</h3>
            <p class="mt-2 text-3xl font-semibold text-[#373896]">
              {length(
                @analytics.prompter_stats
                |> Enum.flat_map(fn p -> List.duplicate(1, p.count) end)
              )}
            </p>
          </div>
          <div class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm">
            <h3 class="text-sm font-medium text-gray-500">Total Revenue</h3>
            <p class="mt-2 text-3xl font-semibold text-emerald-600">
              {Enum.sum(Enum.map(@analytics.prompter_stats, & &1.total))} KES
            </p>
          </div>
          <div class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm">
            <h3 class="text-sm font-medium text-gray-500">Active Prompters</h3>
            <p class="mt-2 text-3xl font-semibold text-amber-600">
              {length(@analytics.prompter_stats)}
            </p>
          </div>
        </div>
        
    <!-- Monthly Trends -->
        <div class="rounded-xl border border-gray-100 bg-white p-6 shadow-sm">
          <h3 class="text-lg font-medium text-gray-900 mb-4">Monthly Payment Trends</h3>
          <div class="space-y-4">
            <%= for month_data <- @analytics.monthly_totals do %>
              <div>
                <div class="flex justify-between text-sm mb-1">
                  <span class="font-medium">{format_month(month_data.month)}</span>
                  <span class="text-gray-600">
                    {month_data.total} KES ({month_data.count} payments)
                  </span>
                </div>
                <div class="w-full bg-gray-200 rounded-full h-2.5">
                  <div
                    class="bg-[#6667ab] h-2.5 rounded-full"
                    style={"width: #{calculate_percentage(month_data.total, @analytics.monthly_totals)}%"}
                  >
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
        
    <!-- Top Prompters -->
        <div class="rounded-xl border border-gray-100 bg-white p-6 shadow-sm">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-medium text-gray-900">Top Prompters</h3>

            <div class="flex space-x-2">
              <button
                phx-click="filter_prompters"
                phx-value-filter="active_only"
                class={[
                  "px-3 py-1 rounded-md text-sm font-medium transition-colors",
                  if(@prompter_filter == :active_only,
                    do: "bg-[#6667ab] text-white",
                    else: "bg-gray-200 text-gray-700 hover:bg-gray-300"
                  )
                ]}
              >
                Active Only
              </button>
              <button
                phx-click="filter_prompters"
                phx-value-filter="all"
                class={[
                  "px-3 py-1 rounded-md text-sm font-medium transition-colors",
                  if(@prompter_filter == :all,
                    do: "bg-[#6667ab] text-white",
                    else: "bg-gray-200 text-gray-700 hover:bg-gray-300"
                  )
                ]}
              >
                All
              </button>
            </div>
          </div>

          <div class="space-y-4">
            <%= for {prompter, index} <- Enum.with_index(filter_prompter_stats(@analytics.prompter_stats, @prompter_filter)) do %>
              <div class="flex items-center">
                <div class="flex-shrink-0 w-8 h-8 flex items-center justify-center rounded-full bg-[#e7e7ff] text-[#373896] font-semibold">
                  {index + 1}
                </div>
                <div class="ml-4 flex-1">
                  <div class="flex justify-between text-sm mb-1">
                    <span class="font-medium flex items-center space-x-2">
                      <span>{prompter.name}</span>
                      <span
                        :if={not prompter.is_active}
                        class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-600"
                      >
                        Inactive
                      </span>
                    </span>
                    <span class="text-gray-600">
                      {prompter.total} KES ({prompter.count} payments)
                    </span>
                  </div>
                  <div class="w-full bg-gray-200 rounded-full h-2">
                    <div
                      class="bg-emerald-600 h-2 rounded-full"
                      style={"width: #{calculate_percentage(prompter.total, filter_prompter_stats(@analytics.prompter_stats, @prompter_filter))}%"}
                    >
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
        
    <!-- Payment Reasons -->
        <div class="rounded-xl border border-gray-100 bg-white p-6 shadow-sm">
          <h3 class="text-lg font-medium text-gray-900 mb-4">Payment Breakdown by Reason</h3>
          <div class="space-y-4">
            <%= for reason_data <- @analytics.reason_stats do %>
              <div>
                <div class="flex justify-between text-sm mb-1">
                  <span class="font-medium">{reason_data.reason}</span>
                  <span class="text-gray-600">
                    {reason_data.total} KES ({reason_data.count} payments)
                  </span>
                </div>
                <div class="w-full bg-gray-200 rounded-full h-2.5">
                  <div
                    class="bg-amber-600 h-2.5 rounded-full"
                    style={"width: #{calculate_percentage(reason_data.total, @analytics.reason_stats)}%"}
                  >
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
        
    <!-- Monthly Performance by Prompter -->
        <div class="rounded-xl border border-gray-100 bg-white p-6 shadow-sm">
          <h3 class="text-lg font-medium text-gray-900 mb-4">Monthly Performance by Prompter</h3>
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Month
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Prompter
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Amount
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Count
                  </th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <%= for data <- @analytics.monthly_by_prompter do %>
                  <tr>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {format_month(data.month)}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{data.prompter}</td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {data.total} KES
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{data.count}</td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def format_datetime(datetime) do
    datetime
    |> DateTime.shift_zone!("Africa/Nairobi")
    |> Timex.format!("{Mfull} {D}, {YYYY} at {h12}:{m} {AM}")
  end

  defp format_month(month_string) do
    [year, month] = String.split(month_string, "-")

    month_name =
      case month do
        "01" -> "January"
        "02" -> "February"
        "03" -> "March"
        "04" -> "April"
        "05" -> "May"
        "06" -> "June"
        "07" -> "July"
        "08" -> "August"
        "09" -> "September"
        "10" -> "October"
        "11" -> "November"
        "12" -> "December"
      end

    "#{month_name} #{year}"
  end

  defp calculate_percentage(value, data_list) do
    max_value = Enum.max_by(data_list, & &1.total).total
    if max_value == 0, do: 0, else: trunc(value / max_value * 100)
  end
end
