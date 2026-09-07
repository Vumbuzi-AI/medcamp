defmodule MedcampWeb.LabPagesLabTestLive.Index do
  use MedcampWeb, :lab_live_view

  alias Medcamp.LabTests

  @impl true
  def mount(_, _session, socket) do
    lab_tests = LabTests.list_lab_tests()

    {:ok,
     socket
     |> assign(:active_tab, :lab_tests)
     |> assign(:lab_tests_count, length(lab_tests))
     |> stream(:lab_tests, lab_tests)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.page_header
        icon_path="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
        title="Lab Tests"
        subtitle="Browse configured lab tests and pricing."
      />

      <.blank_state
        :if={@lab_tests_count == 0}
        icon_path="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
        title="No lab tests found"
        description="No lab tests have been configured yet."
      />

      <.table :if={@lab_tests_count > 0} id="lab_tests" rows={@streams.lab_tests}>
        <:col :let={{_id, lab_test}} label="Name">{lab_test.name}</:col>
        <:col :let={{_id, lab_test}} label="Desription">{lab_test.desription}</:col>
        <:col :let={{_id, lab_test}} label="Price">{lab_test.price}</:col>
      </.table>
    </div>
    """
  end
end
