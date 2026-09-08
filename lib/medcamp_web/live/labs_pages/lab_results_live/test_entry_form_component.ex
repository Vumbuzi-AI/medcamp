defmodule MedcampWeb.LabPagesLabResultLive.TestEntryFormComponent do
  @moduledoc """
  Dynamic form component for filling in lab test results.
  Renders form fields based on the selected test template.
  """
  use MedcampWeb, :live_component

  alias Medcamp.LabTestTemplates
  alias Medcamp.LabTestTemplates.LabTestEntry

  @impl true
  def render(assigns) do
    ~H"""
    <div>
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
              d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
            />
          </svg>
          {@template.name}
        </div>
        <:subtitle>
          <span class="text-sm text-gray-500">
            Fill in the test results for this investigation
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

      <.simple_form
        for={@form}
        id="test-entry-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="mt-6"
      >
        <!-- Sample Collection Info -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 p-4 bg-gray-50 rounded-lg mb-6">
          <.input
            field={@form[:sample_collected_on]}
            type="date"
            label="Sample Collected On"
            required
          />
          <.input
            field={@form[:test_performed_on]}
            type="date"
            label="Test Performed On"
            value={Date.utc_today() |> Date.to_iso8601()}
            required
          />
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
                <.dynamic_field
                  field={field}
                  form={@form}
                  existing_value={get_existing_value(@entry, field)}
                />
              <% end %>
            </div>
          </div>
        <% end %>
        
    <!-- Remarks -->
        <div class="mt-6">
          <.input
            field={@form[:remarks]}
            type="textarea"
            label="Remarks / Additional Notes"
            placeholder="Enter any additional observations or comments..."
          />
        </div>

        <:actions>
          <.button
            type="submit"
            phx-disable-with="Saving..."
            class="bg-brand-accent hover:bg-brand-accent-dark"
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
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  # Dynamic field component
  defp dynamic_field(assigns) do
    field_name = assigns.field["name"] || assigns.field[:name]
    field_type = assigns.field["type"] || assigns.field[:type] || "text"

    assigns = assign(assigns, :field_name, field_name)
    assigns = assign(assigns, :field_type, field_type)

    ~H"""
    <div class="relative">
      <%= case @field_type do %>
        <% "number" -> %>
          <.number_field field={@field} form={@form} existing_value={@existing_value} />
        <% "select" -> %>
          <.select_field field={@field} form={@form} existing_value={@existing_value} />
        <% "boolean" -> %>
          <.boolean_field field={@field} form={@form} existing_value={@existing_value} />
        <% _ -> %>
          <.text_field field={@field} form={@form} existing_value={@existing_value} />
      <% end %>
    </div>
    """
  end

  defp number_field(assigns) do
    field_name = assigns.field["name"] || assigns.field[:name]
    label = assigns.field["label"] || assigns.field[:label]
    unit = assigns.field["unit"] || assigns.field[:unit]
    ref_range = assigns.field["ref_range_text"] || assigns.field[:ref_range_text]
    required = assigns.field["required"] || assigns.field[:required] || false

    assigns =
      assigns
      |> assign(:field_name, field_name)
      |> assign(:label, label)
      |> assign(:unit, unit)
      |> assign(:ref_range, ref_range)
      |> assign(:required, required)

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
      <input
        type="number"
        step="any"
        name={"results[#{@field_name}]"}
        value={@existing_value}
        class="block w-full rounded-md border-gray-300 shadow-sm focus:border-brand-accent focus:ring-brand-accent sm:text-sm"
        placeholder={@ref_range}
      />
      <%= if @ref_range do %>
        <p class="mt-1 text-xs text-gray-500">Ref: {@ref_range}</p>
      <% end %>
    </div>
    """
  end

  defp text_field(assigns) do
    field_name = assigns.field["name"] || assigns.field[:name]
    label = assigns.field["label"] || assigns.field[:label]
    required = assigns.field["required"] || assigns.field[:required] || false

    assigns =
      assigns
      |> assign(:field_name, field_name)
      |> assign(:label, label)
      |> assign(:required, required)

    ~H"""
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-1">
        {@label}
        <%= if @required do %>
          <span class="text-red-500">*</span>
        <% end %>
      </label>
      <input
        type="text"
        name={"results[#{@field_name}]"}
        value={@existing_value}
        class="block w-full rounded-md border-gray-300 shadow-sm focus:border-brand-accent focus:ring-brand-accent sm:text-sm"
      />
    </div>
    """
  end

  defp select_field(assigns) do
    field_name = assigns.field["name"] || assigns.field[:name]
    label = assigns.field["label"] || assigns.field[:label]
    options = assigns.field["options"] || assigns.field[:options] || []
    required = assigns.field["required"] || assigns.field[:required] || false

    assigns =
      assigns
      |> assign(:field_name, field_name)
      |> assign(:label, label)
      |> assign(:options, options)
      |> assign(:required, required)

    ~H"""
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-1">
        {@label}
        <%= if @required do %>
          <span class="text-red-500">*</span>
        <% end %>
      </label>
      <select
        name={"results[#{@field_name}]"}
        class="block w-full rounded-md border-gray-300 shadow-sm focus:border-brand-accent focus:ring-brand-accent sm:text-sm"
      >
        <option value="">Select...</option>
        <%= for option <- @options do %>
          <option value={option} selected={@existing_value == option}>{option}</option>
        <% end %>
      </select>
    </div>
    """
  end

  defp boolean_field(assigns) do
    field_name = assigns.field["name"] || assigns.field[:name]
    label = assigns.field["label"] || assigns.field[:label]

    assigns =
      assigns
      |> assign(:field_name, field_name)
      |> assign(:label, label)

    ~H"""
    <div class="flex items-center">
      <input
        type="checkbox"
        name={"results[#{@field_name}]"}
        value="true"
        checked={@existing_value == "true" || @existing_value == true}
        class="h-4 w-4 rounded border-gray-300 text-brand-accent focus:ring-brand-accent"
      />
      <label class="ml-2 block text-sm text-gray-700">
        {@label}
      </label>
    </div>
    """
  end

  defp get_existing_value(nil, _field), do: nil
  defp get_existing_value(%{results: nil}, _field), do: nil

  defp get_existing_value(%{results: results}, field) do
    field_name = field["name"] || field[:name]

    case Map.get(results, field_name) do
      %{"value" => value} -> value
      value when is_binary(value) -> value
      _ -> nil
    end
  end

  @impl true
  def update(%{template: template, entry: entry} = assigns, socket) do
    grouped_fields =
      template.field_definitions
      |> Enum.sort_by(fn f -> f["display_order"] || f[:display_order] || 999 end)
      |> Enum.group_by(fn f -> f["section"] || f[:section] || "main" end)

    changeset =
      LabTestEntry.results_changeset(
        entry || %LabTestEntry{},
        %{}
      )

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:grouped_fields, grouped_fields)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"results" => results} = params, socket) do
    entry_params = Map.get(params, "lab_test_entry", %{})
    notes = Map.get(params, "notes", %{})

    sample_collected_on = entry_params["sample_collected_on"]
    test_performed_on = entry_params["test_performed_on"]
    remarks = entry_params["remarks"]

    case LabTestTemplates.fill_entry_results(
           socket.assigns.entry,
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

        {:noreply,
         socket
         |> put_flash(:info, "Test results saved successfully")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Error saving test results")
         |> assign(:form, to_form(changeset))}
    end
  end
end
