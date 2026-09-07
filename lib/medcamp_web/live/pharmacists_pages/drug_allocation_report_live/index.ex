defmodule MedcampWeb.PharmacistsLive.DrugAllocationReportIndex do
  use MedcampWeb, :pharmacist_live_view

  alias MedcampWeb.DrugAllocationReportLive, as: Report

  @impl true
  def mount(_params, _session, socket), do: Report.mount(socket)

  @impl true
  def handle_event(event, params, socket), do: Report.handle_event(event, params, socket)

  @impl true
  def render(assigns), do: Report.render(assigns)
end
