defmodule MedcampWeb.StaffMealComponents do
  @moduledoc """
  Markup for the staff meals management page, shared between the reception and
  support staff panels. See `MedcampWeb.StaffMealLive.Shared` for the LiveView
  logic that drives it.
  """

  use Phoenix.Component

  import MedcampWeb.CoreComponents

  alias Medcamp.StaffMeals.StaffMealSupply
  alias Phoenix.LiveView.JS

  attr :summary, :map, required: true
  attr :supplies, :list, required: true
  attr :form, :any, required: true
  attr :show_form, :boolean, required: true
  attr :editing_id, :any, default: nil
  attr :filter_date_from, :string, default: ""
  attr :filter_date_to, :string, default: ""
  attr :filter_meal_type, :string, default: ""
  attr :filter_search, :string, default: ""

  def staff_meals_page(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <div class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm">
          <p class="text-sm text-gray-500">Deliveries</p>
          <p class="mt-2 text-3xl font-semibold text-[#373896]">{@summary.deliveries}</p>
        </div>
        <div class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm">
          <p class="text-sm text-gray-500">Lunch plates</p>
          <p class="mt-2 text-3xl font-semibold text-[#373896]">{@summary.lunch_plates}</p>
        </div>
        <div class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm">
          <p class="text-sm text-gray-500">Supper plates</p>
          <p class="mt-2 text-3xl font-semibold text-[#373896]">{@summary.supper_plates}</p>
        </div>
        <div class="rounded-xl border border-[#cfd0fb] bg-[#eef0ff] p-5 shadow-sm">
          <p class="text-sm text-gray-600">Amount payable to supplier</p>
          <p class="mt-2 text-2xl font-bold text-[#373896]">{money(@summary.amount_payable)}</p>
          <p class="mt-1 text-xs text-gray-500">
            {@summary.total_plates} plates · {period_label(@filter_date_from, @filter_date_to)}
          </p>
        </div>
      </div>

      <section class="rounded-xl border border-gray-100 bg-white p-6 shadow-sm">
        <.page_header
          icon_path="M3 3h18v2H3V3zm0 4h18v2H3V7zm0 4h12v2H3v-2zm0 4h18v2H3v-2zm0 4h12v2H3v-2z"
          title="Staff Meals"
          subtitle="Per-date record of meals supplied by the food vendor."
        >
          <:actions>
            <.button phx-click="open_new" class="bg-[#6667ab] hover:bg-[#5556a0]">
              + Record delivery
            </.button>
          </:actions>
        </.page_header>

        <div class="flex items-center gap-3 mb-4">
          <form phx-change="search" class="flex-1">
            <.search_input
              name="search"
              value={@filter_search}
              placeholder="Search by notes or recorded by"
            />
          </form>

          <.filter_drawer
            id="staff-meals-filters"
            title="Filter staff meals"
            apply_event="filter"
            clear_event="clear_filters"
            active_count={count_active_filters(assigns)}
          >
            <:group label="Date Range">
              <.date_range_fields
                from_name="filters[date_from]"
                to_name="filters[date_to]"
                from_value={@filter_date_from}
                to_value={@filter_date_to}
                disable_future={false}
              />
            </:group>

            <:group label="Meal">
              <select
                name="filters[meal_type]"
                class="w-full h-9 border border-gray-300 rounded-md px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
              >
                <option value="" selected={@filter_meal_type == ""}>All meals</option>
                <option
                  :for={{label, value} <- StaffMealSupply.meal_type_options()}
                  value={value}
                  selected={@filter_meal_type == value}
                >
                  {label}
                </option>
              </select>
            </:group>
          </.filter_drawer>
        </div>

        <.blank_state
          :if={@supplies == []}
          icon_path="M3 3h18v2H3V3zm0 4h18v2H3V7zm0 4h12v2H3v-2zm0 4h18v2H3v-2zm0 4h12v2H3v-2z"
          title="No meal deliveries found"
          description={
            if @filter_search != "" or count_active_filters(assigns) > 0,
              do: "No meal deliveries match the current filters.",
              else: "No meal deliveries have been recorded yet."
          }
        >
          <:actions :if={@filter_search != "" or count_active_filters(assigns) > 0}>
            <button phx-click="clear_filters" class="text-xs text-[#6667ab] hover:underline">
              Clear filters
            </button>
          </:actions>
        </.blank_state>

        <div :if={@supplies != []} class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead>
              <tr class="text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                <th class="px-3 py-3">Date</th>
                <th class="px-3 py-3">Meal</th>
                <th class="px-3 py-3 text-right">Plates</th>
                <th class="px-3 py-3 text-right">Rate</th>
                <th class="px-3 py-3 text-right">Amount</th>
                <th class="px-3 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 bg-white text-sm text-gray-700">
              <%= for supply <- @supplies do %>
                <tr class={@editing_id == supply.id && "bg-[#f5f6ff]"}>
                  <td class="px-3 py-4 align-top">
                    <div class="font-medium text-gray-900">{format_date(supply.supplied_on)}</div>
                    <div :if={supply.notes not in [nil, ""]} class="mt-1 text-xs text-gray-500">
                      {supply.notes}
                    </div>
                  </td>
                  <td class="px-3 py-4 align-top">
                    <span class={[
                      "inline-flex rounded-full px-2 py-0.5 text-xs font-medium",
                      supply.meal_type == "lunch" && "bg-sky-50 text-sky-700",
                      supply.meal_type == "supper" && "bg-indigo-50 text-indigo-700"
                    ]}>
                      {StaffMealSupply.meal_type_label(supply.meal_type)}
                    </span>
                  </td>
                  <td class="px-3 py-4 text-right align-top font-medium text-gray-900">
                    {supply.plates}
                  </td>
                  <td class="px-3 py-4 text-right align-top">{money(supply.price_per_plate)}</td>
                  <td class="px-3 py-4 text-right align-top font-semibold text-[#373896]">
                    {money(StaffMealSupply.amount_payable(supply))}
                  </td>
                  <td class="px-3 py-4 text-right align-top">
                    <div class="flex justify-end gap-3">
                      <button
                        type="button"
                        phx-click="edit"
                        phx-value-id={supply.id}
                        class="text-[#6667ab] hover:underline"
                      >
                        Edit
                      </button>
                      <button
                        type="button"
                        phx-click="delete"
                        phx-value-id={supply.id}
                        data-confirm="Remove this meal delivery record?"
                        class="text-red-600 hover:underline"
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
          <.pagination
            page={@page}
            total_pages={@total_pages}
            total_count={@total_count}
            per_page={@per_page}
          />
        </div>
      </section>

      <.modal :if={@show_form} id="staff-meal-modal" show on_cancel={JS.push("cancel_edit")}>
        <.header class="text-[#373896]">
          {if @editing_id, do: "Edit delivery", else: "Record delivery"}
          <:subtitle>
            Enter the meal, plates supplied and the rate per plate.
          </:subtitle>
        </.header>

        <.form for={@form} phx-change="validate" phx-submit="save" class="mt-4 space-y-4">
          <.input field={@form[:supplied_on]} type="date" label="Date supplied" />

          <div class="grid grid-cols-2 gap-4">
            <.input
              field={@form[:meal_type]}
              type="select"
              label="Meal"
              options={StaffMealSupply.meal_type_options()}
            />
            <.input field={@form[:plates]} type="number" min="1" label="Plates supplied" />
          </div>

          <.input field={@form[:price_per_plate]} type="number" min="0" label="Price per plate (KES)" />

          <.input
            field={@form[:notes]}
            type="textarea"
            label="Notes (optional)"
            placeholder="Any remarks about this delivery"
          />

          <div class="flex items-center gap-2">
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">
              {if @editing_id, do: "Update delivery", else: "Save delivery"}
            </.button>
            <button
              type="button"
              phx-click="cancel_edit"
              class="rounded-lg border border-gray-300 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100"
            >
              Cancel
            </button>
          </div>
        </.form>
      </.modal>
    </div>
    """
  end

  defp count_active_filters(assigns) do
    [assigns.filter_date_from, assigns.filter_date_to, assigns.filter_meal_type]
    |> Enum.count(&(&1 not in [nil, ""]))
  end

  defp format_date(%Date{} = date), do: Calendar.strftime(date, "%a, %d %b %Y")
  defp format_date(_), do: "-"

  defp period_label("", ""), do: "all dates"
  defp period_label(from, ""), do: "from #{pretty_date(from)}"
  defp period_label("", to), do: "up to #{pretty_date(to)}"
  defp period_label(from, to), do: "#{pretty_date(from)} – #{pretty_date(to)}"

  defp pretty_date(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> Calendar.strftime(date, "%d %b %Y")
      _ -> value
    end
  end

  defp money(amount) when is_integer(amount), do: "KES " <> format_thousands(amount)
  defp money(_), do: "KES 0"

  defp format_thousands(number) do
    number
    |> Integer.to_string()
    |> String.replace(~r/\B(?=(\d{3})+(?!\d))/, ",")
  end
end
