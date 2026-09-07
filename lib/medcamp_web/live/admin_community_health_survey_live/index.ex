defmodule MedcampWeb.AdminCommunityHealthSurveyLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.CommunityHealthSurveys

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :community_health_survey)
     |> assign(:page_title, "Community Health Survey")
     |> assign(:filter_date_from, "")
     |> assign(:filter_date_to, "")
     |> assign(:filter_search, "")
     |> assign(:share_path, "/community-health-insurance-survey")
     |> load_dashboard()}
  end

  # The search box and the filter drawer submit independently (two separate
  # <form>s), so a submission from either one only carries its own fields.
  # Merging onto the current filters means a key absent from this submission
  # is left unchanged rather than reset.
  @impl true
  def handle_event("apply_filters", %{"filters" => params}, socket) do
    current = %{
      "date_from" => socket.assigns.filter_date_from,
      "date_to" => socket.assigns.filter_date_to,
      "search" => socket.assigns.filter_search
    }

    params = Map.merge(current, params)

    {:noreply,
     socket
     |> assign(:filter_date_from, trim(params["date_from"]))
     |> assign(:filter_date_to, trim(params["date_to"]))
     |> assign(:filter_search, trim(params["search"]))
     |> load_dashboard()}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filter_date_from, "")
     |> assign(:filter_date_to, "")
     |> assign(:filter_search, "")
     |> load_dashboard()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.survey_dashboard
      metrics={@metrics}
      filter_date_from={@filter_date_from}
      filter_date_to={@filter_date_to}
      filter_search={@filter_search}
      share_path={@share_path}
    />
    """
  end

  defp load_dashboard(socket) do
    assign(socket, :metrics, CommunityHealthSurveys.build_dashboard(filters(socket)))
  end

  defp filters(socket) do
    [
      date_from: socket.assigns.filter_date_from,
      date_to: socket.assigns.filter_date_to,
      search: socket.assigns.filter_search
    ]
  end

  defp trim(nil), do: ""
  defp trim(value), do: String.trim(value)
end
