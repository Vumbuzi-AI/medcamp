defmodule MedcampWeb.ReceptionsPageFormLive.Index do
  use MedcampWeb, :shared_live_view

  alias MedcampWeb.RoleRouteHelpers

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :forms)
     |> assign(:query, "")}
  end

  @impl true
  def handle_params(_, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"search" => query}, socket) do
    {:noreply, assign(socket, :query, query)}
  end

  @impl true
  def handle_event("clear_search", _params, socket) do
    {:noreply, assign(socket, :query, "")}
  end

  defp forms_path(current_user, suffix) do
    RoleRouteHelpers.role_path(current_user, "/forms" <> suffix)
  end

  defp form_groups do
    [
      %{
        title: "Clinical",
        icon: "stethoscope",
        forms: [
          %{
            title: "Discharge Against Medical Advice",
            subtitle: "DAMA Form",
            description:
              "For patients choosing to leave against medical advice. Captures declaration, risks explained, and witness signatures.",
            icon: "arrow-right-on-rectangle",
            suffix: "/dama",
            color: "rose"
          },
          %{
            title: "Discharge Summary",
            subtitle: "GHC Discharge Summary",
            description:
              "Complete discharge summary with clinical summary, diagnosis, discharge medications, and follow-up plan.",
            icon: "document-check",
            suffix: "/discharge_summary",
            color: "green"
          },
          %{
            title: "Patient Referral Form",
            subtitle: "GHC Referral",
            description:
              "Refer a patient to another facility with vital signs, diagnoses, treatments initiated, and reason for referral.",
            icon: "arrow-top-right-on-square",
            suffix: "/patient_referral",
            color: "blue"
          }
        ]
      },
      %{
        title: "Investigations",
        icon: "beaker",
        forms: [
          %{
            title: "Laboratory Request Form",
            subtitle: "GHC Lab Request",
            description:
              "Request laboratory investigations across haematology, biochemistry, microbiology, and other test categories.",
            icon: "beaker",
            suffix: "/lab_request",
            color: "blue"
          },
          %{
            title: "Radiology Request Form",
            subtitle: "GHC Radiology Request",
            description:
              "Request radiology investigations including X-Ray, Ultrasound, CT scan, and MRI with sub-type checkboxes.",
            icon: "photo",
            suffix: "/radiology_request",
            color: "purple"
          }
        ]
      },
      %{
        title: "Consent Forms",
        icon: "shield-check",
        forms: [
          %{
            title: "Surgical Consent Form",
            subtitle: "GHC Consent",
            description:
              "Patient consent for surgical procedures — procedure details, confirmation of understanding, and signatures.",
            icon: "scissors",
            suffix: "/surgical_consent",
            color: "rose"
          },
          %{
            title: "Blood Transfusion Consent",
            subtitle: "GHC Consent",
            description:
              "Patient consent for blood transfusion. Covers risks explained, national guideline screening confirmation.",
            icon: "heart",
            suffix: "/blood_transfusion_consent",
            color: "red"
          },
          %{
            title: "HIV Testing Consent",
            subtitle: "GHC Consent",
            description:
              "Informed consent for HIV testing with pre/post counseling acknowledgment and confidentiality assurance.",
            icon: "shield-check",
            suffix: "/hiv_testing_consent",
            color: "teal"
          }
        ]
      },
      %{
        title: "Clinical Documents",
        icon: "document-text",
        forms: [
          %{
            title: "Medical Report",
            subtitle: "GHC Medical Report",
            description:
              "Pre-employment/education medical report with physical examination, lab investigations, and fitness assessment.",
            icon: "document-magnifying-glass",
            suffix: "/medical_report",
            color: "purple"
          },
          %{
            title: "Prescription Sheet",
            subtitle: "GHC Prescription",
            description:
              "Prescriber sheet for issuing medications with route, dosage, strength, frequency, and duration.",
            icon: "clipboard-document-list",
            suffix: "/prescription_sheet",
            color: "amber"
          },
          %{
            title: "Sick Leave Sheet",
            subtitle: "GHC Sick Leave",
            description:
              "Official sick leave certificate confirming a patient is medically unfit for work or school.",
            icon: "calendar-days",
            suffix: "/sick_leave",
            color: "green"
          }
        ]
      },
      %{
        title: "Administrative",
        icon: "banknotes",
        forms: [
          %{
            title: "Payment Receipt",
            subtitle: "GHC Receipt",
            description:
              "Official payment receipt with GHC-Excellence branding. Records received amount, payer, and service description.",
            icon: "receipt-percent",
            suffix: "/payment_receipt",
            color: "amber"
          }
        ]
      }
    ]
  end

  defp matches_query?(_form, ""), do: true

  defp matches_query?(form, query) do
    q = String.downcase(query)

    String.contains?(String.downcase(form.title), q) or
      String.contains?(String.downcase(form.subtitle), q) or
      String.contains?(String.downcase(form.description), q)
  end

  defp visible_groups(query) do
    form_groups()
    |> Enum.map(fn group ->
      Map.put(group, :forms, Enum.filter(group.forms, &matches_query?(&1, query)))
    end)
    |> Enum.filter(&(&1.forms != []))
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :groups, visible_groups(assigns.query))

    ~H"""
    <div class="max-w-5xl mx-auto">
      <div class="mb-8">
        <h1 class="text-2xl font-bold text-gray-900">Hospital Forms</h1>
        <p class="text-gray-500 mt-1">
          Access and fill out hospital forms digitally. All forms can be printed after completion.
        </p>
      </div>

      <form phx-change="search" class="mb-8">
        <.search_input name="search" value={@query} placeholder="Search by form name or description" />
      </form>

      <.blank_state
        :if={@groups == []}
        icon_path="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
        title="No forms found"
        description="No forms match your search."
      >
        <:actions>
          <button phx-click="clear_search" class="text-xs text-[#6667ab] hover:underline">
            Clear filters
          </button>
        </:actions>
      </.blank_state>

      <div class="space-y-10">
        <.form_group :for={group <- @groups} title={group.title} icon={group.icon}>
          <.form_card
            :for={form <- group.forms}
            title={form.title}
            subtitle={form.subtitle}
            description={form.description}
            icon={form.icon}
            url={forms_path(@current_user, form.suffix)}
            color={form.color}
          />
        </.form_group>
      </div>
    </div>
    """
  end

  defp form_group(assigns) do
    ~H"""
    <div>
      <div class="flex items-center gap-2 mb-4">
        <.icon name={"hero-#{@icon}"} class="w-5 h-5 text-[#373896]" />
        <h2 class="text-base font-bold text-gray-700 uppercase tracking-wider">{@title}</h2>
        <div class="flex-1 h-px bg-gray-200 ml-2"></div>
      </div>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp form_card(assigns) do
    ~H"""
    <a
      href={@url}
      class="block p-6 bg-white border border-gray-200 rounded-xl shadow-sm hover:shadow-md hover:border-[#373896] transition-all duration-200 group"
    >
      <div class="flex items-start gap-4 mb-4">
        <div class={[
          "p-3 rounded-xl shrink-0 group-hover:bg-[#373896] transition-colors",
          @color == "rose" && "bg-rose-50",
          @color == "red" && "bg-red-50",
          @color == "blue" && "bg-blue-50",
          @color == "green" && "bg-green-50",
          @color == "purple" && "bg-slate-50",
          @color == "amber" && "bg-amber-50",
          @color == "teal" && "bg-teal-50"
        ]}>
          <.icon
            name={"hero-#{@icon}"}
            class={"w-6 h-6 group-hover:text-white transition-colors #{form_icon_color(@color)}"}
          />
        </div>
        <div>
          <p class="text-xs font-medium text-gray-400 uppercase tracking-wide mb-0.5">{@subtitle}</p>
          <h3 class="font-semibold text-gray-900 group-hover:text-[#373896] leading-tight">
            {@title}
          </h3>
        </div>
      </div>
      <p class="text-sm text-gray-500 leading-relaxed">{@description}</p>
      <div class="mt-5 flex items-center text-sm font-semibold text-[#373896]">
        Open Form
        <.icon
          name="hero-arrow-right"
          class="w-4 h-4 ml-1.5 group-hover:translate-x-1 transition-transform"
        />
      </div>
    </a>
    """
  end

  defp form_icon_color(color) do
    case color do
      "rose" -> "text-rose-600"
      "red" -> "text-red-600"
      "blue" -> "text-blue-600"
      "green" -> "text-green-600"
      "purple" -> "text-purple-600"
      "amber" -> "text-amber-600"
      "teal" -> "text-teal-600"
      _ -> "text-[#373896]"
    end
  end
end
