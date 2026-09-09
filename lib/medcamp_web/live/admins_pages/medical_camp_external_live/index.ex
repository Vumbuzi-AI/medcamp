defmodule MedcampWeb.AdminMedicalCampExternalLive.Index do
  use MedcampWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Medical Camp External Dashboard")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-slate-50 via-white to-slate-100">
      <div class="mx-auto w-full px-4 py-4 sm:px-6 lg:px-8">
        <div class="mb-4 flex flex-col gap-3 rounded-2xl border border-slate-200 bg-white px-5 py-4 shadow-sm sm:flex-row sm:items-center sm:justify-between">
          <div>
            <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">
              Restricted External View
            </p>
            <h1 class="mt-1 text-xl font-bold text-slate-900">Medical Camp Dashboard</h1>
            <p class="text-sm text-slate-500">
              Signed in as {@external_admin_user && @external_admin_user.name}. This session only
              grants access to this page.
            </p>
          </div>

          <div class="flex flex-wrap items-center gap-3">
            <.link
              navigate="/admin/medical_camp/external/report"
              class="inline-flex items-center justify-center gap-2 rounded-xl bg-brand-primary px-4 py-2 text-sm font-semibold text-white transition hover:bg-[#2f307e]"
            >
              <Heroicons.icon name="document-text" type="outline" class="h-4 w-4" /> Report
            </.link>

            <.link
              href={~p"/admin/medical_camp/access/logout"}
              method="delete"
              class="inline-flex items-center justify-center rounded-xl border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-700 transition hover:border-slate-400 hover:bg-slate-50"
            >
              Logout
            </.link>
          </div>
        </div>

        {Phoenix.Component.live_render(@socket, MedcampWeb.AdminMedicalCampLive.Index,
          id: "external-medical-camp-dashboard",
          session: %{"report_path" => "/admin/medical_camp/external/report"}
        )}
      </div>
    </div>
    """
  end
end
