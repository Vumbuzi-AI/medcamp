defmodule MedcampWeb.LabPages.ScanIndex do
  use MedcampWeb, :lab_live_view
  alias Medcamp.Patients

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :scan)}
  end

  @impl true
  def handle_params(%{"value" => %{"qr" => qr}}, _url, socket) do
    qr = String.replace_prefix(qr, "01", "")

    case Patients.get_patient_by_gsrn(qr) do
      nil ->
        {:noreply, socket}

      patient ->
        {:noreply,
         socket
         |> push_navigate(
           to:
             MedcampWeb.MedicalCampRouting.after_scan_path(
               socket.assigns.current_user.role,
               patient
             )
         )}
    end
  end

  def handle_params(_, _url, socket) do
    {:noreply, socket}
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
