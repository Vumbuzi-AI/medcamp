defmodule MedcampWeb.PharmacistsLive.PharmacyLogShow do
  use MedcampWeb, :pharmacist_live_view

  alias Medcamp.PharmacyLogs
  alias Medcamp.PharmacyLogs.PharmacyLog

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :pharmacy_logs)
     |> assign(:log, nil)
     |> assign(:selected_month, Date.utc_today().month)
     |> assign(:selected_year, Date.utc_today().year)}
  end

  @impl true
  def handle_params(%{"log_type" => log_type} = params, _url, socket) do
    month = parse_month(params["month"])
    year = parse_year(params["year"])

    log = PharmacyLogs.get_log_by_month_year(log_type, month, year)

    log =
      if log do
        %{log | daily_entries: log.daily_entries || %{}}
      else
        case PharmacyLogs.create_log(%{
               log_type: log_type,
               month: month,
               year: year,
               created_by_id: socket.assigns.current_user.id,
               daily_entries: %{}
             }) do
          {:ok, new_log} ->
            PharmacyLogs.get_log!(new_log.id)

          {:error, %Ecto.Changeset{} = changeset} ->
            case PharmacyLogs.get_log_by_month_year(log_type, month, year) do
              nil ->
                IO.inspect(changeset.errors, label: "Failed to create pharmacy log")
                nil

              existing_log ->
                %{existing_log | daily_entries: existing_log.daily_entries || %{}}
            end

          {:error, _} ->
            nil
        end
      end

    {:noreply,
     socket
     |> assign(:log_type, log_type)
     |> assign(:log, log)
     |> assign(:selected_month, month)
     |> assign(:selected_year, year)
     |> assign(:page_title, PharmacyLog.log_type_label(log_type))}
  end

  @impl true
  def handle_event("update_entry", params, socket) do
    day = Map.get(params, "day")
    field = Map.get(params, "field")

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
    log = socket.assigns.log
    current_entries = log.daily_entries || %{}
    day_entry = Map.get(current_entries, day_key, %{})

    updated_day_entry =
      case field do
        "morning_temperature" ->
          morning = Map.get(day_entry, "morning", %{}) || %{}
          Map.put(day_entry, "morning", Map.put(morning, "temperature", value))

        "morning_humidity" ->
          morning = Map.get(day_entry, "morning", %{}) || %{}
          Map.put(day_entry, "morning", Map.put(morning, "humidity", value))

        "morning_status" ->
          morning = Map.get(day_entry, "morning", %{}) || %{}
          Map.put(day_entry, "morning", Map.put(morning, "status", value))

        "morning_tech_initials" ->
          morning = Map.get(day_entry, "morning", %{}) || %{}
          Map.put(day_entry, "morning", Map.put(morning, "tech_initials", value))

        "afternoon_temperature" ->
          afternoon = Map.get(day_entry, "afternoon", %{}) || %{}
          Map.put(day_entry, "afternoon", Map.put(afternoon, "temperature", value))

        "afternoon_humidity" ->
          afternoon = Map.get(day_entry, "afternoon", %{}) || %{}
          Map.put(day_entry, "afternoon", Map.put(afternoon, "humidity", value))

        "afternoon_status" ->
          afternoon = Map.get(day_entry, "afternoon", %{}) || %{}
          Map.put(day_entry, "afternoon", Map.put(afternoon, "status", value))

        "afternoon_tech_initials" ->
          afternoon = Map.get(day_entry, "afternoon", %{}) || %{}
          Map.put(day_entry, "afternoon", Map.put(afternoon, "tech_initials", value))

        _ ->
          Map.put(day_entry, field, value)
      end

    updated_entries = Map.put(current_entries, day_key, updated_day_entry)

    case PharmacyLogs.update_log(log, %{daily_entries: updated_entries}) do
      {:ok, updated_log} ->
        reloaded_log = PharmacyLogs.get_log!(updated_log.id)
        {:noreply, assign(socket, :log, reloaded_log)}

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
         ~p"/pharmacist/pharmacy_logs/#{socket.assigns.log_type}?month=#{month_int}&year=#{year_int}"
     )}
  end

  defp parse_month(nil), do: Date.utc_today().month
  defp parse_month(m) when is_binary(m), do: String.to_integer(m)
  defp parse_month(m), do: m

  defp parse_year(nil), do: Date.utc_today().year
  defp parse_year(y) when is_binary(y), do: String.to_integer(y)
  defp parse_year(y), do: y

  defp month_name(month) do
    ~w[January February March April May June July August September October November December]
    |> Enum.at(month - 1)
  end

  defp days_in_month(month, year), do: :calendar.last_day_of_the_month(year, month)

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
              d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
            />
          </svg>
          {PharmacyLog.log_type_label(@log_type)}
        </div>
        <:actions>
          <.link navigate={~p"/pharmacist/pharmacy_logs"} class="text-[#6667ab] hover:text-[#373896]">
            Back to Logs
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

      <%= if @log do %>
        <div class="overflow-x-auto">
          <div class="mb-4">
            <h3 class="text-lg font-semibold text-gray-900 mb-1">
              {month_name(@selected_month)} {@selected_year}
            </h3>
            <p class="text-sm text-gray-500">
              Normal Range: {PharmacyLog.normal_range(@log_type)}
            </p>
          </div>

          <table class="min-w-full border-collapse border border-gray-300 text-sm">
            <thead>
              <tr class="bg-[#e7e7ff]">
                <th class="border border-gray-300 px-4 py-2 text-left font-semibold text-[#373896]">
                  Date
                </th>
                <th
                  class="border border-gray-300 px-4 py-2 text-center font-semibold text-[#373896]"
                  colspan={if PharmacyLog.has_humidity?(@log_type), do: 4, else: 3}
                >
                  Morning
                </th>
                <th
                  class="border border-gray-300 px-4 py-2 text-center font-semibold text-[#373896]"
                  colspan={if PharmacyLog.has_humidity?(@log_type), do: 4, else: 3}
                >
                  Afternoon
                </th>
              </tr>
              <tr class="bg-gray-50">
                <th class="border border-gray-300 px-4 py-2"></th>
                <th class="border border-gray-300 px-3 py-2 text-xs text-gray-600 font-medium">
                  Temp (°C)
                </th>
                <%= if PharmacyLog.has_humidity?(@log_type) do %>
                  <th class="border border-gray-300 px-3 py-2 text-xs text-gray-600 font-medium">
                    Humidity (%)
                  </th>
                <% end %>
                <th class="border border-gray-300 px-3 py-2 text-xs text-gray-600 font-medium">
                  Status
                </th>
                <th class="border border-gray-300 px-3 py-2 text-xs text-gray-600 font-medium">
                  Tech
                </th>
                <th class="border border-gray-300 px-3 py-2 text-xs text-gray-600 font-medium">
                  Temp (°C)
                </th>
                <%= if PharmacyLog.has_humidity?(@log_type) do %>
                  <th class="border border-gray-300 px-3 py-2 text-xs text-gray-600 font-medium">
                    Humidity (%)
                  </th>
                <% end %>
                <th class="border border-gray-300 px-3 py-2 text-xs text-gray-600 font-medium">
                  Status
                </th>
                <th class="border border-gray-300 px-3 py-2 text-xs text-gray-600 font-medium">
                  Tech
                </th>
              </tr>
            </thead>
            <tbody>
              <%= for day <- 1..days_in_month(@selected_month, @selected_year) do %>
                <% day_entry = PharmacyLogs.get_day_entry(@log, day) %>
                <% morning = Map.get(day_entry, "morning", %{}) || %{} %>
                <% afternoon = Map.get(day_entry, "afternoon", %{}) || %{} %>
                <% morning_status = Map.get(morning, "status", "") || "" %>
                <% afternoon_status = Map.get(afternoon, "status", "") || "" %>
                <tr class="hover:bg-gray-50">
                  <td class="border border-gray-300 px-4 py-2 font-medium text-gray-700 whitespace-nowrap">
                    {String.pad_leading(Integer.to_string(day), 2, "0")}/{String.pad_leading(
                      Integer.to_string(@selected_month),
                      2,
                      "0"
                    )}/{@selected_year}
                  </td>
                  <!-- Morning temperature -->
                  <td class="border border-gray-300 px-2 py-1">
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
                  </td>
                  <!-- Morning humidity (if applicable) -->
                  <%= if PharmacyLog.has_humidity?(@log_type) do %>
                    <td class="border border-gray-300 px-2 py-1">
                      <input
                        type="number"
                        step="0.1"
                        id={"morning_humidity_#{day}"}
                        phx-hook="QualityAssuranceInput"
                        phx-value-day={day}
                        phx-value-field="morning_humidity"
                        value={Map.get(morning, "humidity", "")}
                        placeholder="%"
                        class="w-full px-2 py-1 border border-gray-300 rounded text-sm"
                      />
                    </td>
                  <% end %>
                  <!-- Morning status -->
                  <td class="border border-gray-300 px-2 py-1">
                    <form
                      phx-change="update_entry"
                      phx-value-day={day}
                      phx-value-field="morning_status"
                    >
                      <select
                        name="morning_status"
                        class="w-full px-2 py-1 border border-gray-300 rounded text-sm"
                      >
                        <option value="" selected={morning_status == ""}>-</option>
                        <option value="Normal" selected={morning_status == "Normal"}>Normal</option>
                        <option value="Low" selected={morning_status == "Low"}>Low</option>
                        <option value="High" selected={morning_status == "High"}>High</option>
                      </select>
                    </form>
                  </td>
                  <!-- Morning tech initials -->
                  <td class="border border-gray-300 px-2 py-1">
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
                  </td>
                  <!-- Afternoon temperature -->
                  <td class="border border-gray-300 px-2 py-1">
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
                  </td>
                  <!-- Afternoon humidity (if applicable) -->
                  <%= if PharmacyLog.has_humidity?(@log_type) do %>
                    <td class="border border-gray-300 px-2 py-1">
                      <input
                        type="number"
                        step="0.1"
                        id={"afternoon_humidity_#{day}"}
                        phx-hook="QualityAssuranceInput"
                        phx-value-day={day}
                        phx-value-field="afternoon_humidity"
                        value={Map.get(afternoon, "humidity", "")}
                        placeholder="%"
                        class="w-full px-2 py-1 border border-gray-300 rounded text-sm"
                      />
                    </td>
                  <% end %>
                  <!-- Afternoon status -->
                  <td class="border border-gray-300 px-2 py-1">
                    <form
                      phx-change="update_entry"
                      phx-value-day={day}
                      phx-value-field="afternoon_status"
                    >
                      <select
                        name="afternoon_status"
                        class="w-full px-2 py-1 border border-gray-300 rounded text-sm"
                      >
                        <option value="" selected={afternoon_status == ""}>-</option>
                        <option value="Normal" selected={afternoon_status == "Normal"}>Normal</option>
                        <option value="Low" selected={afternoon_status == "Low"}>Low</option>
                        <option value="High" selected={afternoon_status == "High"}>High</option>
                      </select>
                    </form>
                  </td>
                  <!-- Afternoon tech initials -->
                  <td class="border border-gray-300 px-2 py-1">
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
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>
    </div>
    """
  end
end
