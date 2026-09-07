defmodule MedcampWeb.ReceptionsPage.ScanIndex do
  use MedcampWeb, :reception_live_view

  alias Medcamp.Patients
  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :scan)}
  end

  @impl true
  def handle_params(%{"value" => %{"qr" => qr}}, _url, socket) do
    qr = String.slice(qr, 2..-1//-1)

    case Patients.get_patient_by_gsrn(qr) do
      nil ->
        {:noreply, socket}

      patient ->
        {:noreply,
         socket
         |> push_navigate(to: redirect_to_route(socket.assigns.current_user.role, patient))}
    end
  end

  def handle_params(_, _url, socket) do
    {:noreply, socket}
  end

  defp redirect_to_route(role, patient) do
    case role do
      "doctor" ->
        "/doctor/patients/#{patient.id}"

      "nurse" ->
        "/nurse/#{patient.id}/patient_overview"

      "reception" ->
        "/reception/#{patient.id}/patient_overview"

      "labtechnician" ->
        "/lab/#{patient.id}/lab_results"

      "pharmacist" ->
        "/pharmacist/#{patient.id}/drug_allocations"

      _ ->
        "/"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.live_component module={MedcampWeb.ScanComponent} current_user={@current_user} id="hero" />
    </div>
    """
  end
end
