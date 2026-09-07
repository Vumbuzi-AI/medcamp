defmodule MedcampWeb.LabStockRequestLive do
  @moduledoc "Lab stock change requests (bucket: lab allocations)."
  use MedcampWeb, :lab_live_view
  alias MedcampWeb.StockRequests.Hub

  @impl true
  def mount(params, session, socket),
    do: Hub.mount("lab_allocation", :stock_requests, params, session, socket)

  @impl true
  def handle_event(event, params, socket), do: Hub.handle_event(event, params, socket)

  @impl true
  def render(assigns), do: Hub.render(assigns)
end
