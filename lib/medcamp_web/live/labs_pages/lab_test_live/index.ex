defmodule MedcampWeb.LabTestLive.Index do
  use MedcampWeb, :lab_live_view

  alias Medcamp.LabTests
  alias Medcamp.LabTests.LabTest

  @impl true
  def mount(_params, _session, socket) do
    lab_tests = LabTests.list_lab_tests()

    {:ok,
     socket
     |> assign(:active_tab, :lab_tests)
     |> assign(:lab_tests_count, length(lab_tests))
     |> assign(:lab_tests, lab_tests)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Lab test")
    |> assign(:lab_test, LabTests.get_lab_test!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Lab test")
    |> assign(:lab_test, %LabTest{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Lab tests")
    |> assign(:lab_test, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    lab_test = LabTests.get_lab_test!(id)
    {:ok, _} = LabTests.delete_lab_test(lab_test)

    {:noreply,
     socket
     |> update(:lab_tests_count, &max(&1 - 1, 0))
     |> assign(:lab_tests, Enum.reject(socket.assigns.lab_tests, &(&1.id == lab_test.id)))}
  end
end
