defmodule MedcampWeb.LabPagesQualityAssuranceLive.Show do
  use MedcampWeb, :lab_live_view

  alias Medcamp.QualityAssurance
  alias Medcamp.QualityAssurance.Chart

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :quality_assurance)
     |> assign(:chart, nil)
     |> assign(:selected_month, Date.utc_today().month)
     |> assign(:selected_year, Date.utc_today().year)}
  end

  @impl true
  def handle_params(%{"chart_type" => chart_type} = params, _url, socket) do
    month = parse_month(params["month"])
    year = parse_year(params["year"])

    chart = QualityAssurance.get_chart_by_month_year(chart_type, month, year)

    chart =
      if chart do
        %{chart | daily_entries: chart.daily_entries || %{}}
      else
        case QualityAssurance.create_chart(%{
               chart_type: chart_type,
               month: month,
               year: year,
               created_by_id: socket.assigns.current_user.id,
               daily_entries: %{}
             }) do
          {:ok, new_chart} ->
            QualityAssurance.get_chart!(new_chart.id)

          {:error, %Ecto.Changeset{} = changeset} ->
            case QualityAssurance.get_chart_by_month_year(chart_type, month, year) do
              nil ->
                IO.inspect(changeset.errors, label: "Failed to create chart")
                nil

              existing_chart ->
                %{existing_chart | daily_entries: existing_chart.daily_entries || %{}}
            end

          {:error, _} ->
            nil
        end
      end

    {:noreply,
     socket
     |> assign(:chart_type, chart_type)
     |> assign(:chart, chart)
     |> assign(:selected_month, month)
     |> assign(:selected_year, year)
     |> assign(:page_title, Chart.chart_type_label(chart_type))}
  end

  @impl true
  def handle_event("update_entry", params, socket) do
    day = Map.get(params, "day")
    field = Map.get(params, "field")

    # Get value from params - the field name is the key
    value =
      cond do
        is_binary(field) && Map.has_key?(params, field) ->
          Map.get(params, field, "")

        Map.has_key?(params, "value") ->
          Map.get(params, "value", "")

        true ->
          params
          |> Map.drop(["day", "field", "_target", "_format"])
          |> Enum.find(fn {_k, v} -> is_binary(v) end)
          |> case do
            {_key, val} -> val
            nil -> ""
          end
      end

    day_key = to_string(day)

    chart = socket.assigns.chart
    current_entries = chart.daily_entries || %{}
    day_entry = Map.get(current_entries, day_key, %{})

    updated_day_entry =
      if Chart.is_temperature_chart?(socket.assigns.chart_type) do
        case field do
          "morning_temperature" ->
            morning = Map.get(day_entry, "morning", %{}) || %{}
            updated_morning = Map.put(morning, "temperature", value)
            Map.put(day_entry, "morning", updated_morning)

          "morning_status" ->
            morning = Map.get(day_entry, "morning", %{}) || %{}
            updated_morning = Map.put(morning, "status", value)
            Map.put(day_entry, "morning", updated_morning)

          "morning_tech_initials" ->
            morning = Map.get(day_entry, "morning", %{}) || %{}
            updated_morning = Map.put(morning, "tech_initials", value)
            Map.put(day_entry, "morning", updated_morning)

          "afternoon_temperature" ->
            afternoon = Map.get(day_entry, "afternoon", %{}) || %{}
            updated_afternoon = Map.put(afternoon, "temperature", value)
            Map.put(day_entry, "afternoon", updated_afternoon)

          "afternoon_status" ->
            afternoon = Map.get(day_entry, "afternoon", %{}) || %{}
            updated_afternoon = Map.put(afternoon, "status", value)
            Map.put(day_entry, "afternoon", updated_afternoon)

          "afternoon_tech_initials" ->
            afternoon = Map.get(day_entry, "afternoon", %{}) || %{}
            updated_afternoon = Map.put(afternoon, "tech_initials", value)
            Map.put(day_entry, "afternoon", updated_afternoon)

          _ ->
            Map.put(day_entry, field, value)
        end
      else
        Map.put(day_entry, field, value)
      end

    updated_entries = Map.put(current_entries, day_key, updated_day_entry)

    case QualityAssurance.update_chart(chart, %{daily_entries: updated_entries}) do
      {:ok, updated_chart} ->
        reloaded_chart = QualityAssurance.get_chart!(updated_chart.id)

        {:noreply,
         socket
         |> assign(:chart, reloaded_chart)}

      {:error, changeset} ->
        IO.inspect(changeset.errors, label: "Update entry error")
        {:noreply, put_flash(socket, :error, "Failed to update entry")}
    end
  end

  @impl true
  def handle_event("change_month_year", %{"month" => month, "year" => year}, socket) do
    month_int = String.to_integer(month)
    year_int = String.to_integer(year)

    {:noreply,
     push_patch(socket,
       to:
         ~p"/lab/quality_assurance/#{socket.assigns.chart_type}?month=#{month_int}&year=#{year_int}"
     )}
  end

  defp parse_month(nil), do: Date.utc_today().month
  defp parse_month(month) when is_binary(month), do: String.to_integer(month)
  defp parse_month(month), do: month

  defp parse_year(nil), do: Date.utc_today().year
  defp parse_year(year) when is_binary(year), do: String.to_integer(year)
  defp parse_year(year), do: year

  defp month_name(month) do
    ~w[January February March April May June July August September October November December]
    |> Enum.at(month - 1)
  end

  defp days_in_month(month, year) do
    :calendar.last_day_of_the_month(year, month)
  end

  defp task_to_id(task) do
    task
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "_")
    |> String.trim("_")
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
              d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          {Chart.chart_type_label(@chart_type)}
        </div>
        <:actions>
          <.link navigate={~p"/lab/quality_assurance"} class="text-[#6667ab] hover:text-[#373896]">
            Back to Quality Assurance
          </.link>
        </:actions>
      </.header>
      
    <!-- Month/Year Selector -->
      <div class="mb-6 bg-gray-50 rounded-lg p-4 border border-gray-200">
        <form phx-change="change_month_year" class="flex items-center gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Month</label>
            <select
              name="month"
              class="w-full rounded-md border-gray-300 shadow-sm focus:border-[#6667ab] focus:ring-[#6667ab]"
            >
              <%= for month <- 1..12 do %>
                <option value={month} selected={@selected_month == month}>
                  {month_name(month)}
                </option>
              <% end %>
            </select>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Year</label>
            <select
              name="year"
              class="w-full rounded-md border-gray-300 shadow-sm focus:border-[#6667ab] focus:ring-[#6667ab]"
            >
              <%= for year <- (Date.utc_today().year - 2)..(Date.utc_today().year + 1) do %>
                <option value={year} selected={@selected_year == year}>{year}</option>
              <% end %>
            </select>
          </div>
        </form>
      </div>

      <%= if @chart do %>
        <%= if Chart.is_temperature_chart?(@chart_type) do %>
          <.temperature_chart
            chart={@chart}
            chart_type={@chart_type}
            month={@selected_month}
            year={@selected_year}
            current_user={@current_user}
          />
        <% else %>
          <.maintenance_chart
            chart={@chart}
            chart_type={@chart_type}
            month={@selected_month}
            year={@selected_year}
            current_user={@current_user}
          />
        <% end %>
      <% end %>
    </div>
    """
  end

  defp temperature_chart(assigns) do
    ~H"""
    <div class="overflow-x-auto">
      <div class="mb-4">
        <h3 class="text-lg font-semibold text-gray-900 mb-2">
          {month_name(@month)} {@year}
        </h3>
        <p class="text-sm text-gray-600 mb-4">
          {Chart.temperature_status_text(@chart_type)}
        </p>
      </div>

      <table class="min-w-full border-collapse border border-gray-300">
        <thead>
          <tr class="bg-[#e7e7ff]">
            <th class="border border-gray-300 px-4 py-2 text-left font-semibold text-[#373896]">
              Date / Time
            </th>
            <th class="border border-gray-300 px-4 py-2 text-center font-semibold text-[#373896]">
              Morning
            </th>
            <th class="border border-gray-300 px-4 py-2 text-center font-semibold text-[#373896]">
              Afternoon
            </th>
          </tr>
          <tr class="bg-gray-50">
            <th class="border border-gray-300 px-4 py-2 text-sm text-gray-700"></th>
            <th class="border border-gray-300 px-4 py-2 text-sm text-gray-700">
              <div class="grid grid-cols-3 gap-2">
                <span>Temp (°C)</span>
                <span>Status</span>
                <span>Tech</span>
              </div>
            </th>
            <th class="border border-gray-300 px-4 py-2 text-sm text-gray-700">
              <div class="grid grid-cols-3 gap-2">
                <span>Temp (°C)</span>
                <span>Status</span>
                <span>Tech</span>
              </div>
            </th>
          </tr>
        </thead>
        <tbody>
          <%= for day <- 1..days_in_month(@month, @year) do %>
            <% day_entry = QualityAssurance.get_day_entry(@chart, day) %>
            <% morning = Map.get(day_entry, "morning", %{}) || %{} %>
            <% afternoon = Map.get(day_entry, "afternoon", %{}) || %{} %>
            <% morning_status = Map.get(morning, "status", "") || "" %>
            <% afternoon_status = Map.get(afternoon, "status", "") || "" %>
            <tr class="hover:bg-gray-50">
              <td class="border border-gray-300 px-4 py-2">
                {String.pad_leading(Integer.to_string(day), 2, "0")}/{String.pad_leading(
                  Integer.to_string(@month),
                  2,
                  "0"
                )}/{@year}
              </td>
              <td class="border border-gray-300 px-2 py-2">
                <div class="grid grid-cols-3 gap-2">
                  <input
                    type="number"
                    step="0.1"
                    id={"morning_temp_#{day}"}
                    phx-hook="QualityAssuranceInput"
                    phx-value-day={day}
                    phx-value-field="morning_temperature"
                    value={Map.get(morning, "temperature", "")}
                    placeholder="°C"
                    class="w-full px-2 py-1 border border-gray-300 rounded text-sm"
                  />
                  <form phx-change="update_entry" phx-value-day={day} phx-value-field="morning_status">
                    <select
                      id={"morning_status_#{day}"}
                      name="morning_status"
                      class="w-full px-2 py-1 border border-gray-300 rounded text-sm"
                    >
                      <option value="" selected={morning_status == ""}>-</option>
                      <option value="Normal" selected={morning_status == "Normal"}>Normal</option>
                      <option value="Low" selected={morning_status == "Low"}>Low</option>
                      <option value="High" selected={morning_status == "High"}>High</option>
                    </select>
                  </form>
                  <input
                    type="text"
                    id={"morning_tech_#{day}"}
                    phx-hook="QualityAssuranceInput"
                    phx-value-day={day}
                    phx-value-field="morning_tech_initials"
                    value={Map.get(morning, "tech_initials", "")}
                    placeholder="Initials"
                    maxlength="5"
                    class="w-full px-2 py-1 border border-gray-300 rounded text-sm"
                  />
                </div>
              </td>
              <td class="border border-gray-300 px-2 py-2">
                <div class="grid grid-cols-3 gap-2">
                  <input
                    type="number"
                    step="0.1"
                    id={"afternoon_temp_#{day}"}
                    phx-hook="QualityAssuranceInput"
                    phx-value-day={day}
                    phx-value-field="afternoon_temperature"
                    value={Map.get(afternoon, "temperature", "")}
                    placeholder="°C"
                    class="w-full px-2 py-1 border border-gray-300 rounded text-sm"
                  />
                  <form
                    phx-change="update_entry"
                    phx-value-day={day}
                    phx-value-field="afternoon_status"
                  >
                    <select
                      id={"afternoon_status_#{day}"}
                      name="afternoon_status"
                      class="w-full px-2 py-1 border border-gray-300 rounded text-sm"
                    >
                      <option value="" selected={afternoon_status == ""}>-</option>
                      <option value="Normal" selected={afternoon_status == "Normal"}>Normal</option>
                      <option value="Low" selected={afternoon_status == "Low"}>Low</option>
                      <option value="High" selected={afternoon_status == "High"}>High</option>
                    </select>
                  </form>
                  <input
                    type="text"
                    id={"afternoon_tech_#{day}"}
                    phx-hook="QualityAssuranceInput"
                    phx-value-day={day}
                    phx-value-field="afternoon_tech_initials"
                    value={Map.get(afternoon, "tech_initials", "")}
                    placeholder="Initials"
                    maxlength="5"
                    class="w-full px-2 py-1 border border-gray-300 rounded text-sm"
                  />
                </div>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  defp maintenance_chart(assigns) do
    assigns =
      assigns
      |> assign(:tasks, Chart.maintenance_tasks(assigns.chart_type))
      |> assign(:days, days_in_month(assigns.month, assigns.year))

    ~H"""
    <div class="overflow-x-auto">
      <div class="mb-4">
        <h3 class="text-lg font-semibold text-gray-900 mb-2">
          {month_name(@month)} {@year}
        </h3>
        <p class="text-sm text-gray-600 mb-4">
          Key: D - Done | ND - Not Done
        </p>
      </div>

      <table class="min-w-full border-collapse border border-gray-300 text-sm">
        <thead>
          <tr class="bg-[#e7e7ff]">
            <th class="border border-gray-300 px-4 py-2 text-left font-semibold text-[#373896] sticky left-0 bg-[#e7e7ff] z-10">
              Date
            </th>
            <%= for day <- 1..@days do %>
              <th class="border border-gray-300 px-2 py-2 text-center font-semibold text-[#373896] min-w-[60px]">
                {day}
              </th>
            <% end %>
          </tr>
        </thead>
        <tbody>
          <%= for task <- @tasks do %>
            <tr class="hover:bg-gray-50">
              <td class="border border-gray-300 px-4 py-2 font-medium text-gray-900 sticky left-0 bg-white z-10">
                {task}
              </td>
              <%= for day <- 1..@days do %>
                <% day_entry = QualityAssurance.get_day_entry(@chart, day) || %{} %>
                <% task_status = Map.get(day_entry, task, "") || "" %>
                <td class="border border-gray-300 px-2 py-2 text-center">
                  <form phx-change="update_entry" phx-value-day={day} phx-value-field={task}>
                    <select
                      id={"task_#{task_to_id(task)}_#{day}"}
                      name={task}
                      class="w-full px-1 py-1 border border-gray-300 rounded text-xs"
                    >
                      <option value="" selected={task_status == ""}>-</option>
                      <option value="D" selected={task_status == "D"}>D</option>
                      <option value="ND" selected={task_status == "ND"}>ND</option>
                    </select>
                  </form>
                </td>
              <% end %>
            </tr>
          <% end %>
          <tr class="bg-gray-50 font-medium">
            <td class="border border-gray-300 px-4 py-2 sticky left-0 bg-gray-50 z-10">
              Tech Initials
            </td>
            <%= for day <- 1..@days do %>
              <% day_entry = QualityAssurance.get_day_entry(@chart, day) || %{} %>
              <% tech_initials = Map.get(day_entry, "tech_initials", "") %>
              <td class="border border-gray-300 px-2 py-2">
                <input
                  type="text"
                  id={"tech_initials_#{day}"}
                  phx-hook="QualityAssuranceInput"
                  phx-value-day={day}
                  phx-value-field="tech_initials"
                  value={tech_initials}
                  placeholder="Initials"
                  maxlength="5"
                  class="w-full px-1 py-1 border border-gray-300 rounded text-xs text-center"
                />
              </td>
            <% end %>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end
