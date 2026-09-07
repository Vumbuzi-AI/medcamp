defmodule MedcampWeb.ReferralLive.Index do
  use MedcampWeb, :each_patient_live_view

  alias Medcamp.Referrals
  alias Medcamp.Referrals.Referral
  alias Medcamp.Patients

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :referrals)
     |> assign(:referrals, Referrals.list_referrals_for_a_patient(id))}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    patient = Patients.get_patient!(id)

    {:noreply,
     socket
     |> assign(:patient, patient)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Referral")
    |> assign(:referral, Referrals.get_referral!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Referral")
    |> assign(:referral, %Referral{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Referrals")
    |> assign(:referral, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    referral = Referrals.get_referral!(id)
    {:ok, _} = Referrals.delete_referral(referral)

    {:noreply, stream_delete(socket, :referrals, referral)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.referrals_card_for_a_patient referrals={@referrals} />
    """
  end
end
