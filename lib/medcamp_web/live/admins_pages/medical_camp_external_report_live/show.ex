defmodule MedcampWeb.AdminMedicalCampExternalReportLive.Show do
  use MedcampWeb, :live_view

  alias Medcamp.MedicalCampReports

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Medical Camp External Report")
     |> assign(:report, MedicalCampReports.report())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-slate-50 via-white to-slate-100">
      <div class="mx-auto w-[90%] mx-auto px-4 py-4 sm:px-6 lg:px-8">
        <div class="medical-camp-report-print-hidden mb-4 flex flex-col gap-3 rounded-2xl border border-slate-200 bg-white px-5 py-4 shadow-sm sm:flex-row sm:items-center sm:justify-between">
          <div class="flex flex-wrap items-center gap-3 text-sm">
            <.link
              navigate="/admin/medical_camp/external"
              class="inline-flex items-center gap-2 rounded-xl border border-slate-200 px-3 py-2 font-medium text-slate-600 transition hover:bg-slate-50"
            >
              <Heroicons.icon name="arrow-left" type="outline" class="h-4 w-4" /> Dashboard
            </.link>

            <button
              type="button"
              onclick="window.print()"
              class="inline-flex items-center gap-2 rounded-xl bg-slate-900 px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-800"
            >
              <Heroicons.icon name="arrow-down-tray" type="outline" class="h-4 w-4" /> Download PDF
            </button>
          </div>

          <.link
            href={~p"/admin/medical_camp/access/logout"}
            method="delete"
            class="inline-flex items-center justify-center rounded-xl border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-700 transition hover:border-slate-400 hover:bg-slate-50"
          >
            Logout
          </.link>
        </div>

        <div class="medical-camp-report-print-shell rounded-3xl bg-white/70 p-1">
          <.medical_camp_report report={@report} />
        </div>
      </div>
    </div>
    """
  end
end
