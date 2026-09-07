defmodule MedcampWeb.ReceptionMpesaReconciliationLive.Index do
  use MedcampWeb, :reception_live_view

  alias MedcampWeb.AdminMpesaReconciliationLive.Index, as: ReconciliationLive

  @impl true
  def mount(params, session, socket) do
    case ReconciliationLive.mount(params, session, socket) do
      {:ok, socket} -> {:ok, assign(socket, :active_tab, :mpesa_reconciliation)}
      other -> other
    end
  end

  @impl true
  defdelegate handle_event(event, params, socket), to: ReconciliationLive

  @impl true
  defdelegate render(assigns), to: ReconciliationLive
end
