defmodule MedcampWeb.LabPagesLabTestTemplateLive.FormComponent do
  use Phoenix.LiveComponent

  import Phoenix.Component
  import MedcampWeb.CoreComponents

  alias Medcamp.LabTestTemplates

  @field_types ~w(number text select boolean)

  @blank_row %{
    "name" => "",
    "label" => "",
    "type" => "number",
    "unit" => "",
    "ref_range_min" => "",
    "ref_range_max" => "",
    "ref_range_text" => "",
    "options" => "",
    "section" => "",
    "required" => "false"
  }

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
          <div class="flex items-center justify-between">
            <h3 class="text-base font-semibold text-slate-900">Test parameters</h3>
            <button
              type="button"
              phx-click="toggle_json"
              phx-target={@myself}
              class="text-xs font-semibold text-brand-accent hover:underline"
            >
              {if @show_json, do: "Back to builder", else: "Paste JSON instead"}
            </button>
          </div>

          <div :if={not @show_json} class="mt-4 space-y-3">
            <p
              :if={@field_rows == []}
              class="rounded-xl border border-dashed border-slate-300 bg-slate-50 px-4 py-6 text-center text-sm text-slate-500"
            >
              No parameters yet. Add the first one below.
            </p>

            <div
              :for={{row, index} <- Enum.with_index(@field_rows)}
              class="rounded-xl border border-slate-200 bg-white p-4"
            >
              <div class="flex items-start justify-between gap-3">
                <p class="text-xs font-semibold uppercase tracking-wide text-slate-400">
                  Parameter {index + 1}
                </p>
                <button
                  type="button"
                  phx-click="remove_parameter"
                  phx-value-index={index}
                  phx-target={@myself}
                  class="text-xs font-semibold text-rose-600 hover:underline"
                >
                  Remove
                </button>
              </div>

              <div class="mt-3 grid grid-cols-1 gap-3 sm:grid-cols-2 [&>*]:min-w-0">
                <label class="block text-sm">
                  <span class="font-medium text-slate-700">Label</span>
                  <input
                    type="text"
                    name={"lab_test_template[fields][#{index}][label]"}
                    value={row["label"]}
                    phx-debounce="blur"
                    placeholder="Hemoglobin (HGB)"
                    class="mt-1 block w-full rounded-lg border-slate-300 text-sm focus:border-brand-accent focus:ring-brand-accent"
                  />
                </label>

                <label class="block text-sm">
                  <span class="font-medium text-slate-700">Field key</span>
                  <input
                    type="text"
                    name={"lab_test_template[fields][#{index}][name]"}
                    value={row["name"]}
                    phx-debounce="blur"
                    placeholder="hemoglobin (auto from label if blank)"
                    class="mt-1 block w-full rounded-lg border-slate-300 font-mono text-sm focus:border-brand-accent focus:ring-brand-accent"
                  />
                </label>

                <label class="block text-sm">
                  <span class="font-medium text-slate-700">Type</span>
                  <select
                    name={"lab_test_template[fields][#{index}][type]"}
                    class="mt-1 block w-full rounded-lg border-slate-300 text-sm focus:border-brand-accent focus:ring-brand-accent"
                  >
                    <option :for={t <- @field_types} value={t} selected={row["type"] == t}>
                      {t}
                    </option>
                  </select>
                </label>

                <label class="block text-sm">
                  <span class="font-medium text-slate-700">Unit</span>
                  <input
                    type="text"
                    name={"lab_test_template[fields][#{index}][unit]"}
                    value={row["unit"]}
                    phx-debounce="blur"
                    placeholder="g/dL"
                    class="mt-1 block w-full rounded-lg border-slate-300 text-sm focus:border-brand-accent focus:ring-brand-accent"
                  />
                </label>

                <label :if={row["type"] == "number"} class="block text-sm">
                  <span class="font-medium text-slate-700">Reference min</span>
                  <input
                    type="number"
                    step="any"
                    name={"lab_test_template[fields][#{index}][ref_range_min]"}
                    value={row["ref_range_min"]}
                    phx-debounce="blur"
                    class="mt-1 block w-full rounded-lg border-slate-300 text-sm focus:border-brand-accent focus:ring-brand-accent"
                  />
                </label>

                <label :if={row["type"] == "number"} class="block text-sm">
                  <span class="font-medium text-slate-700">Reference max</span>
                  <input
                    type="number"
                    step="any"
                    name={"lab_test_template[fields][#{index}][ref_range_max]"}
                    value={row["ref_range_max"]}
                    phx-debounce="blur"
                    class="mt-1 block w-full rounded-lg border-slate-300 text-sm focus:border-brand-accent focus:ring-brand-accent"
                  />
                </label>

                <label :if={row["type"] == "select"} class="block text-sm sm:col-span-2">
                  <span class="font-medium text-slate-700">Options (comma separated)</span>
                  <input
                    type="text"
                    name={"lab_test_template[fields][#{index}][options]"}
                    value={row["options"]}
                    phx-debounce="blur"
                    placeholder="Negative, Positive"
                    class="mt-1 block w-full rounded-lg border-slate-300 text-sm focus:border-brand-accent focus:ring-brand-accent"
                  />
                </label>

                <label class="block text-sm">
                  <span class="font-medium text-slate-700">Reference text</span>
                  <input
                    type="text"
                    name={"lab_test_template[fields][#{index}][ref_range_text]"}
                    value={row["ref_range_text"]}
                    phx-debounce="blur"
                    placeholder="12-16 g/dL"
                    class="mt-1 block w-full rounded-lg border-slate-300 text-sm focus:border-brand-accent focus:ring-brand-accent"
                  />
                </label>

                <label class="block text-sm">
                  <span class="font-medium text-slate-700">Section (optional)</span>
                  <input
                    type="text"
                    name={"lab_test_template[fields][#{index}][section]"}
                    value={row["section"]}
                    phx-debounce="blur"
                    placeholder="Microscopy"
                    class="mt-1 block w-full rounded-lg border-slate-300 text-sm focus:border-brand-accent focus:ring-brand-accent"
                  />
                </label>

                <label class="flex items-center gap-2 text-sm sm:col-span-2">
                  <input
                    type="hidden"
                    name={"lab_test_template[fields][#{index}][required]"}
                    value="false"
                  />
                  <input
                    type="checkbox"
                    name={"lab_test_template[fields][#{index}][required]"}
                    value="true"
                    checked={row["required"] in [true, "true"]}
                    class="h-4 w-4 rounded border-slate-300 text-brand-accent focus:ring-brand-accent"
                  />
                  <span class="text-slate-700">Required</span>
                </label>
              </div>
            </div>

            <button
              type="button"
              phx-click="add_parameter"
              phx-target={@myself}
              class="inline-flex items-center gap-1.5 rounded-full border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 transition-colors hover:bg-slate-100"
            >
              <.icon name="hero-plus" class="h-4 w-4" /> Add parameter
            </button>
          </div>

          <div :if={@show_json} class="mt-4">
            <label class="block text-sm font-semibold text-slate-900">
              Field definitions (JSON array)
            </label>
            <textarea
              name="lab_test_template[field_definitions_json]"
              rows="16"
              phx-debounce="500"
              class="mt-2 block w-full rounded-lg border-slate-300 font-mono text-sm focus:border-brand-accent focus:ring-brand-accent"
            >{@field_definitions_json}</textarea>
            <div class="mt-2 rounded-lg border border-blue-200 bg-blue-50 p-4">
              <h4 class="mb-2 text-sm font-semibold text-blue-900">Example</h4>
              <pre class="overflow-x-auto whitespace-pre text-xs text-blue-800"><%= json_example() %></pre>
            </div>
          </div>

          <div :if={@json_error} class="mt-4 rounded-lg border border-red-200 bg-red-50 p-4">
            <p class="text-sm font-semibold text-red-900">Could not read the parameters</p>
            <p class="text-sm text-red-800">{@json_error}</p>
          </div>
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
      }
    ]
    """
  end

  @impl true
  def update(%{template: template} = assigns, socket) do
    categories = LabTestTemplates.list_categories()
    category_options = Enum.map(categories, fn cat -> {cat.name, cat.id} end)

    rows = definitions_to_rows(template.field_definitions)

    changeset = LabTestTemplates.change_template(template)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:category_options, category_options)
     |> assign(:field_types, @field_types)
     |> assign(:json_error, nil)
     |> assign(:show_json, false)
     |> assign(:field_rows, rows)
     |> assign(:field_definitions_json, rows_to_json(rows))
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("add_parameter", _params, socket) do
    {:noreply, assign(socket, :field_rows, socket.assigns.field_rows ++ [@blank_row])}
  end

  def handle_event("remove_parameter", %{"index" => index}, socket) do
    rows = List.delete_at(socket.assigns.field_rows, String.to_integer(index))
    changeset = validate_changeset(socket, rows_to_definitions(rows))
    {:noreply, socket |> assign(:field_rows, rows) |> assign_form(changeset)}
  end

  def handle_event("toggle_json", _params, socket) do
    if socket.assigns.show_json do
      # Leaving JSON: parse it back into builder rows.
      case parse_field_definitions(socket.assigns.field_definitions_json) do
        {:ok, definitions} ->
          {:noreply,
           socket
           |> assign(:show_json, false)
           |> assign(:json_error, nil)
           |> assign(:field_rows, definitions_to_rows(definitions))}

        {:error, error} ->
          {:noreply, assign(socket, :json_error, error)}
      end
    else
      # Entering JSON: seed the textarea from the current rows.
      {:noreply,
       socket
       |> assign(:show_json, true)
       |> assign(:json_error, nil)
       |> assign(:field_definitions_json, rows_to_json(socket.assigns.field_rows))}
    end
  end

  @impl true
  def handle_event("validate", %{"lab_test_template" => template_params}, socket) do
    {definitions, rows, json, json_error} = read_parameters(socket, template_params)

    {:noreply,
     socket
     |> assign(:field_rows, rows)
     |> assign(:field_definitions_json, json)
     |> assign(:json_error, json_error)
     |> assign_form(validate_changeset(socket, definitions, template_params))}
  end

  def handle_event("save", %{"lab_test_template" => template_params}, socket) do
    {definitions, _rows, _json, json_error} = read_parameters(socket, template_params)

    if json_error do
      {:noreply, assign(socket, :json_error, json_error)}
    else
      params =
        template_params
        |> Map.put("field_definitions", definitions)
        |> Map.delete("field_definitions_json")
        |> Map.delete("fields")

      save_template(socket, socket.assigns.action, params)
    end
  end

  # Returns `{definitions, rows, json_string, json_error}` for the active mode.
  defp read_parameters(%{assigns: %{show_json: true}}, template_params) do
    json = template_params["field_definitions_json"] || "[]"

    case parse_field_definitions(json) do
      {:ok, definitions} -> {definitions, definitions_to_rows(definitions), json, nil}
      {:error, error} -> {[], [], json, error}
    end
  end

  defp read_parameters(_socket, template_params) do
    rows = params_to_rows(template_params["fields"])
    definitions = rows_to_definitions(rows)
    {definitions, rows, rows_to_json(rows), nil}
  end

  defp validate_changeset(socket, definitions, template_params \\ %{}) do
    socket.assigns.template
    |> LabTestTemplates.change_template(
      Map.put(template_params, "field_definitions", definitions)
    )
    |> Map.put(:action, :validate)
  end

  # --- row <-> definition conversion -------------------------------------------

  defp params_to_rows(nil), do: []

  defp params_to_rows(fields) when is_map(fields) do
    fields
    |> Enum.sort_by(fn {k, _} -> String.to_integer(k) end)
    |> Enum.map(fn {_k, v} -> Map.merge(@blank_row, v) end)
  end

  defp rows_to_definitions(rows) do
    rows
    |> Enum.reject(&blank_row?/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, order} ->
      label = presence(row["label"]) || presence(row["name"]) || "Parameter #{order}"

      %{
        "name" => presence(row["name"]) || slugify(label),
        "label" => label,
        "type" => (row["type"] in @field_types && row["type"]) || "number",
        "unit" => presence(row["unit"]),
        "ref_range_min" => to_number(row["ref_range_min"]),
        "ref_range_max" => to_number(row["ref_range_max"]),
        "ref_range_text" => presence(row["ref_range_text"]),
        "options" => parse_options(row["options"]),
        "section" => presence(row["section"]),
        "required" => row["required"] in [true, "true"],
        "display_order" => order
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()
    end)
  end

  defp definitions_to_rows(nil), do: []
  defp definitions_to_rows([]), do: []

  defp definitions_to_rows(definitions) when is_list(definitions) do
    Enum.map(definitions, fn field ->
      %{
        "name" => to_string(get_def(field, "name")),
        "label" => to_string(get_def(field, "label")),
        "type" => to_string(get_def(field, "type") || "number"),
        "unit" => to_string(get_def(field, "unit")),
        "ref_range_min" => number_to_string(get_def(field, "ref_range_min")),
        "ref_range_max" => number_to_string(get_def(field, "ref_range_max")),
        "ref_range_text" => to_string(get_def(field, "ref_range_text")),
        "options" => field |> get_def("options") |> options_to_string(),
        "section" => to_string(get_def(field, "section")),
        "required" => (get_def(field, "required") == true && "true") || "false"
      }
    end)
  end

  defp definitions_to_rows(_), do: []

  defp get_def(field, key) when is_map(field), do: field[key] || field[String.to_atom(key)]

  defp rows_to_json(rows) do
    rows
    |> rows_to_definitions()
    |> Jason.encode!(pretty: true)
  end

  defp blank_row?(row) do
    ~w(name label unit ref_range_min ref_range_max ref_range_text options section)
    |> Enum.all?(fn key -> presence(row[key]) == nil end)
  end

  defp presence(nil), do: nil

  defp presence(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp presence(value), do: value

  defp to_number(value) do
    case presence(value) do
      nil ->
        nil

      string ->
        case Float.parse(string) do
          {float, _} -> float
          :error -> nil
        end
    end
  end

  defp number_to_string(nil), do: ""
  defp number_to_string(number) when is_float(number), do: to_string(number)
  defp number_to_string(number) when is_integer(number), do: to_string(number)
  defp number_to_string(other), do: to_string(other)

  defp parse_options(value) do
    case presence(value) do
      nil ->
        nil

      string ->
        string
        |> String.split(",", trim: true)
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
        |> case do
          [] -> nil
          list -> list
        end
    end
  end

  defp options_to_string(options) when is_list(options), do: Enum.join(options, ", ")
  defp options_to_string(_), do: ""

  defp slugify(label) do
    label
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "_")
    |> String.trim("_")
    |> case do
      "" -> "field"
      slug -> slug
    end
  end

  # --- JSON fallback ---------------------------------------------------------

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
