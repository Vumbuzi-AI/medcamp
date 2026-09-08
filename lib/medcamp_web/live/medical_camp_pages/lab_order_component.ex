defmodule MedcampWeb.MedicalCampPages.LabOrderComponent do
  use MedcampWeb, :live_component
  alias Medcamp.LabResults
  alias Medcamp.LabResults.LabResult
  alias Medcamp.LabTests
  alias Medcamp.LabTests.LabTest

  @camp_test_names ~w(FHG Ova/Cyst Urinalysis Pylori Random)

  @impl true
  def update(assigns, socket) do
    camp_tests = LabTests.get_camp_lab_tests(@camp_test_names)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:camp_tests, camp_tests)
     |> assign(:selected_test_ids, [])
     |> assign_new(:form, fn ->
       to_form(LabResults.change_camp_lab_result(%LabResult{}))
     end)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Order Lab Test for {[@patient.first_name, @patient.middle_name, @patient.last_name]
        |> Enum.filter(&(&1 != nil))
        |> Enum.join(" ")}
      </.header>

      <div class="mb-4 grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div class="hidden">
          <label class="block text-sm font-medium text-gray-700 mb-1">Lab Payment</label>
          <div class="mt-1 block w-full rounded-md border border-gray-200 bg-gray-50 px-3 py-2 text-gray-700 cursor-not-allowed">
            Subsidized (30% off)
          </div>
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Insurance Provider</label>
          <div class="mt-1 block w-full rounded-md border border-gray-200 bg-gray-50 px-3 py-2 text-gray-700 cursor-not-allowed">
            Human Development Fund ( HDF )
          </div>
        </div>
      </div>

      <.simple_form
        for={@form}
        id="camp-lab-order-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="flex flex-col gap-3 mb-4">
          <label class="block text-sm font-medium text-gray-700">Select Lab Tests</label>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <%= for test <- @camp_tests do %>
              <label class={[
                "flex items-center gap-3 rounded-lg border-2 p-3 cursor-pointer transition-colors",
                if(test.id in @selected_test_ids,
                  do: "border-brand-accent bg-brand-50",
                  else: "border-gray-200 hover:border-gray-300"
                )
              ]}>
                <input
                  type="checkbox"
                  value={test.id}
                  checked={test.id in @selected_test_ids}
                  phx-click="toggle_camp_test"
                  phx-value-id={test.id}
                  phx-target={@myself}
                  class="rounded text-brand-accent focus:ring-brand-accent"
                />
                <span class="text-sm font-medium text-gray-800">{test.name}</span>
              </label>
            <% end %>
          </div>
        </div>

        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input
          field={@form[:urgency]}
          type="select"
          prompt="Select urgency"
          options={[{"High (STAT)", "STAT"}, {"Urgent", "Urgent"}, {"Routine", "Routine"}]}
          label="Urgency"
        />

        <:actions>
          <.button phx-disable-with="Saving...">Order Lab Test</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("toggle_camp_test", %{"id" => id}, socket) do
    test_id = String.to_integer(id)
    current = socket.assigns.selected_test_ids

    updated =
      if test_id in current,
        do: List.delete(current, test_id),
        else: [test_id | current]

    {:noreply, assign(socket, :selected_test_ids, updated)}
  end

  def handle_event("validate", %{"lab_result" => lab_result_params}, socket) do
    changeset = LabResults.change_camp_lab_result(%LabResult{}, lab_result_params)
    {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"lab_result" => lab_result_params}, socket) do
    if socket.assigns.selected_test_ids == [] do
      {:noreply, put_flash(socket, :error, "Please select at least one lab test")}
    else
      tests =
        socket.assigns.camp_tests
        |> Enum.filter(&(&1.id in socket.assigns.selected_test_ids))
        |> Enum.map(fn test ->
          %{name: test.name, price: LabTest.price_for_payment_type(test, "subsidized")}
        end)

      attrs =
        lab_result_params
        |> Map.put("patient_id", socket.assigns.patient.id)
        |> Map.put("doctor_id", socket.assigns.current_user.id)
        |> Map.put("doctor_note_id", socket.assigns.doctor_note_id)
        |> Map.put("payment_type", "Insurance")
        |> Map.put("insurance_name", "Human Development Fund ( HDF )")
        |> Map.put("has_paid", true)
        |> Map.put("tests", tests)

      case LabResults.create_camp_lab_order(attrs) do
        {:ok, _lab_result} ->
          send(self(), {:lab_order_saved})
          {:noreply, socket}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, :form, to_form(changeset))}
      end
    end
  end
end
