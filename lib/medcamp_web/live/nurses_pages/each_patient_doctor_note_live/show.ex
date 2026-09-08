defmodule MedcampWeb.NursesPages.EachPatientDoctorNoteShow do
  use MedcampWeb, :nurse_each_patient_live_view

  @moduledoc """
  A nurse's read-only view of one doctor note.

  At a camp the nurse's own work ends at triage; this page exists so they can
  see what the doctor concluded and ordered - the note itself, the lab tests
  requested and their results, and the drugs prescribed. Everything here is
  read-only: notes are authored by the doctor and drugs are dispensed by the
  pharmacist.
  """

  alias Medcamp.Patients
  alias Medcamp.DoctorNotes
  alias Medcamp.LabResults
  alias Medcamp.DrugAllocations

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :doctor_notes)
     |> assign(:current_tab, "overview")
     |> assign(:note_path, nil)}
  end

  @impl true
  def handle_params(%{"patient_id" => id, "note_id" => note_id} = params, _url, socket) do
    patient = Patients.get_patient!(id)
    doctor_note = DoctorNotes.get_doctor_note!(note_id)
    note_path = "/nurse/#{id}/doctor_notes/#{note_id}"
    current_tab = valid_tab(params["tab"])

    {:noreply,
     socket
     |> assign(:patient, patient)
     |> assign(:doctor_note, doctor_note)
     |> assign(:note_path, note_path)
     |> assign(:note_path_with_params, "#{note_path}?tab=#{current_tab}")
     |> assign(:current_tab, current_tab)
     |> assign(:page_title, "Doctor Note")
     |> assign(:lab_results, LabResults.list_lab_results_for_doctor_note(note_id))
     |> assign(
       :drug_allocations,
       DrugAllocations.list_drug_allocations_for_a_doctor_note(note_id)
     )
     |> assign_new(:form, fn -> to_form(DoctorNotes.change_doctor_note(doctor_note)) end)}
  end

  defp valid_tab(tab) when tab in ~w(overview lab_work medication), do: tab
  defp valid_tab(_), do: "overview"

  @impl true
  def handle_event("change-tab", %{"tab" => tab}, socket) do
    path = "#{socket.assigns.note_path}?tab=#{valid_tab(tab)}"
    {:noreply, push_patch(socket, to: path)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="w-full flex justify-between items-center mb-4">
        <.link
          navigate={"/nurse/#{@patient.id}/doctor_notes"}
          class="flex gap-2 cursor-pointer text-brand-primary font-semibold items-center hover:text-brand-accent transition-colors"
        >
          <Heroicons.icon name="arrow-left" type="outline" class="h-4 w-4" />
          <p>
            Back to Doctor Notes
          </p>
        </.link>
      </div>

      <.doctor_note_tabs
        current_tab={@current_tab}
        tabs={[
          %{id: "overview", label: "Overview", icon_name: "document-text"},
          %{id: "lab_work", label: "Lab Work", icon_name: "beaker"},
          %{
            id: "medication",
            label: "Medication",
            icon_markup: "<i class=\"fa fa-diamond\" aria-hidden=\"true\"></i>",
            icon_name: nil
          }
        ]}
      />

      <.doctor_notes_form_for_nurse
        :if={@current_tab == "overview"}
        patient={@patient}
        show_lab_imaging_request={false}
        form={@form}
      />

      <.lab_results_card_for_nurse
        :if={@current_tab == "lab_work"}
        lab_results={@lab_results}
        patient={@patient}
        doctor_note={@doctor_note}
      />

      <.drug_allocations_section_for_nurse
        :if={@current_tab == "medication"}
        drug_allocations={@drug_allocations}
        patient={@patient}
        doctor_note={@doctor_note}
      />
    </div>
    """
  end
end
