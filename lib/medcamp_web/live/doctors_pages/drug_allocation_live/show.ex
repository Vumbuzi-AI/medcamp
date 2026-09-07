defmodule MedcampWeb.DoctorsPagePatientLive.DrugAllocationShow do
  use MedcampWeb, :each_patient_live_view

  alias Medcamp.Patients
  alias Medcamp.DrugAllocations

  @impl true
  def mount(_, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :lab_results)}
  end

  @impl true
  def handle_params(
        %{"id" => id, "drug_allocation_id" => drug_allocation_id} = _params,
        _url,
        socket
      ) do
    patient = Patients.get_patient!(id)

    drug_allocation = DrugAllocations.get_drug_allocation!(drug_allocation_id)

    {:noreply,
     socket
     |> assign(:patient, patient)
     |> assign(:drug_allocation, drug_allocation)}
  end

  @impl true

  def render(assigns) do
    ~H"""
    <div>
      <.drug_allocation_card drug_allocation={@drug_allocation} />

      <p class="text-lg text-darkblue font-semibold mt-4">
        Doctor Notes Details
      </p>
      <.doctor_notes_card
        :if={@drug_allocation.doctor_note}
        doctor_note={@drug_allocation.doctor_note}
      />
    </div>
    """
  end
end
