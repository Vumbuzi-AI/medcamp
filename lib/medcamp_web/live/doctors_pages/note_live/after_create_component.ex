defmodule MedcampWeb.AfterCreateNoteComponent do
  use MedcampWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Doctor Note Created Successfully
      </.header>
      <div class="flex flex-col gap-2 w-[100%]">
        <p>
          Doctor note created successfully. You can now proceed to create a lab result for this note or prescibe medication for the patient.
        </p>

        <div class="flex gap-8 flex-wrap mt-8 w-[100%] justify-center  items-center">
          <.button>
            <.link navigate={"/doctor/patients/#{@patient.id}/notes/#{@doctor_note.id}/request_lab"}>
              Request Lab Work
            </.link>
          </.button>

          <.button>
            <.link navigate={"/doctor/patients/#{@patient.id}/notes/#{@doctor_note.id}/prescribe_drug"}>
              Prescribe Medicine
            </.link>
          </.button>

          <.link navigate={"/doctor/patients/#{@patient.id}/notes/#{@doctor_note.id}/refer_patient"}>
            <.button>
              Refer Patient
            </.button>
          </.link>

          <.button>
            <.link navigate={"/doctor/patients/#{@patient.id}/notes/#{@doctor_note.id}/request_radiology_test"}>
              Request Radiology Test
            </.link>
          </.button>

          <.button>
            <.link navigate={"/doctor/patients/#{@patient.id}/notes/#{@doctor_note.id}/admit_patient"}>
              Admit Patient
            </.link>
          </.button>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end
end
