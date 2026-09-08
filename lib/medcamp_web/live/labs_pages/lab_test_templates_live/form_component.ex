defmodule MedcampWeb.LabPagesLabTestTemplateLive.FormComponent do
  use Phoenix.LiveComponent

  import Phoenix.Component
  import MedcampWeb.CoreComponents

  alias Medcamp.LabTestTemplates

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>
          Define test parameters, reference ranges, and field types
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="template-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-4">
          <.input
            field={@form[:name]}
            type="text"
            label="Template Name"
            placeholder="e.g., Full Blood Count"
            required
          />

          <.input
            field={@form[:short_name]}
            type="text"
            label="Short Name"
            placeholder="e.g., FBC"
            required
          />

          <.input
            field={@form[:category_id]}
            type="select"
            label="Category"
            options={@category_options}
            prompt="Select a category"
            required
          />
        </div>

        <div class="mt-8">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Test Parameters (JSON Format)</h3>

          <div class="mb-4">
            <label class="block text-sm font-semibold text-gray-900 mb-2">
              Field Definitions
            </label>
            <textarea
              name="lab_test_template[field_definitions_json]"
              rows="20"
              phx-debounce="500"
              class="mt-2 block w-full rounded-lg border-gray-300 focus:border-brand-accent focus:ring-brand-accent text-sm font-mono"
            >{@field_definitions_json}</textarea>
          </div>

          <div class="mt-2 p-4 bg-blue-50 border border-blue-200 rounded-lg">
            <h4 class="text-sm font-semibold text-blue-900 mb-2">Example Format:</h4>
            <pre class="text-xs text-blue-800 overflow-x-auto whitespace-pre"><%= json_example() %></pre>
          </div>

          <div class="mt-4 p-4 bg-amber-50 border border-amber-200 rounded-lg">
            <h4 class="text-sm font-semibold text-amber-900 mb-2">Field Options:</h4>
            <ul class="text-xs text-amber-800 space-y-1">
              <li><strong>type:</strong> "number", "text", or "select"</li>
              <li><strong>section:</strong> (optional) Group fields</li>
              <li><strong>options:</strong> (for select) Array like ["Negative", "Positive"]</li>
              <li><strong>ref_range_min/max:</strong> (for number) Numeric values</li>
              <li><strong>ref_range_text:</strong> Display text for reference range</li>
              <li><strong>required:</strong> true or false</li>
              <li><strong>display_order:</strong> Number for ordering</li>
            </ul>
          </div>

          <%= if @json_error do %>
            <div class="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg">
              <p class="text-sm font-semibold text-red-900">JSON Error:</p>
              <p class="text-sm text-red-800">{@json_error}</p>
            </div>
          <% end %>
        </div>

        <:actions>
          <.button
            phx-disable-with="Saving..."
            class="w-full bg-brand-accent hover:bg-brand-accent-dark"
          >
            Save Template
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  defp json_example do
    """
    [
    {
    "name": "hemoglobin",
    "label": "Hemoglobin (HGB)",
    "type": "number",
    "unit": "g/dL",
    "ref_range_min": 12.0,
    "ref_range_max": 16.0,
    "ref_range_text": "12-16 g/dL",
    "required": true,
    "display_order": 1
    },
    {
    "name": "wbc",
    "label": "White Blood Cells",
    "type": "number",
    "unit": "10^9/L",
    "ref_range_min": 4.0,
    "ref_range_max": 11.0,
    "ref_range_text": "4-11 10^9/L",
    "required": true,
    "display_order": 2
    }
    ]
    """
  end

  @impl true
  def update(%{template: template} = assigns, socket) do
    categories = LabTestTemplates.list_categories()
    category_options = Enum.map(categories, fn cat -> {cat.name, cat.id} end)

    # Convert field_definitions to JSON string for display
    field_definitions_json =
      case template.field_definitions do
        [] -> "[]"
        definitions -> Jason.encode!(definitions, pretty: true)
      end

    changeset = LabTestTemplates.change_template(template)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:category_options, category_options)
     |> assign(:json_error, nil)
     |> assign(:field_definitions_json, field_definitions_json)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"lab_test_template" => template_params}, socket) do
    {changeset, json_error} =
      case parse_field_definitions(template_params["field_definitions_json"]) do
        {:ok, field_definitions} ->
          params = Map.put(template_params, "field_definitions", field_definitions)

          changeset =
            socket.assigns.template
            |> LabTestTemplates.change_template(params)
            |> Map.put(:action, :validate)

          {changeset, nil}

        {:error, error} ->
          changeset =
            socket.assigns.template
            |> LabTestTemplates.change_template(template_params)
            |> Map.put(:action, :validate)

          {changeset, error}
      end

    {:noreply,
     socket
     |> assign(:json_error, json_error)
     |> assign_form(changeset)}
  end

  def handle_event("save", %{"lab_test_template" => template_params}, socket) do
    case parse_field_definitions(template_params["field_definitions_json"]) do
      {:ok, field_definitions} ->
        params =
          template_params
          |> Map.put("field_definitions", field_definitions)
          |> Map.delete("field_definitions_json")

        save_template(socket, socket.assigns.action, params)

      {:error, error} ->
        {:noreply, assign(socket, :json_error, error)}
    end
  end

  defp parse_field_definitions(nil), do: {:ok, []}
  defp parse_field_definitions(""), do: {:ok, []}

  defp parse_field_definitions(json_string) do
    case Jason.decode(json_string) do
      {:ok, field_definitions} when is_list(field_definitions) ->
        {:ok, field_definitions}

      {:ok, _} ->
        {:error, "Field definitions must be a JSON array"}

      {:error, %Jason.DecodeError{} = error} ->
        {:error, Exception.message(error)}
    end
  end

  defp save_template(socket, :edit, template_params) do
    case LabTestTemplates.update_template(socket.assigns.template, template_params) do
      {:ok, template} ->
        notify_parent({:saved, template})

        {:noreply,
         socket
         |> put_flash(:info, "Template updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_template(socket, :new, template_params) do
    case LabTestTemplates.create_template(template_params) do
      {:ok, template} ->
        notify_parent({:saved, template})

        {:noreply,
         socket
         |> put_flash(:info, "Template created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
