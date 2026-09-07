defmodule MedcampWeb.AdminMedicalCampReportLive.Show do
  use MedcampWeb, :admin_live_view

  alias Medcamp.MedicalCampReports

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :medical_camp)
     |> assign(:page_title, "Medical Camp Report")
     |> assign(:report, MedicalCampReports.report())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="medical-camp-report-print-hidden flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <.link
            navigate="/admin/medical_camp"
            class="inline-flex items-center gap-2 text-sm font-medium text-slate-500 hover:text-slate-700"
          >
            <Heroicons.icon name="arrow-left" type="outline" class="h-4 w-4" />
            Back to Medical Camp Dashboard
          </.link>
        </div>

        <button
          type="button"
          onclick="window.print()"
          class="inline-flex items-center justify-center gap-2 rounded-2xl bg-slate-900 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-slate-800"
        >
          <Heroicons.icon name="arrow-down-tray" type="outline" class="h-4 w-4" /> Download PDF
        </button>
      </div>

      <div class="medical-camp-report-print-shell rounded-3xl bg-white/70 p-1">
        <.medical_camp_report report={@report} />
      </div>
    </div>
    """
  end
end
