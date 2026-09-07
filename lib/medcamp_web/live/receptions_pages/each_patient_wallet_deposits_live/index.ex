defmodule MedcampWeb.ReceptionsPagePatientLive.EachPatientWalletDepositsIndex do
  use MedcampWeb, :reception_each_patient_live_view

  alias Medcamp.WalletDeposits
  alias Medcamp.Patients

  @per_page 10

  @impl true
  def mount(%{"patient_id" => patient_id} = _params, _session, socket) do
    statistics = WalletDeposits.get_wallet_statistics_for_patient(patient_id)

    patient = Patients.get_patient!(patient_id)

    {:ok,
     socket
     |> assign(:patient, patient)
     |> assign(:active_tab, :wallet_deposits)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:statistics, statistics)
     |> load_wallet_deposits()}
  end

  defp load_wallet_deposits(socket) do
    all_deposits =
      WalletDeposits.list_wallet_deposits_with_usage_for_patient(socket.assigns.patient.id)

    total_count = length(all_deposits)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    deposits =
      Enum.slice(all_deposits, (page - 1) * socket.assigns.per_page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:wallet_deposits, deposits)
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_wallet_deposits()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Wallet Deposits")
    |> assign(:wallet_deposit, nil)
  end

  defp apply_action(socket, :trigger_payment, _params) do
    socket
    |> assign(:page_title, "New Wallet Deposit")
    |> assign(:wallet_deposit, %WalletDeposits.WalletDeposit{})
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-gray-50 min-h-screen">
      <div class="container mx-auto ">
        <.wallet_deposits_header statistics={@statistics} patient={@patient} active_tab={@active_tab} />

        <.wallet_deposits_table
          id="wallet_deposits_table"
          wallet_deposits={@wallet_deposits}
          patient={@patient}
          count={@total_count}
        />
        <.pagination
          page={@page}
          total_pages={@total_pages}
          total_count={@total_count}
          per_page={@per_page}
        />
      </div>
    </div>

    <.modal
      :if={@live_action in [:trigger_payment]}
      id="patient_visit-modal"
      show
      on_cancel={JS.patch(~p"/reception/#{@patient.id}/wallet_deposits")}
    >
      <.live_component
        module={MedcampWeb.ReceptionsPagePatientLive.TriggerPayment}
        id={:new}
        title={@page_title}
        action={@live_action}
        action_to_perform="create_wallet_deposit"
        return_url={"/reception/#{@patient.id}/wallet_deposits"}
        actionable_type={%{}}
        patient={@patient}
        current_user={@current_user}
        patient_id={@patient.id}
        patch={"/reception/#{@patient.id}/wallet_deposits"}
      />
    </.modal>
    """
  end
end
