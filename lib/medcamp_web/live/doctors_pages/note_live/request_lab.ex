defmodule MedcampWeb.RequestLabComponent do
  use MedcampWeb, :live_component

  @moduledoc """
  Doctor-facing form for ordering lab tests against a doctor note.

  Camp lab work is free, so this is just test selection: pick tests, set an
  urgency, describe why, and the request lands in the lab's queue. There is
  no pricing, payment type or M-Pesa prompt.
  """

  alias Medcamp.LabResults
  alias Medcamp.LabTests

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Request Lab Work for {[@patient.first_name, @patient.middle_name, @patient.last_name]
        |> Enum.filter(&(&1 != nil))
        |> Enum.join(" ")}
      </.header>

      <.simple_form
        for={@form}
        id="lab_result-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="flex flex-col gap-0">
          <.input
            field={@form[:query]}
            value={@searched_query}
            phx-change="search_lab_test"
            type="text"
            label="Search Lab Test"
          />
          <div :if={@selected_tests != []} class="flex flex-wrap my-4 gap-3">
            <%= for test <- @selected_tests do %>
              <div class="flex flex-row gap-2 rounded-md bg-gray-100 flex justify-center items-center p-2  rounded-md">
                {test.name}
                <p phx-click={"remove_lab_test-#{test.id}"} phx-target={@myself}>
                  <Heroicons.icon
                    name="x-mark"
                    type="outline"
                    class="h-4 w-4 cursor-pointer text-darkblue"
                  />
                </p>
              </div>
            <% end %>
          </div>
          <div :if={@searched_lab_tests != []} class="bg-gray-100 gap-2 p-2 h-[150px] overflow-y-auto">
            <%= for option <- @searched_lab_tests do %>
              <div
                phx-click="select_lab_test"
                phx-target={@myself}
                phx-value-id={option.id}
                class="p-2 cursor-pointer border-b-[1px] hover:bg-gray-200"
              >
                {option.name}
              </div>
            <% end %>
          </div>
        </div>
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input
          field={@form[:urgency]}
          type="select"
          prompt="Select urgency"
          options={[
            {"High (Red)", "High"},
            {"Medium (Amber)", "Medium"},
            {"Low (Green)", "Low"}
          ]}
        />

        <:actions>
          <.button phx-disable-with="Saving...">Request Lab Work</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{lab_result: lab_result} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:searched_query, "")
     |> assign(:searched_lab_tests, [])
     |> assign(:selected_tests, [])
     |> assign_new(:form, fn ->
       to_form(LabResults.change_lab_result(lab_result))
     end)}
  end

  @impl true
  def handle_event("search_lab_test", %{"lab_result" => %{"query" => query}}, socket) do
    {:noreply,
     socket
     |> assign(searched_query: query)
     |> assign(searched_lab_tests: unselected_matches(query, socket.assigns.selected_tests))}
  end

  def handle_event("select_lab_test", %{"id" => id}, socket) do
    lab_test = LabTests.get_lab_test!(id)

    selected_tests =
      [lab_test | socket.assigns.selected_tests]
      |> Enum.uniq_by(& &1.id)

    {:noreply,
     socket
     |> assign(selected_tests: selected_tests)
     |> assign(
       searched_lab_tests: unselected_matches(socket.assigns.searched_query, selected_tests)
     )}
  end

  def handle_event("remove_lab_test-" <> id, _, socket) do
    selected_tests =
      socket.assigns.selected_tests |> Enum.reject(&(&1.id == String.to_integer(id)))

    {:noreply,
     socket
     |> assign(selected_tests: selected_tests)
     |> assign(
       searched_lab_tests: unselected_matches(socket.assigns.searched_query, selected_tests)
     )}
  end

  def handle_event("validate", %{"lab_result" => lab_result_params}, socket) do
    changeset = LabResults.change_lab_result(socket.assigns.lab_result, lab_result_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"lab_result" => lab_result_params}, socket) do
    tests = Enum.map(socket.assigns.selected_tests, &%{name: &1.name})

    lab_result_params =
      lab_result_params
      |> Map.put("patient_id", socket.assigns.patient.id)
      |> Map.put("doctor_id", socket.assigns.current_user.id)
      |> Map.put("doctor_note_id", socket.assigns.doctor_note.id)
      |> Map.put("tests", tests)

    case LabResults.create_lab_result(lab_result_params) do
      {:ok, _lab_result} ->
        {:noreply,
         socket
         |> put_flash(:info, "Lab result created successfully and sent to the lab")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp unselected_matches(query, selected_tests) do
    selected_ids = Enum.map(selected_tests, & &1.id)

    query
    |> LabTests.search_lab_tests()
    |> Enum.reject(&(&1.id in selected_ids))
  end
end
