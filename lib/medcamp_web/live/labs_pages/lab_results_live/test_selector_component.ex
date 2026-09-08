defmodule MedcampWeb.LabPagesLabResultLive.TestSelectorComponent do
  @moduledoc """
  Component for selecting which lab test to add to a lab request.
  After selecting a test, shows the form to fill results immediately.
  """
  use MedcampWeb, :live_component

  alias Medcamp.LabTestTemplates

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @selected_entry do %>
        <!-- Show Form After Selection -->
        <.test_entry_form
          entry={@selected_entry}
          template={@selected_template}
          patient_name={@patient_name}
          doctor_name={@doctor_name}
          requested_on={@requested_on}
          lab_result_id={@lab_result_id}
          grouped_fields={@grouped_fields}
          form={@form}
          myself={@myself}
        />
      <% else %>
        <!-- Test Selection View -->
        <.header>
          <div class="flex items-center gap-2">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5 text-brand-accent"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 6v6m0 0v6m0-6h6m-6 0H6"
              />
            </svg>
            Add Lab Test
          </div>
          <:subtitle>
            Select a test type to add results
          </:subtitle>
        </.header>
        
    <!-- Search -->
        <div class="mt-4">
          <form phx-change="search" phx-target={@myself}>
            <div class="relative">
              <svg
                class="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                />
              </svg>
              <input
                type="text"
                name="query"
                value={@search_query}
                placeholder="Search tests (e.g., FBC, Urinalysis, HIV)..."
                class="block w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-brand-accent focus:border-brand-accent"
                phx-debounce="300"
              />
            </div>
          </form>
        </div>
        
    <!-- Already Added Tests -->
        <%= if length(@existing_template_ids) > 0 do %>
          <div class="mt-4 p-3 bg-blue-50 rounded-lg border border-blue-100">
            <p class="text-sm text-blue-800">
              <span class="font-medium">{length(@existing_template_ids)}</span>
              test(s) already added to this request
            </p>
          </div>
        <% end %>
        
    <!-- Test Selection Grid -->
        <div class="mt-6 space-y-6 max-h-[60vh] overflow-y-auto">
          <%= if @search_query != "" do %>
            <!-- Search Results -->
            <div>
              <h3 class="text-sm font-medium text-gray-500 mb-3">Search Results</h3>
              <%= if Enum.empty?(@search_results) do %>
                <p class="text-sm text-gray-500 text-center py-4">
                  No tests found matching "{@search_query}"
                </p>
              <% else %>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                  <%= for template <- @search_results do %>
                    <.test_card
                      template={template}
                      is_added={template.id in @existing_template_ids}
                      myself={@myself}
                    />
                  <% end %>
                </div>
              <% end %>
            </div>
          <% else %>
            <!-- Grouped by Category -->
            <%= for {category, templates} <- @grouped_templates do %>
              <%= if category do %>
                <div>
                  <h3 class="text-sm font-semibold text-brand-primary uppercase tracking-wide mb-3 flex items-center">
                    <span class="w-2 h-2 rounded-full bg-brand-accent mr-2"></span>
                    {category.name}
                  </h3>
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                    <%= for template <- templates do %>
                      <.test_card
                        template={template}
                        is_added={template.id in @existing_template_ids}
                        myself={@myself}
                      />
                    <% end %>
                  </div>
                </div>
              <% end %>
            <% end %>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp test_card(assigns) do
    ~H"""
    <div class={[
      "p-4 rounded-lg border-2 transition-all",
      if(@is_added,
        do: "bg-green-50 border-green-200 opacity-60",
        else: "bg-white border-gray-200 hover:border-brand-accent hover:shadow-md cursor-pointer"
      )
    ]}>
      <div class="flex items-start justify-between">
        <div class="flex-1">
          <h4 class="font-medium text-gray-900">{@template.name}</h4>
          <%= if @template.short_name do %>
            <span class="text-xs text-gray-500">({@template.short_name})</span>
          <% end %>
          <p class="text-sm text-gray-500 mt-1">
            {length(@template.field_definitions)} parameter(s)
          </p>
        </div>

        <%= if @is_added do %>
          <span class="flex items-center text-green-600 text-sm">
            <svg class="h-5 w-5 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M5 13l4 4L19 7"
              />
            </svg>
            Added
          </span>
        <% else %>
          <button
            type="button"
            phx-click="select_and_add"
            phx-value-template-id={@template.id}
            phx-target={@myself}
            class="px-3 py-1.5 text-sm font-medium text-white bg-brand-accent rounded-lg hover:bg-brand-accent-dark transition-colors"
          >
            Select & Add Results
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  # Form component shown after selecting a test
  defp test_entry_form(assigns) do
    ~H"""
    <div>
      <.header>
        <div class="flex items-center gap-2">
          <button
            type="button"
            phx-click="back_to_selection"
            phx-target={@myself}
            class="p-1 rounded-lg hover:bg-gray-100 text-gray-500"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5"
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
          </button>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5 text-brand-accent"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
            />
          </svg>
          {@template.name}
        </div>
        <:subtitle>
          <span class="text-sm text-gray-500">
            Fill in the test results below
          </span>
        </:subtitle>
      </.header>
      
    <!-- Patient Info Banner -->
      <div class="mt-4 p-4 bg-blue-50 rounded-lg border border-blue-100">
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
          <div>
            <span class="text-gray-500">Patient:</span>
            <span class="ml-1 font-medium text-gray-900">{@patient_name}</span>
          </div>
          <div>
            <span class="text-gray-500">Lab Test No:</span>
            <span class="ml-1 font-medium text-gray-900">{@lab_result_id}</span>
          </div>
          <div>
            <span class="text-gray-500">Requested On:</span>
            <span class="ml-1 font-medium text-gray-900">{@requested_on}</span>
          </div>
          <div>
            <span class="text-gray-500">Doctor:</span>
            <span class="ml-1 font-medium text-gray-900">{@doctor_name}</span>
          </div>
        </div>
      </div>

      <form id="test-entry-form" phx-target={@myself} phx-submit="save_results" class="mt-6">
        <!-- Sample Collection Info -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 p-4 bg-gray-50 rounded-lg mb-6">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Sample Collected On <span class="text-red-500">*</span>
            </label>
            <input
              type="date"
              name="sample_collected_on"
              required
              class="block w-full rounded-md border-gray-300 shadow-sm focus:border-brand-accent focus:ring-brand-accent sm:text-sm"
            />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Test Performed On <span class="text-red-500">*</span>
            </label>
            <input
              type="date"
              name="test_performed_on"
              value={Date.utc_today() |> Date.to_iso8601()}
              required
              class="block w-full rounded-md border-gray-300 shadow-sm focus:border-brand-accent focus:ring-brand-accent sm:text-sm"
            />
          </div>
        </div>
        
    <!-- Dynamic Test Fields -->
        <%= for {section, fields} <- @grouped_fields do %>
          <div class="mb-6">
            <%= if section != "main" do %>
              <h3 class="text-sm font-semibold text-brand-primary uppercase tracking-wide mb-3 pb-2 border-b border-gray-200">
                {section}
              </h3>
            <% end %>

            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              <%= for field <- fields do %>
                <.dynamic_field field={field} />
              <% end %>
            </div>
          </div>
        <% end %>
        
    <!-- Remarks -->
        <div class="mt-6">
          <label class="block text-sm font-medium text-gray-700 mb-1">
            Remarks / Additional Notes
          </label>
          <textarea
            name="remarks"
            rows="3"
            placeholder="Enter any additional observations or comments..."
            class="block w-full rounded-md border-gray-300 shadow-sm focus:border-brand-accent focus:ring-brand-accent sm:text-sm"
          ></textarea>
        </div>
        
    <!-- Actions -->
        <div class="mt-6 flex justify-end gap-3">
          <button
            type="button"
            phx-click="back_to_selection"
            phx-target={@myself}
            class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50"
          >
            Cancel
          </button>
          <button
            type="submit"
            class="px-4 py-2 text-sm font-medium text-white bg-brand-accent rounded-lg hover:bg-brand-accent-dark flex items-center"
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
                d="M5 13l4 4L19 7"
              />
            </svg>
            Save Results
          </button>
        </div>
      </form>
    </div>
    """
  end

  defp dynamic_field(assigns) do
    field_name = assigns.field["name"] || assigns.field[:name]
    field_type = assigns.field["type"] || assigns.field[:type] || "text"
    label = assigns.field["label"] || assigns.field[:label]
    unit = assigns.field["unit"] || assigns.field[:unit]
    ref_range = assigns.field["ref_range_text"] || assigns.field[:ref_range_text]
    required = assigns.field["required"] || assigns.field[:required] || false
    options = assigns.field["options"] || assigns.field[:options] || []

    assigns =
      assigns
      |> assign(:field_name, field_name)
      |> assign(:field_type, field_type)
      |> assign(:label, label)
      |> assign(:unit, unit)
      |> assign(:ref_range, ref_range)
      |> assign(:required, required)
      |> assign(:options, options)

    ~H"""
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-1">
        {@label}
        <%= if @required do %>
          <span class="text-red-500">*</span>
        <% end %>
        <%= if @unit do %>
          <span class="text-gray-400 font-normal">({@unit})</span>
        <% end %>
      </label>

      <%= case @field_type do %>
        <% "number" -> %>
          <input
            type="number"
            step="any"
            name={"results[#{@field_name}]"}
            class="block w-full rounded-md border-gray-300 shadow-sm focus:border-brand-accent focus:ring-brand-accent sm:text-sm"
            placeholder={@ref_range}
          />
        <% "select" -> %>
          <select
            name={"results[#{@field_name}]"}
            class="block w-full rounded-md border-gray-300 shadow-sm focus:border-brand-accent focus:ring-brand-accent sm:text-sm"
          >
            <option value="">Select...</option>
            <%= for option <- @options do %>
              <option value={option}>{option}</option>
            <% end %>
          </select>
        <% _ -> %>
          <input
            type="text"
            name={"results[#{@field_name}]"}
            class="block w-full rounded-md border-gray-300 shadow-sm focus:border-brand-accent focus:ring-brand-accent sm:text-sm"
          />
      <% end %>

      <%= if @ref_range do %>
        <p class="mt-1 text-xs text-gray-500">Ref: {@ref_range}</p>
      <% end %>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    grouped_templates = LabTestTemplates.list_templates_grouped_by_category()
    existing_template_ids = LabTestTemplates.get_existing_template_ids(assigns.lab_result_id)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:grouped_templates, grouped_templates)
     |> assign(:existing_template_ids, existing_template_ids)
     |> assign(:search_query, "")
     |> assign(:search_results, [])
     |> assign(:selected_entry, nil)
     |> assign(:selected_template, nil)
     |> assign(:grouped_fields, [])
     |> assign(:form, nil)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    search_results =
      if String.trim(query) != "" do
        LabTestTemplates.search_templates(query)
      else
        []
      end

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:search_results, search_results)}
  end

  def handle_event("select_and_add", %{"template-id" => template_id}, socket) do
    template_id = String.to_integer(template_id)

    case LabTestTemplates.add_test_to_lab_result(socket.assigns.lab_result_id, template_id) do
      {:ok, entry} ->
        template = LabTestTemplates.get_template!(template_id)

        grouped_fields =
          template.field_definitions
          |> Enum.sort_by(fn f -> f["display_order"] || f[:display_order] || 999 end)
          |> Enum.group_by(fn f -> f["section"] || f[:section] || "main" end)

        # Update existing IDs
        existing_ids = [template_id | socket.assigns.existing_template_ids]

        {:noreply,
         socket
         |> assign(:selected_entry, entry)
         |> assign(:selected_template, template)
         |> assign(:grouped_fields, grouped_fields)
         |> assign(:existing_template_ids, existing_ids)}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not add test. It may already exist.")}
    end
  end

  def handle_event("back_to_selection", _params, socket) do
    # Notify parent that a test was added (even if not filled)
    send(self(), {:test_added, socket.assigns.selected_entry})

    {:noreply,
     socket
     |> assign(:selected_entry, nil)
     |> assign(:selected_template, nil)
     |> assign(:grouped_fields, [])}
  end

  def handle_event("save_results", %{"results" => results} = params, socket) do
    sample_collected_on = params["sample_collected_on"]
    test_performed_on = params["test_performed_on"]
    remarks = params["remarks"]
    notes = Map.get(params, "notes", %{})

    case LabTestTemplates.fill_entry_results(
           socket.assigns.selected_entry,
           results,
           notes,
           socket.assigns.current_user.id
         ) do
      {:ok, entry} ->
        # Update additional fields
        LabTestTemplates.update_entry_results(entry, %{
          sample_collected_on: sample_collected_on,
          test_performed_on: test_performed_on,
          remarks: remarks
        })

        # Notify parent
        send(self(), {:test_added, entry})
        send(self(), :close_modal)

        {:noreply,
         socket
         |> put_flash(:info, "Test results saved successfully")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Error saving test results")}
    end
  end

  def handle_event("save_results", _params, socket) do
    {:noreply, socket |> put_flash(:error, "Please fill in the results")}
  end
end
