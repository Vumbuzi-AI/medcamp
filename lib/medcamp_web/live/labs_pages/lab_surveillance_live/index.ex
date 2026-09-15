defmodule MedcampWeb.LabPagesLabSurveillanceLive.Index do
  use MedcampWeb, :lab_live_view

  alias MedcampWeb.LabSurveillanceLive

  @impl true
  def mount(_params, _session, socket), do: {:ok, LabSurveillanceLive.mount(socket)}

  @impl true
  def handle_event("filter", params, socket) do
    {:noreply, LabSurveillanceLive.apply_filters(socket, params)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, LabSurveillanceLive.clear_filters(socket)}
  end

  @impl true
  def render(assigns), do: LabSurveillanceLive.report(assigns)
end
