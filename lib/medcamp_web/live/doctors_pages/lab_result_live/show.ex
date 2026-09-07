defmodule MedcampWeb.DoctorsPagePatientLive.LabResultShow do
  use MedcampWeb, :each_patient_live_view

  alias Medcamp.LabResults
  alias Medcamp.Patients

  @impl true
  def mount(_, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :lab_results)}
  end

  @impl true
  def handle_params(%{"id" => id, "lab_result_id" => lab_result_id} = _params, _url, socket) do
    patient = Patients.get_patient!(id)

    lab_result = LabResults.get_lab_result!(lab_result_id)

    {:noreply,
     socket
     |> assign(:patient, patient)
     |> assign(:lab_result, lab_result)}
  end

  @impl true
  def handle_event("refresh-interpretation", %{"id" => id}, socket) do
    case LabResults.refresh_lab_result_interpretation(String.to_integer(id)) do
      {:ok, lab_result} ->
        {:noreply,
         socket
         |> assign(:lab_result, lab_result)
         |> put_flash(:info, "AI lab data generated")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not generate AI lab data right now")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.lab_result_card lab_result={@lab_result} patient={@patient} regenerate={true} />
    </div>
    """
  end
end
