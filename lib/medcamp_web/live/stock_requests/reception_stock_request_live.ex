defmodule MedcampWeb.ReceptionStockRequestLive do
  @moduledoc "Reception stock change requests (bucket: received batches)."
  use MedcampWeb, :reception_live_view
  alias MedcampWeb.StockRequests.Hub

  @impl true
  def mount(params, session, socket),
    do: Hub.mount("inventory_received", :stock_requests, params, session, socket)

  @impl true
  def handle_event(event, params, socket), do: Hub.handle_event(event, params, socket)

  @impl true
  def render(assigns), do: Hub.render(assigns)
end
