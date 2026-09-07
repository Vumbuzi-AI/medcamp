defmodule MedcampWeb.DailyActivityLive.Index do
  @moduledoc """
  LiveView for tracking daily housekeeping activities.
  Each activity is done ONCE per day - clicking records WHO did it.
  Only the person who marked it can undo it.
  """
  use MedcampWeb, :support_staff_live_view

  alias Medcamp.DailyActivities

  @activities [
    "Tea Prepared",
    "Laundry Done",
    "Surfaces Dusted",
    "Floor Cleaned",
    "Bins Emptied",
    "Toilet/Bath room Cleaned",
    "Tissue Papers/Hand Towels Refilled",
    "Handwash Refilled",
    "Windows Cleaned",
    "Compound Cleaned"
  ]

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()

    # Get the current month's date range
    {start_date, end_date} = get_month_range(today)

    # Load all activities (we show who did each one)
    activities = DailyActivities.list_all_activities(start_date, end_date)

    {:ok,
     socket
     |> assign(:current_date, today)
     |> assign(:selected_month, today)
     |> assign(:start_date, start_date)
     |> assign(:end_date, end_date)
     |> assign(:activities_list, @activities)
     |> assign(:activities, activities)
     |> assign(:active_tab, :daily_activities)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Daily Activity Checklist")
  end

  defp apply_action(socket, :history, _params) do
    socket
    |> assign(:page_title, "Activity History")
  end

  @impl true
  def handle_event("mark_done", %{"activity" => activity, "day" => day}, socket) do
    current_user = socket.assigns.current_user
    date = Date.from_iso8601!(day)

    # Check if already done by someone
    case get_activity_record(socket.assigns.activities, date, activity) do
      nil ->
        # Not done yet - mark it with current user
        case DailyActivities.mark_activity_done(current_user.id, date, activity) do
          {:ok, _activity} ->
            activities = reload_activities(socket)

            {:noreply,
             socket
             |> assign(:activities, activities)
             |> put_flash(:info, "#{activity} marked as done")}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to update activity")}
        end

      %{user_id: user_id} = record when user_id == current_user.id ->
        # Done by current user - allow undo
        case DailyActivities.undo_activity(record.id) do
          {:ok, _} ->
            activities = reload_activities(socket)

            {:noreply,
             socket
             |> assign(:activities, activities)
             |> put_flash(:info, "#{activity} unmarked")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to undo")}
        end

      _other_user ->
        # Done by someone else - can't modify
        {:noreply, put_flash(socket, :error, "This was done by another staff member")}
    end
  end

  def handle_event("change_month", %{"direction" => direction}, socket) do
    current_month = socket.assigns.selected_month

    new_month =
      case direction do
        "prev" -> Date.add(current_month, -Date.days_in_month(current_month))
        "next" -> Date.add(current_month, Date.days_in_month(current_month))
      end

    {start_date, end_date} = get_month_range(new_month)
    activities = DailyActivities.list_all_activities(start_date, end_date)

    {:noreply,
     socket
     |> assign(:selected_month, new_month)
     |> assign(:start_date, start_date)
     |> assign(:end_date, end_date)
     |> assign(:activities, activities)}
  end

  def handle_event("go_to_today", _params, socket) do
    today = Date.utc_today()
    {start_date, end_date} = get_month_range(today)
    activities = DailyActivities.list_all_activities(start_date, end_date)

    {:noreply,
     socket
     |> assign(:selected_month, today)
     |> assign(:current_date, today)
     |> assign(:start_date, start_date)
     |> assign(:end_date, end_date)
     |> assign(:activities, activities)}
  end

  def handle_event("mark_all_today", _params, socket) do
    current_user = socket.assigns.current_user
    today = socket.assigns.current_date

    # Mark all uncompleted activities for today
    Enum.each(@activities, fn activity ->
      case get_activity_record(socket.assigns.activities, today, activity) do
        nil -> DailyActivities.mark_activity_done(current_user.id, today, activity)
        _ -> :ok
      end
    end)

    activities = reload_activities(socket)

    {:noreply,
     socket
     |> assign(:activities, activities)
     |> put_flash(:info, "All available activities marked as done")}
  end

  # Helper functions
  defp get_month_range(date) do
    start_date = Date.beginning_of_month(date)
    end_date = Date.end_of_month(date)
    {start_date, end_date}
  end

  defp reload_activities(socket) do
    DailyActivities.list_all_activities(socket.assigns.start_date, socket.assigns.end_date)
  end

  defp get_activity_record(activities, date, activity_name) do
    key = {Date.to_iso8601(date), activity_name}
    Map.get(activities, key)
  end

  defp days_in_month(date) do
    1..Date.days_in_month(date)
    |> Enum.map(fn day -> Date.new!(date.year, date.month, day) end)
  end

  defp is_today?(date, current_date) do
    Date.compare(date, current_date) == :eq
  end

  defp is_future?(date, current_date) do
    Date.compare(date, current_date) == :gt
  end

  defp get_initials(name) when is_binary(name) do
    name
    |> String.split(" ")
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
  end

  defp get_initials(_), do: "?"

  defp completion_percentage(activities, date, activities_list) do
    total = length(activities_list)

    completed =
      Enum.count(activities_list, fn activity ->
        get_activity_record(activities, date, activity) != nil
      end)

    if total > 0, do: round(completed / total * 100), else: 0
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100">
      <!-- Header -->
      <div class="p-4 border-b border-gray-100">
        <.header class="text-[#373896]">
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
                d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"
              />
            </svg>
            Housekeeping Checklist
            <span class="ml-2 text-sm font-normal text-gray-500">
              ({Calendar.strftime(@selected_month, "%B %Y")})
            </span>
          </div>
          <:actions>
            <div class="flex items-center gap-2">
              <button
                phx-click="mark_all_today"
                class="px-3 py-1.5 text-sm font-medium text-white bg-[#6667ab] rounded-lg hover:bg-[#5556a0] transition-colors"
              >
                Mark All Done Today
              </button>
              <button
                phx-click="go_to_today"
                class="px-3 py-1.5 text-sm font-medium text-[#6667ab] bg-[#6667ab]/10 rounded-lg hover:bg-[#6667ab]/20 transition-colors"
              >
                Today
              </button>
            </div>
          </:actions>
        </.header>
      </div>
      
    <!-- Controls Bar -->
      <div class="p-4 bg-gray-50 border-b border-gray-100">
        <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <!-- Month Navigation -->
          <div class="flex items-center gap-2">
            <button
              phx-click="change_month"
              phx-value-direction="prev"
              class="p-2 rounded-lg hover:bg-gray-200 transition-colors"
            >
              <svg class="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M15 19l-7-7 7-7"
                />
              </svg>
            </button>
            <span class="text-lg font-semibold text-gray-900 min-w-[160px] text-center">
              {Calendar.strftime(@selected_month, "%B %Y")}
            </span>
            <button
              phx-click="change_month"
              phx-value-direction="next"
              class="p-2 rounded-lg hover:bg-gray-200 transition-colors"
            >
              <svg class="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 5l7 7-7 7"
                />
              </svg>
            </button>
          </div>
          
    <!-- Current User Info -->
          <div class="flex items-center gap-2 text-sm">
            <span class="text-gray-600">Logged in as:</span>
            <span class="px-2 py-1 bg-[#6667ab]/10 text-[#6667ab] rounded-lg font-medium">
              {@current_user.name} ({get_initials(@current_user.name)})
            </span>
          </div>
        </div>
      </div>
      
    <!-- Legend -->
      <div class="px-4 py-3 bg-blue-50 border-b border-blue-100">
        <div class="flex flex-wrap items-center gap-4 text-sm">
          <span class="font-medium text-blue-900">How it works:</span>
          <div class="flex items-center gap-1">
            <span class="w-8 h-8 rounded-lg bg-gray-100 border-2 border-dashed border-gray-300 flex items-center justify-center text-gray-400">
              –
            </span>
            <span class="text-gray-600">= Not done (click to mark)</span>
          </div>
          <div class="flex items-center gap-1">
            <span class="w-8 h-8 rounded-lg bg-green-100 border border-green-300 flex items-center justify-center text-green-800 text-xs font-bold">
              RP
            </span>
            <span class="text-gray-600">= Done by staff (initials shown)</span>
          </div>
          <div class="flex items-center gap-1">
            <span class="w-8 h-8 rounded-lg bg-[#6667ab] flex items-center justify-center text-white text-xs font-bold ring-2 ring-[#6667ab]/50">
              You
            </span>
            <span class="text-gray-600">= Done by you (click to undo)</span>
          </div>
        </div>
      </div>
      
    <!-- Today's Quick View -->
      <div class="p-4 border-b border-gray-100">
        <div class="bg-gradient-to-r from-[#6667ab]/10 to-[#373896]/10 rounded-xl p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="font-semibold text-[#373896]">
              Today's Progress - {Calendar.strftime(@current_date, "%A, %B %d")}
            </h3>
            <span class="text-2xl font-bold text-[#6667ab]">
              {completion_percentage(@activities, @current_date, @activities_list)}%
            </span>
          </div>
          <div class="w-full bg-gray-200 rounded-full h-3">
            <div
              class="bg-gradient-to-r from-[#6667ab] to-[#373896] h-3 rounded-full transition-all duration-500"
              style={"width: #{completion_percentage(@activities, @current_date, @activities_list)}%"}
            >
            </div>
          </div>
        </div>
      </div>
      
    <!-- Activity Checklist Table -->
      <div class="overflow-x-auto">
        <table class="min-w-full">
          <thead>
            <tr class="bg-gray-50">
              <th class="sticky left-0 z-10 bg-gray-50 px-4 py-3 text-left text-xs font-semibold text-gray-700 uppercase tracking-wider border-b border-r border-gray-200 min-w-[200px]">
                Activity
              </th>
              <%= for day <- days_in_month(@selected_month) do %>
                <th class={"px-1 py-2 text-center border-b border-gray-200 min-w-[50px] #{if is_today?(day, @current_date), do: "bg-[#6667ab]/20", else: ""}"}>
                  <div class="flex flex-col items-center">
                    <span class={"text-xs font-medium #{if is_today?(day, @current_date), do: "text-[#373896]", else: "text-gray-500"}"}>
                      {day.day}
                    </span>
                    <span class="text-[10px] text-gray-400">
                      {Calendar.strftime(day, "%a") |> String.slice(0, 2)}
                    </span>
                  </div>
                </th>
              <% end %>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <%= for activity <- @activities_list do %>
              <tr class="hover:bg-gray-50 transition-colors">
                <td class="sticky left-0 z-10 bg-white px-4 py-3 text-sm font-medium text-gray-900 border-r border-gray-200 whitespace-nowrap">
                  {activity}
                </td>
                <%= for day <- days_in_month(@selected_month) do %>
                  <% record = get_activity_record(@activities, day, activity) %>
                  <% is_mine = record && record.user_id == @current_user.id %>
                  <% is_done = record != nil %>
                  <% can_click = !is_future?(day, @current_date) && (is_mine || !is_done) %>
                  <td class={"px-1 py-2 text-center #{if is_today?(day, @current_date), do: "bg-[#6667ab]/10", else: ""}"}>
                    <button
                      phx-click="mark_done"
                      phx-value-activity={activity}
                      phx-value-day={Date.to_iso8601(day)}
                      disabled={!can_click}
                      title={
                        cond do
                          is_done && is_mine ->
                            "Click to undo (done by you at #{if record.completed_at, do: Calendar.strftime(record.completed_at, "%H:%M"), else: "?"})"

                          is_done ->
                            "Done by #{record.user_name}"

                          is_future?(day, @current_date) ->
                            "Future date"

                          true ->
                            "Click to mark as done"
                        end
                      }
                      class={[
                        "w-10 h-10 rounded-lg text-xs font-bold transition-all flex items-center justify-center mx-auto",
                        cond do
                          is_done && is_mine ->
                            "bg-[#6667ab] text-white ring-2 ring-[#6667ab]/50 hover:bg-[#5556a0] cursor-pointer"

                          is_done ->
                            "bg-green-100 text-green-800 border border-green-300 cursor-not-allowed"

                          is_future?(day, @current_date) ->
                            "bg-gray-50 text-gray-300 border border-dashed border-gray-200 cursor-not-allowed"

                          true ->
                            "bg-gray-100 text-gray-400 border-2 border-dashed border-gray-300 hover:bg-gray-200 hover:border-[#6667ab] cursor-pointer"
                        end
                      ]}
                    >
                      <%= cond do %>
                        <% is_done && is_mine -> %>
                          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              stroke-width="2"
                              d="M5 13l4 4L19 7"
                            />
                          </svg>
                        <% is_done -> %>
                          {get_initials(record.user_name)}
                        <% true -> %>
                          –
                      <% end %>
                    </button>
                  </td>
                <% end %>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
      
    <!-- Summary Footer -->
      <div class="p-4 bg-gray-50 border-t border-gray-100">
        <div class="flex flex-wrap items-center justify-between gap-4">
          <div class="text-sm text-gray-600">
            <span class="font-medium">{length(@activities_list)}</span>
            activities tracked across
            <span class="font-medium">{Date.days_in_month(@selected_month)}</span>
            days
          </div>
          <div class="text-sm text-gray-500">
            Click any empty cell to mark as done • Only you can undo your own entries
          </div>
        </div>
      </div>
    </div>
    """
  end
end
