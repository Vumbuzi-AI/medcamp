defmodule MedcampWeb.PharmacistsLive.DangerousDrugRegisterShow do
  use MedcampWeb, :pharmacist_live_view

  alias Medcamp.DangerousDrugRegisters
  alias Medcamp.Drugs

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()

    {:ok,
     socket
     |> assign(:active_tab, :dangerous_drug_registers)
     |> assign(:register, nil)
     |> assign(:drug, nil)
     |> assign(:selected_month, today.month)
     |> assign(:selected_year, today.year)}
  end

  @impl true
  def handle_params(%{"drug_id" => drug_id} = params, _url, socket) do
    month = parse_month(params["month"])
    year = parse_year(params["year"])
    drug = Drugs.get_drug!(drug_id)

    if drug.is_dangerous_drug do
      {:ok, register} =
        DangerousDrugRegisters.ensure_register(
          drug.id,
          month,
          year,
          socket.assigns.current_user.id
        )

      {:noreply,
       socket
       |> assign(:page_title, "Dangerous Drug Register")
       |> assign(:drug, drug)
       |> assign(:register, register)
       |> assign(:selected_month, month)
       |> assign(:selected_year, year)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "This drug is not marked for the dangerous drug register yet.")
       |> push_navigate(to: ~p"/pharmacist/dangerous_drug_registers")}
    end
  end

  @impl true
  def handle_event("update_entry", params, socket) do
    entry_id = Map.get(params, "entry_id") || Map.get(params, "day")
    field = Map.get(params, "field")
    value = Map.get(params, "value", "")

    case DangerousDrugRegisters.update_entry(socket.assigns.register, entry_id, field, value) do
      {:ok, register} ->
        {:noreply, assign(socket, :register, DangerousDrugRegisters.get_register!(register.id))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update register entry")}
    end
  end

  @impl true
  def handle_event("add_entry", _params, socket) do
    case DangerousDrugRegisters.add_entry(socket.assigns.register) do
      {:ok, register} ->
        {:noreply, assign(socket, :register, DangerousDrugRegisters.get_register!(register.id))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to add register row")}
    end
  end

  @impl true
  def handle_event("remove_entry", %{"entry_id" => entry_id}, socket) do
    case DangerousDrugRegisters.remove_entry(socket.assigns.register, entry_id) do
      {:ok, register} ->
        {:noreply, assign(socket, :register, DangerousDrugRegisters.get_register!(register.id))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to remove register row")}
    end
  end

  @impl true
  def handle_event("change_month_year", %{"month" => month, "year" => year}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         ~p"/pharmacist/dangerous_drug_registers/#{socket.assigns.drug.id}?month=#{month}&year=#{year}"
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

  defp quantity_display(number) when is_integer(number), do: Integer.to_string(number)

  defp quantity_display(number) when is_float(number) do
    if number == Float.floor(number) do
      number
      |> trunc()
      |> Integer.to_string()
    else
      :erlang.float_to_binary(number, decimals: 2)
      |> String.trim_trailing("0")
      |> String.trim_trailing(".")
    end
  end

  @impl true
  def render(assigns) do
    opening_balance = DangerousDrugRegisters.opening_balance(assigns.register)
    rows = DangerousDrugRegisters.entry_rows(assigns.register)
    closing_balance = DangerousDrugRegisters.closing_balance(assigns.register)

    assigns =
      assigns
      |> assign(:opening_balance, opening_balance)
      |> assign(:rows, rows)
      |> assign(:closing_balance, closing_balance)

    ~H"""
    <div class="space-y-6">
      <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
        <.header class="text-[#373896] border-b border-gray-100 pb-4 mb-4">
          <div>
            <div class="text-xs font-semibold uppercase tracking-[0.2em] text-orange-600">
              Dangerous Drug Register
            </div>
            <div class="mt-1">{Drugs.display_name(@drug)}</div>
          </div>
          <:actions>
            <.link
              navigate={~p"/pharmacist/dangerous_drug_registers"}
              class="text-[#6667ab] hover:text-[#373896]"
            >
              Back to Drugs
            </.link>
          </:actions>
        </.header>

        <div class="grid gap-4 lg:grid-cols-[1.3fr,0.7fr]">
          <div class="rounded-xl border border-orange-100 bg-orange-50/60 p-4">
            <p class="text-sm text-slate-700">
              Each drug keeps its own monthly page. Prescription reference is optional, so staff can
              leave it blank or enter any local reference when scripts are not numbered.
            </p>
          </div>

          <div class="rounded-xl border border-gray-200 bg-gray-50 p-4">
            <form phx-change="change_month_year" class="grid gap-3 sm:grid-cols-2">
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
        </div>
      </div>

      <div class="grid gap-4 md:grid-cols-3">
        <div class="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
          <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">Month</p>
          <p class="mt-2 text-xl font-semibold text-slate-900">
            {month_name(@selected_month)} {@selected_year}
          </p>
        </div>

        <div class="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
          <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">
            Opening Balance
          </p>
          <p class="mt-2 text-xl font-semibold text-slate-900">
            {quantity_display(@opening_balance)}
          </p>
        </div>

        <div class="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
          <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">
            Closing Balance
          </p>
          <p class="mt-2 text-xl font-semibold text-slate-900">
            {quantity_display(@closing_balance)}
          </p>
        </div>
      </div>

      <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
        <div class="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h3 class="text-lg font-semibold text-slate-900">Monthly Transactions</h3>
            <p class="text-sm text-slate-500">
              Transaction number and per-row drug name are intentionally removed on this register.
            </p>
          </div>

          <button
            type="button"
            phx-click="add_entry"
            class="inline-flex items-center justify-center rounded-md bg-[#373896] px-4 py-2 text-sm font-medium text-white transition hover:bg-[#2e2f77]"
          >
            Add Row
          </button>
        </div>

        <div class="overflow-x-auto">
          <table class="min-w-full border-collapse border border-gray-300 text-sm">
            <thead>
              <tr class="bg-[#f8f7ff]">
                <th class="border border-gray-300 px-3 py-2 text-left font-semibold text-[#373896]">
                  Date
                </th>
                <th class="border border-gray-300 px-3 py-2 text-left font-semibold text-[#373896]">
                  Time
                </th>
                <th class="border border-gray-300 px-3 py-2 text-left font-semibold text-[#373896]">
                  Prescription No. / Ref
                </th>
                <th class="border border-gray-300 px-3 py-2 text-left font-semibold text-[#373896]">
                  Patient Name
                </th>
                <th class="border border-gray-300 px-3 py-2 text-left font-semibold text-[#373896]">
                  Patient ID / File No.
                </th>
                <th class="border border-gray-300 px-3 py-2 text-left font-semibold text-[#373896]">
                  Strength / Form
                </th>
                <th class="border border-gray-300 px-3 py-2 text-left font-semibold text-[#373896]">
                  Batch No.
                </th>
                <th class="border border-gray-300 px-3 py-2 text-left font-semibold text-[#373896]">
                  Qty Received
                </th>
                <th class="border border-gray-300 px-3 py-2 text-left font-semibold text-[#373896]">
                  Qty Dispensed
                </th>
                <th class="border border-gray-300 px-3 py-2 text-left font-semibold text-[#373896]">
                  Running Balance
                </th>
                <th class="border border-gray-300 px-3 py-2 text-left font-semibold text-[#373896]">
                  Prescriber
                </th>
                <th class="border border-gray-300 px-3 py-2 text-left font-semibold text-[#373896]">
                  Pharmacist
                </th>
                <th class="border border-gray-300 px-3 py-2 text-left font-semibold text-[#373896]">
                  Remarks
                </th>
                <th class="border border-gray-300 px-3 py-2 text-left font-semibold text-[#373896]">
                </th>
              </tr>
            </thead>
            <tbody>
              <%= for row <- @rows do %>
                <% entry = row.entry %>
                <tr class="align-top hover:bg-gray-50">
                  <td class="border border-gray-300 px-2 py-1">
                    <input
                      id={"register_#{row.id}_date"}
                      type="date"
                      phx-hook="QualityAssuranceInput"
                      phx-value-day={row.id}
                      phx-value-field="date"
                      value={Map.get(entry, "date", "")}
                      class="w-36 rounded border border-gray-300 px-2 py-1"
                    />
                  </td>
                  <td class="border border-gray-300 px-2 py-1">
                    <input
                      id={"register_#{row.id}_time"}
                      type="time"
                      phx-hook="QualityAssuranceInput"
                      phx-value-day={row.id}
                      phx-value-field="time"
                      value={Map.get(entry, "time", "")}
                      class="w-28 rounded border border-gray-300 px-2 py-1"
                    />
                  </td>
                  <td class="border border-gray-300 px-2 py-1">
                    <input
                      id={"register_#{row.id}_prescription_number"}
                      type="text"
                      phx-hook="QualityAssuranceInput"
                      phx-value-day={row.id}
                      phx-value-field="prescription_number"
                      value={Map.get(entry, "prescription_number", "")}
                      placeholder="Optional"
                      class="w-40 rounded border border-gray-300 px-2 py-1"
                    />
                  </td>
                  <td class="border border-gray-300 px-2 py-1">
                    <input
                      id={"register_#{row.id}_patient_name"}
                      type="text"
                      phx-hook="QualityAssuranceInput"
                      phx-value-day={row.id}
                      phx-value-field="patient_name"
                      value={Map.get(entry, "patient_name", "")}
                      class="w-44 rounded border border-gray-300 px-2 py-1"
                    />
                  </td>
                  <td class="border border-gray-300 px-2 py-1">
                    <input
                      id={"register_#{row.id}_patient_file_number"}
                      type="text"
                      phx-hook="QualityAssuranceInput"
                      phx-value-day={row.id}
                      phx-value-field="patient_file_number"
                      value={Map.get(entry, "patient_file_number", "")}
                      class="w-40 rounded border border-gray-300 px-2 py-1"
                    />
                  </td>
                  <td class="border border-gray-300 px-2 py-1">
                    <input
                      id={"register_#{row.id}_strength_form"}
                      type="text"
                      phx-hook="QualityAssuranceInput"
                      phx-value-day={row.id}
                      phx-value-field="strength_form"
                      value={Map.get(entry, "strength_form", "")}
                      class="w-36 rounded border border-gray-300 px-2 py-1"
                    />
                  </td>
                  <td class="border border-gray-300 px-2 py-1">
                    <input
                      id={"register_#{row.id}_batch_number"}
                      type="text"
                      phx-hook="QualityAssuranceInput"
                      phx-value-day={row.id}
                      phx-value-field="batch_number"
                      value={Map.get(entry, "batch_number", "")}
                      class="w-32 rounded border border-gray-300 px-2 py-1"
                    />
                  </td>
                  <td class="border border-gray-300 px-2 py-1">
                    <input
                      id={"register_#{row.id}_quantity_received"}
                      type="number"
                      step="0.01"
                      min="0"
                      phx-hook="QualityAssuranceInput"
                      phx-value-day={row.id}
                      phx-value-field="quantity_received"
                      value={Map.get(entry, "quantity_received", "")}
                      class="w-28 rounded border border-gray-300 px-2 py-1"
                    />
                  </td>
                  <td class="border border-gray-300 px-2 py-1">
                    <input
                      id={"register_#{row.id}_quantity_dispensed"}
                      type="number"
                      step="0.01"
                      min="0"
                      phx-hook="QualityAssuranceInput"
                      phx-value-day={row.id}
                      phx-value-field="quantity_dispensed"
                      value={Map.get(entry, "quantity_dispensed", "")}
                      class="w-28 rounded border border-gray-300 px-2 py-1"
                    />
                  </td>
                  <td class="border border-gray-300 px-3 py-2 font-semibold text-slate-700">
                    {quantity_display(row.running_balance)}
                  </td>
                  <td class="border border-gray-300 px-2 py-1">
                    <input
                      id={"register_#{row.id}_prescriber"}
                      type="text"
                      phx-hook="QualityAssuranceInput"
                      phx-value-day={row.id}
                      phx-value-field="prescriber"
                      value={Map.get(entry, "prescriber", "")}
                      class="w-36 rounded border border-gray-300 px-2 py-1"
                    />
                  </td>
                  <td class="border border-gray-300 px-2 py-1">
                    <input
                      id={"register_#{row.id}_pharmacist"}
                      type="text"
                      phx-hook="QualityAssuranceInput"
                      phx-value-day={row.id}
                      phx-value-field="pharmacist"
                      value={Map.get(entry, "pharmacist", "")}
                      class="w-36 rounded border border-gray-300 px-2 py-1"
                    />
                  </td>
                  <td class="border border-gray-300 px-2 py-1">
                    <textarea
                      id={"register_#{row.id}_remarks"}
                      phx-hook="QualityAssuranceInput"
                      phx-value-day={row.id}
                      phx-value-field="remarks"
                      class="min-h-[42px] w-48 rounded border border-gray-300 px-2 py-1"
                    ><%= Map.get(entry, "remarks", "") %></textarea>
                  </td>
                  <td class="border border-gray-300 px-2 py-1">
                    <button
                      type="button"
                      phx-click="remove_entry"
                      phx-value-entry_id={row.id}
                      class="rounded border border-rose-200 px-3 py-1 text-xs font-medium text-rose-700 transition hover:bg-rose-50"
                    >
                      Remove
                    </button>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end
end
