defmodule MedcampWeb.PharmacistStockRequestLive do
  @moduledoc "Pharmacist stock change requests (bucket: drug batches)."
  use MedcampWeb, :pharmacist_live_view
  alias MedcampWeb.StockRequests.Hub

  @impl true
  def mount(params, session, socket),
    do: Hub.mount("drug_batch", :stock_requests, params, session, socket)

  @impl true
  def handle_event(event, params, socket), do: Hub.handle_event(event, params, socket)

  @impl true
  def render(assigns), do: Hub.render(assigns)
end
