defmodule MedcampWeb.DoctorsPagePatientLive.TriageIndex do
  use MedcampWeb, :each_patient_live_view

  alias Medcamp.Triages
  alias Medcamp.Triages.Triage
  alias Medcamp.Patients

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :triages)}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    patient = Patients.get_patient!(id)

    triages = Triages.list_triages_by_patient(patient.id)

    {:noreply,
     socket
     |> assign(:patient, patient)
     |> assign(:triages_count, length(triages))
     |> assign(:triages, triages)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"triage_id" => id}) do
    socket
    |> assign(:page_title, "Edit Triage")
    |> assign(:triage, Triages.get_triage!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Triage")
    |> assign(:triage, %Triage{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Triages")
    |> assign(:triage, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    triage = Triages.get_triage!(id)
    {:ok, _} = Triages.delete_triage(triage)

    {:noreply,
     socket
     |> assign(:triages_count, socket.assigns.triages_count - 1)
     |> assign(:triages, Enum.reject(socket.assigns.triages, &(&1.id == triage.id)))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-[100%]">
      <.triages_table
        route_prefix={"/doctor/patients/#{@patient.id}/triages"}
        new_triage_url={"/doctor/patients/#{@patient.id}/triages/new"}
        triages={@triages}
        count={@triages_count}
        show_new_link={false}
      />

      <.modal
        :if={@live_action in [:new, :edit]}
        id="triage-modal"
        show
        on_cancel={JS.patch("/doctor/patients/#{@patient.id}/triages")}
      >
        <.live_component
          module={MedcampWeb.DoctorsPagePatientLive.TriageFormComponent}
          id={@triage.id || :new}
          title={@page_title}
          patient={@patient}
          current_user={@current_user}
          action={@live_action}
          triage={@triage}
          patch={"/doctor/patients/#{@patient.id}/triages"}
        />
      </.modal>
    </div>
    """
  end
end
