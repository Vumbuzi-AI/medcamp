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

      <p class="mb-5 text-sm text-gray-500">
        Select the tests the laboratory should perform, then set how urgently they are needed.
      </p>

      <.simple_form
        for={@form}
        id="lab_result-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="flex flex-col gap-1">
          <.input
            field={@form[:query]}
            value={@searched_query}
            phx-change="search_lab_test"
            type="text"
            label="Find a lab test"
            placeholder="Search by test name..."
          />

          <div class="mt-2 flex items-center justify-between">
            <span class="text-xs font-semibold uppercase tracking-wide text-gray-500">
              Selected tests ({length(@selected_tests)})
            </span>
            <span :if={@selected_tests == []} class="text-xs text-amber-600">
              Select at least one test
            </span>
          </div>

          <div :if={@selected_tests != []} class="my-2 flex flex-wrap gap-2">
            <%= for test <- @selected_tests do %>
              <div class="flex items-center gap-2 rounded-full bg-indigo-50 px-3 py-1.5 text-sm font-medium text-indigo-900 ring-1 ring-indigo-100">
                {test.name}
                <button
                  type="button"
                  aria-label={"Remove #{test.name}"}
                  phx-click={"remove_lab_test-#{test.id}"}
                  phx-target={@myself}
                  class="rounded-full text-indigo-500 hover:bg-indigo-100 hover:text-indigo-900"
                >
                  <Heroicons.icon name="x-mark" type="outline" class="h-4 w-4" />
                </button>
              </div>
            <% end %>
          </div>

          <div class="mt-2 overflow-hidden rounded-lg border border-gray-200 bg-gray-50">
            <p class="border-b border-gray-200 px-3 py-2 text-xs text-gray-500">
              Click a test to add it to this request
            </p>
            <%= for option <- @searched_lab_tests do %>
              <div
                phx-click="select_lab_test"
                phx-target={@myself}
                phx-value-id={option.id}
                class="cursor-pointer border-b border-gray-200 bg-white px-3 py-2.5 text-sm last:border-b-0 hover:bg-indigo-50"
              >
                {option.name}
              </div>
            <% end %>
            <p :if={@searched_lab_tests == []} class="px-3 py-4 text-center text-sm text-gray-500">
              No matching lab tests found. Try a different search.
            </p>
          </div>
        </div>

        <.input
          field={@form[:description]}
          type="textarea"
          label="Clinical indication"
          placeholder="Briefly explain why these tests are needed (optional)"
        />
        <.input
          field={@form[:urgency]}
          type="select"
          label="Priority"
          prompt="Choose priority"
          options={[
            {"High (Red)", "High"},
            {"Medium (Amber)", "Medium"},
            {"Low (Green)", "Low"}
          ]}
        />
        <p class="-mt-2 text-xs text-gray-500">
          High: act immediately · Medium: process soon · Low: routine
        </p>

        <:actions>
          <.button
            phx-disable-with="Saving..."
            disabled={@selected_tests == [] or @form[:urgency].value in [nil, ""]}
          >
            Request Lab Work
          </.button>
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
     |> assign(:searched_lab_tests, LabTests.list_lab_tests())
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
    tests =
      Enum.map(socket.assigns.selected_tests, fn test ->
        %{name: test.name, price: test.price || 0}
      end)

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
