defmodule MedcampWeb.LabPagesDutyRotaLive.Index do
  use MedcampWeb, :lab_live_view

  @staff [
    %{name: "Aman", color: "bg-purple-100 text-purple-800 border-purple-200"},
    %{name: "Brayan", color: "bg-green-100 text-green-800 border-green-200"},
    %{name: "Rodgers", color: "bg-blue-100 text-blue-800 border-blue-200"},
    %{name: "Mohammed", color: "bg-orange-100 text-orange-800 border-orange-200"}
  ]

  # 4-day rotation cycle — 2 people per day, fair day/night rotation
  # Each person works day shift then night shift across the cycle
  @rotation [
    # {day_shift_index, night_shift_index} — index into @staff
    {0, 1},
    {2, 3},
    {1, 0},
    {3, 2}
  ]

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()
    six_months_ago = Date.add(today, -183)

    {:ok,
     socket
     |> assign(:active_tab, :duty_rota)
     |> assign(:today, today)
     |> assign(:view_month, today)
     |> assign(:six_months_ago, six_months_ago)
     |> assign(:staff, @staff)
     |> assign(:selected_day, nil)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :page_title, "Duty Rota")}
  end

  @impl true
  def handle_event("prev_month", _params, socket) do
    new_month = socket.assigns.view_month |> Date.beginning_of_month() |> Date.add(-1)
    {:noreply, assign(socket, :view_month, new_month)}
  end

  @impl true
  def handle_event("next_month", _params, socket) do
    new_month = socket.assigns.view_month |> Date.end_of_month() |> Date.add(1)
    {:noreply, assign(socket, :view_month, new_month)}
  end

  @impl true
  def handle_event("select_day", %{"date" => date_str}, socket) do
    case Date.from_iso8601(date_str) do
      {:ok, date} -> {:noreply, assign(socket, :selected_day, date)}
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event("close_detail", _params, socket) do
    {:noreply, assign(socket, :selected_day, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.header class="text-[#373896] border-b border-gray-100 pb-4 mb-4">
        <div class="flex items-center">
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
          Lab Duty Rota
        </div>
      </.header>

      <%!-- Staff Legend --%>
      <div class="flex flex-wrap gap-3 mb-6">
        <%= for person <- @staff do %>
          <div class={"flex items-center gap-2 px-3 py-1.5 rounded-full border text-sm font-medium #{person.color}"}>
            <div class="w-2 h-2 rounded-full bg-current opacity-70"></div>
            {person.name}
          </div>
        <% end %>
        <div class="flex items-center gap-2 px-3 py-1.5 rounded-full border text-sm font-medium bg-yellow-50 text-yellow-700 border-yellow-200 ml-4">
          <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
            <path d="M10 2a8 8 0 100 16A8 8 0 0010 2zm0 14A6 6 0 1110 4a6 6 0 010 12zm1-9H9v5l4.25 2.52.75-1.23-3-1.79V7z" />
          </svg>
          Day: 06:00 – 18:00
        </div>
        <div class="flex items-center gap-2 px-3 py-1.5 rounded-full border text-sm font-medium bg-indigo-50 text-indigo-700 border-indigo-200">
          <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
            <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" />
          </svg>
          Night: 18:00 – 06:00
        </div>
      </div>

      <%!-- Month Navigation --%>
      <div class="flex items-center justify-between mb-4">
        <button
          phx-click="prev_month"
          class="flex items-center gap-1 px-3 py-2 text-sm text-gray-600 hover:text-[#373896] hover:bg-[#f0f0ff] rounded-lg transition-colors"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
          </svg>
          Prev
        </button>

        <h2 class="text-lg font-semibold text-[#373896]">
          {Calendar.strftime(@view_month, "%B %Y")}
          <%= if Date.beginning_of_month(@view_month) == Date.beginning_of_month(@today) do %>
            <span class="ml-2 text-xs font-normal text-white bg-[#6667ab] px-2 py-0.5 rounded-full">
              Current Month
            </span>
          <% end %>
        </h2>

        <button
          phx-click="next_month"
          class="flex items-center gap-1 px-3 py-2 text-sm text-gray-600 hover:text-[#373896] hover:bg-[#f0f0ff] rounded-lg transition-colors"
        >
          Next
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
        </button>
      </div>

      <%!-- Calendar Grid --%>
      <div class="border border-gray-200 rounded-lg overflow-hidden">
        <%!-- Day headers --%>
        <div class="grid grid-cols-7 bg-[#f7f7ff]">
          <%= for day_name <- ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"] do %>
            <div class="py-2 text-center text-xs font-semibold text-[#6667ab] uppercase tracking-wide">
              {day_name}
            </div>
          <% end %>
        </div>

        <%!-- Calendar Weeks --%>
        <div class="grid grid-cols-7 divide-x divide-y divide-gray-100">
          <%= for {date, in_month} <- calendar_days(@view_month) do %>
            <% shift = get_shift(date) %>
            <% is_today = Date.compare(date, @today) == :eq %>
            <% is_selected = @selected_day && Date.compare(date, @selected_day) == :eq %>
            <% is_past = Date.compare(date, @today) == :lt %>
            <div
              phx-click="select_day"
              phx-value-date={Date.to_iso8601(date)}
              class={[
                "min-h-[90px] p-2 cursor-pointer transition-all",
                in_month && "hover:bg-[#f7f7ff]",
                !in_month && "bg-gray-50 opacity-40",
                is_today && "bg-[#eeeeff]",
                is_selected && "ring-2 ring-inset ring-[#6667ab]"
              ]}
            >
              <div class={[
                "text-xs font-medium mb-1 w-6 h-6 flex items-center justify-center rounded-full",
                is_today && "bg-[#6667ab] text-white",
                !is_today && in_month && "text-gray-700",
                !is_today && !in_month && "text-gray-400"
              ]}>
                {date.day}
              </div>

              <%= if in_month && shift do %>
                <% day_person = Enum.at(@staff, shift.day_index) %>
                <% night_person = Enum.at(@staff, shift.night_index) %>
                <div class={[
                  "text-xs px-1.5 py-0.5 rounded border mb-1 truncate flex items-center gap-1",
                  day_person.color
                ]}>
                  <svg class="w-2.5 h-2.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                    <path
                      fill-rule="evenodd"
                      d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z"
                      clip-rule="evenodd"
                    />
                  </svg>
                  <span class="truncate">{day_person.name}</span>
                </div>
                <div class={[
                  "text-xs px-1.5 py-0.5 rounded border truncate flex items-center gap-1",
                  night_person.color
                ]}>
                  <svg class="w-2.5 h-2.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" />
                  </svg>
                  <span class="truncate">{night_person.name}</span>
                </div>
                <%= if is_past do %>
                  <div class="text-xs text-gray-400 mt-0.5">✓ completed</div>
                <% end %>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <%!-- Day Detail Panel --%>
      <%= if @selected_day do %>
        <% shift = get_shift(@selected_day) %>
        <% day_person = Enum.at(@staff, shift.day_index) %>
        <% night_person = Enum.at(@staff, shift.night_index) %>
        <% is_past_day = Date.compare(@selected_day, @today) == :lt %>
        <div class="mt-4 border border-[#d4d5f7] rounded-lg p-4 bg-[#f7f7ff]">
          <div class="flex items-center justify-between mb-3">
            <h3 class="font-semibold text-[#373896]">
              {Calendar.strftime(@selected_day, "%A, %d %B %Y")}
              <%= if is_past_day do %>
                <span class="ml-2 text-xs font-normal text-gray-500 bg-gray-100 px-2 py-0.5 rounded-full">
                  Past
                </span>
              <% end %>
            </h3>
            <button
              phx-click="close_detail"
              class="text-gray-400 hover:text-gray-600 transition-colors"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div class="bg-white rounded-lg border border-yellow-200 p-3">
              <div class="flex items-center gap-2 mb-2">
                <div class="p-1.5 bg-yellow-100 rounded-md">
                  <svg class="w-4 h-4 text-yellow-600" fill="currentColor" viewBox="0 0 20 20">
                    <path
                      fill-rule="evenodd"
                      d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z"
                      clip-rule="evenodd"
                    />
                  </svg>
                </div>
                <div>
                  <div class="text-xs text-gray-500 font-medium">Day Shift</div>
                  <div class="text-xs text-gray-400">06:00 – 18:00</div>
                </div>
              </div>
              <div class={"text-sm font-semibold px-2 py-1 rounded border #{day_person.color}"}>
                {day_person.name}
              </div>
            </div>

            <div class="bg-white rounded-lg border border-indigo-200 p-3">
              <div class="flex items-center gap-2 mb-2">
                <div class="p-1.5 bg-indigo-100 rounded-md">
                  <svg class="w-4 h-4 text-indigo-600" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" />
                  </svg>
                </div>
                <div>
                  <div class="text-xs text-gray-500 font-medium">Night Shift</div>
                  <div class="text-xs text-gray-400">18:00 – 06:00</div>
                </div>
              </div>
              <div class={"text-sm font-semibold px-2 py-1 rounded border #{night_person.color}"}>
                {night_person.name}
              </div>
            </div>
          </div>
        </div>
      <% end %>

      <%!-- Upcoming shifts summary --%>
      <div class="mt-4">
        <h3 class="text-sm font-semibold text-gray-600 mb-3">Next 7 Days</h3>
        <div class="space-y-2">
          <%= for offset <- 0..6 do %>
            <% date = Date.add(@today, offset) %>
            <% shift = get_shift(date) %>
            <% day_person = Enum.at(@staff, shift.day_index) %>
            <% night_person = Enum.at(@staff, shift.night_index) %>
            <div class="flex items-center gap-3 p-2 rounded-lg hover:bg-gray-50 transition-colors">
              <div class="w-24 text-xs font-medium text-gray-500">
                {if offset == 0, do: "Today", else: Calendar.strftime(date, "%a %d %b")}
              </div>
              <div class="flex gap-2 flex-1">
                <span class={"text-xs px-2 py-0.5 rounded border #{day_person.color}"}>
                  ☀ {day_person.name}
                </span>
                <span class={"text-xs px-2 py-0.5 rounded border #{night_person.color}"}>
                  ☾ {night_person.name}
                </span>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # Generate calendar days for a given month — returns {date, in_month} tuples
  # padded to fill the Mon–Sun grid
  defp calendar_days(view_month) do
    first_day = Date.beginning_of_month(view_month)
    last_day = Date.end_of_month(view_month)

    # Monday = 1 ... Sunday = 7
    leading_days = Date.day_of_week(first_day) - 1

    start_date = Date.add(first_day, -leading_days)
    total_days = Date.diff(last_day, start_date) + 1
    # Round up to nearest 7
    total_cells = ceil(total_days / 7) * 7

    for offset <- 0..(total_cells - 1) do
      date = Date.add(start_date, offset)
      in_month = date.month == view_month.month && date.year == view_month.year
      {date, in_month}
    end
  end

  # Compute shift assignment for a given date using 4-day rotation
  # Returns %{day_index: _, night_index: _} into @staff list
  defp get_shift(date) do
    # Use a fixed epoch to ensure consistent rotation across all dates
    epoch = ~D[2024-01-01]
    diff = Date.diff(date, epoch)
    cycle_pos = rem(abs(diff), 4)
    {day_idx, night_idx} = Enum.at(@rotation, cycle_pos)
    %{day_index: day_idx, night_index: night_idx}
  end
end
