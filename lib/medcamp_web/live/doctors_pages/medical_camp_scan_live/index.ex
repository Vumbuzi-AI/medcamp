defmodule MedcampWeb.DoctorsPage.MedicalCampScanIndex do
  use MedcampWeb, :doctor_live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :medical_camp_scan)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={MedcampWeb.MedicalCampScanComponent}
        current_user={@current_user}
        id="medical-camp-scan"
      />
    </div>
    """
  end
end
