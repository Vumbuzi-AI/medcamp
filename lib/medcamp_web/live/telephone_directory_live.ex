defmodule MedcampWeb.TelephoneDirectoryLive do
  use MedcampWeb, :live_view
  alias Medcamp.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user = Accounts.get_user_by_session_token(session["user_token"])

    {:ok,
     socket
     |> assign(:current_user, current_user)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex p-4 items-center gap-4">
        <!-- Back to Panel Button -->
        <.link
          navigate={get_panel_url(@current_user.role)}
          class="flex items-center gap-2 px-4 py-2 text-sm bg-[#373896] text-white rounded-lg hover:bg-[#6667ab] transition-colors"
        >
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
          </svg>
          Back to Panel
        </.link>
      </div>
      <.telephone_directory />
    </div>
    """
  end

  defp get_panel_url(role) do
    case role do
      "doctor" -> "/doctor/patients"
      "nurse" -> "/nurse/scan"
      "reception" -> "/reception/scan"
      "pharmacist" -> "/pharmacist/scan"
      "labtechnician" -> "/lab/scan"
      "radiologist" -> "/radiologist/scan"
      "admin" -> "/admin/users"
      "inventory_manager" -> "/inventory_manager/inventories_received"
      "supplier" -> "/supplier/dashboard"
      "procurement_officer" -> "/procurement/dashboard"
      "stores_officer" -> "/procurement/dashboard"
      "finance_officer" -> "/procurement/dashboard"
      _ -> "/"
    end
  end
end
