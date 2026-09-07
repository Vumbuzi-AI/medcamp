defmodule MedcampWeb.RadiologistPages.EachPatientRadiologyResultLive.Index do
  use MedcampWeb, :radiologist_each_patient_live_view

  alias Medcamp.RadiologyResults
  alias Medcamp.Patients
  alias Medcamp.RadiologyResults.RadiologyResult

  @per_page 10

  @impl true
  def mount(%{"patient_id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :radiology_results)
     |> assign(:patient, Patients.get_patient!(id))
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_radiology_results()}
  end

  defp load_radiology_results(socket) do
    patient_id = socket.assigns.patient.id
    total_count = RadiologyResults.count_radiology_results_by_patient_id(patient_id)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    radiology_results =
      RadiologyResults.list_radiology_results_by_patient_id_paginated(
        patient_id,
        page,
        socket.assigns.per_page
      )

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:radiology_results, radiology_results)
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Radiology result")
    |> assign(:radiology_result, RadiologyResults.get_radiology_result!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Radiology result")
    |> assign(:radiology_result, %RadiologyResult{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Radiology results")
    |> assign(:radiology_result, nil)
  end

  @impl true
  def handle_info(
        {MedcampWeb.RadiologyResultLive.FormComponent, {:saved, _radiology_result}},
        socket
      ) do
    {:noreply, load_radiology_results(socket)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    radiology_result = RadiologyResults.get_radiology_result!(id)
    {:ok, _} = RadiologyResults.delete_radiology_result(radiology_result)

    {:noreply, load_radiology_results(socket)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_radiology_results()}
  end
end
