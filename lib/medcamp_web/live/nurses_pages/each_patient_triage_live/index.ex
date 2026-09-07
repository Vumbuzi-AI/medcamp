defmodule MedcampWeb.NursesPages.EachPatientTriageIndex do
  use MedcampWeb, :nurse_each_patient_live_view

  alias Medcamp.Triages
  alias Medcamp.Patients
  alias Medcamp.Triages.Triage

  @impl true
  def mount(%{"patient_id" => id}, _session, socket) do
    patient = Patients.get_patient!(id)

    {:ok,
     socket
     |> assign(:patient, patient)
     |> assign(:active_tab, :triages)
     |> assign_triages(Triages.list_triages_by_patient(id))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
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

  # The triages table is expandable, so it renders its rows eagerly rather than
  # under `phx-update="stream"`. It must be fed a plain list assign — a stream
  # would render empty on the first re-render that isn't a reset.
  defp assign_triages(socket, triages) do
    socket
    |> assign(:triages_count, length(triages))
    |> assign(:triages, triages)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-[100%]">
      <.triages_table
        route_prefix={"/nurse/#{@patient.id}/triages"}
        new_triage_url={"/nurse/#{@patient.id}/triages/new"}
        triages={@triages}
        count={@triages_count}
        show_new_link={true}
      />

      <.modal
        :if={@live_action in [:new, :edit]}
        id="triage-modal"
        show
        on_cancel={JS.patch("/nurse/#{@patient.id}/triages")}
      >
        <.live_component
          module={MedcampWeb.NursesPage.TriageFormComponent}
          id={@triage.id || :new}
          title={@page_title}
          current_user={@current_user}
          selected_patient={@patient}
          action={@live_action}
          triage={@triage}
          patch={"/nurse/#{@patient.id}/triages"}
        />
      </.modal>
    </div>
    """
  end
end
