defmodule MedcampWeb.DoctorsPagePatientLive.DrugAllocationIndex do
  use MedcampWeb, :each_patient_live_view

  alias Medcamp.DrugAllocations
  alias Medcamp.Patients

  @per_page 10

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    patients = Patients.list_patients_for_selection()

    {:ok,
     socket
     |> assign(:patients, patients)
     |> assign(:active_tab, :drug_allocations)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:total_count, 0)
     |> assign(:total_pages, 0)
     |> assign_drug_allocations(id, 1)}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    patient = Patients.get_patient!(id)

    {:noreply,
     socket
     |> assign(:patient, patient)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Drug allocations")
    |> assign(:drug_allocation, nil)
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, assign_drug_allocations(socket, socket.assigns.patient.id, page)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    drug_allocation = DrugAllocations.get_drug_allocation!(id)

    case DrugAllocations.delete_drug_allocation(drug_allocation) do
      {:ok, _} ->
        {:noreply,
         assign_drug_allocations(socket, socket.assigns.patient.id, socket.assigns.page)}

      {:error, :dispensed_drugs} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "You cannot delete a prescription after any drug has been given"
         )}

      {:error, :paid_prescription} ->
        {:noreply, put_flash(socket, :error, "You cannot delete a paid prescription")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to delete prescription")}
    end
  end

  defp assign_drug_allocations(socket, patient_id, page) do
    page = normalize_page(page)
    total_count = DrugAllocations.count_drug_allocations_for_a_patient(patient_id)
    total_pages = max(1, div(total_count + @per_page - 1, @per_page))
    page = min(page, total_pages)

    drug_allocations =
      DrugAllocations.list_drug_allocations_for_a_patient_paginated(patient_id, page, @per_page)

    socket
    |> assign(:page, page)
    |> assign(:per_page, @per_page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:drug_allocations, drug_allocations)
  end

  defp normalize_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {value, _} when value > 0 -> value
      _ -> 1
    end
  end

  defp normalize_page(page) when is_integer(page) and page > 0, do: page
  defp normalize_page(_), do: 1

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Drug allocations for {patient_name(@patient)}
      </.header>

      <.blank_state
        :if={@drug_allocations == []}
        icon_path="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
        title="No drugs allocated"
        description="No drugs have been given to this patient yet."
      />

      <.data_table
        :if={@drug_allocations != []}
        id="drug_allocations"
        rows={@drug_allocations}
        row_click={
          fn drug_allocation ->
            JS.navigate("/doctor/patients/#{@patient.id}/drug_allocations/#{drug_allocation.id}")
          end
        }
      >
        <:col :let={drug_allocation} label="Prescription">{drug_allocation.prescription}</:col>
        <:col :let={drug_allocation} label="Patient">{patient_name(drug_allocation.patient)}</:col>
        <:col :let={drug_allocation} label="Doctor">
          {drug_allocation.doctor && drug_allocation.doctor.name}
        </:col>
        <:col :let={drug_allocation} label="Pharmacist">
          {drug_allocation.pharmacist && drug_allocation.pharmacist.name}
        </:col>

        <:col :let={drug_allocation} label="Quantity">{drug_allocation.quantity}</:col>
        <:col :let={drug_allocation} label="Prescription">{drug_allocation.prescription}</:col>
      </.data_table>

      <.pagination
        page={@page}
        total_pages={@total_pages}
        total_count={@total_count}
        per_page={@per_page}
      />
    </div>
    """
  end

  defp patient_name(%{first_name: first_name, middle_name: middle_name, last_name: last_name}) do
    [first_name, middle_name, last_name]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end
end
