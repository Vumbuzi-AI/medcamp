defmodule MedcampWeb.PatientCardLive do
  use MedcampWeb, :live_view

  alias Medcamp.DoctorNotes
  alias Medcamp.DrugAllocations
  alias Medcamp.LabResults
  alias Medcamp.PatientVisits
  alias Medcamp.Patients
  alias Medcamp.Triages

  @tabs ~w(overview triages doctor_notes lab_results visits medications)a

  def mount(%{"gsrn" => gsrn}, _session, socket) do
    case Patients.get_patient_by_gsrn(gsrn) do
      nil ->
        {:ok, assign(socket, patient: nil, page_title: "Patient not found")}

      patient ->
        {:ok,
         socket
         |> assign(
           patient: patient,
           page_title: "Patient record",
           pin: "",
           pin_error: nil,
           verified: false,
           active_tab: :overview,
           tabs: @tabs
         )
         |> assign(
           triages: Triages.list_triages_by_patient(patient.id),
           doctor_notes: DoctorNotes.doctor_notes_for_patient(patient.id),
           lab_results: LabResults.list_lab_results_for_patient(patient.id),
           visits: PatientVisits.list_patient_visits_by_patient_id(patient.id),
           medications: DrugAllocations.list_drug_allocations_for_a_patient(patient.id)
         )}
    end
  end

  def handle_event("pin_changed", %{"pin" => pin}, socket),
    do: {:noreply, assign(socket, :pin, pin)}

  def handle_event("verify_pin", _params, %{assigns: %{patient: patient, pin: pin}} = socket) do
    if pin != "" and String.to_integer(pin) == patient.pin,
      do: {:noreply, assign(socket, verified: true, pin_error: nil)},
      else: {:noreply, assign(socket, pin_error: "Incorrect PIN. Please try again.")}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    tab = String.to_existing_atom(tab)
    {:noreply, assign(socket, :active_tab, if(tab in @tabs, do: tab, else: :overview))}
  end

  def render(%{patient: nil} = assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-50 flex items-center justify-center p-6">
      <div class="bg-white rounded-2xl border border-slate-200 shadow-sm p-8 text-center max-w-md">
        <h1 class="text-xl font-bold text-slate-900">Patient record not found</h1>
        <p class="text-slate-500 mt-2">The QR code or GSRN is not linked to a patient.</p>
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-slate-50 via-white to-indigo-50">
      <header class="bg-white border-b border-slate-200">
        <div class="max-w-6xl mx-auto px-4 sm:px-6 py-5 flex items-center justify-between">
          <div class="flex items-center gap-3">
            <img src="/images/logo.png" class="h-10 w-10 object-contain" alt="GHC Excellence" />
            <div>
              <p class="font-bold text-slate-900">GHC Excellence</p>
              <p class="text-xs text-slate-500">Patient record</p>
            </div>
          </div>
          <span class="text-xs font-medium text-slate-500">GSRN: {@patient.gsrn}</span>
        </div>
      </header>
      <main class={"max-w-6xl mx-auto px-4 sm:px-6 py-8 #{if @verified, do: "", else: "blur-sm pointer-events-none"}"}>
        <section class="bg-white rounded-2xl border border-slate-200 shadow-sm p-6 mb-6">
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <p class="text-sm text-slate-500">Patient</p>
              <h1 class="text-2xl font-bold text-slate-900">{patient_name(@patient)}</h1>
              <p class="text-sm text-slate-500 mt-1">
                {@patient.gender || "—"} · {patient_age(@patient)} years
              </p>
            </div>
            <a
              href={"/8018/#{@patient.gsrn}/medical-camp"}
              class="text-sm font-semibold text-indigo-700"
            >
              Open care portal →
            </a>
          </div>
        </section>
        <nav class="bg-white rounded-2xl border border-slate-200 shadow-sm p-2 flex gap-1 overflow-x-auto">
          <%= for tab <- @tabs do %>
            <button
              phx-click="switch_tab"
              phx-value-tab={tab}
              class={"whitespace-nowrap px-4 py-2.5 rounded-xl text-sm font-semibold #{if @active_tab == tab, do: "bg-indigo-600 text-white", else: "text-slate-600 hover:bg-slate-100"}"}
            >
              {tab_label(tab)}
            </button>
          <% end %>
        </nav>
        <section class="mt-6">
          <%= case @active_tab do %>
            <% :overview -> %>
              <div class="grid sm:grid-cols-2 lg:grid-cols-4 gap-4">
                <.summary title="Triages" count={length(@triages)} icon="🩺" /><.summary
                  title="Doctor notes"
                  count={length(@doctor_notes)}
                  icon="📋"
                /><.summary title="Lab results" count={length(@lab_results)} icon="🧪" /><.summary
                  title="Medications"
                  count={length(@medications)}
                  icon="💊"
                />
              </div>
              <.visit_list items={@visits} title="Recent visits" />
            <% :triages -> %>
              <.triage_list items={@triages} />
            <% :doctor_notes -> %>
              <.note_list items={@doctor_notes} />
            <% :lab_results -> %>
              <.lab_list items={@lab_results} />
            <% :visits -> %>
              <.visit_list items={@visits} title="Visits" />
            <% :medications -> %>
              <.medication_list items={@medications} />
          <% end %>
        </section>
      </main>
      <%= unless @verified do %>
        <div class="fixed inset-0 bg-slate-950/60 backdrop-blur-sm flex items-center justify-center p-4">
          <form phx-submit="verify_pin" class="bg-white rounded-2xl shadow-2xl p-7 w-full max-w-sm">
            <div class="text-center">
              <div class="text-3xl mb-3">🔒</div>
              <h2 class="text-xl font-bold text-slate-900">Verify your identity</h2>
              <p class="text-sm text-slate-500 mt-2">
                Enter your patient PIN to view your care history.
              </p>
            </div>
            <input
              id="patient-pin"
              name="pin"
              type="password"
              inputmode="numeric"
              maxlength="4"
              required
              value={@pin}
              phx-change="pin_changed"
              class="mt-6 w-full rounded-xl border border-slate-300 px-4 py-3 text-center text-2xl tracking-[.5em]"
              placeholder="••••"
            />
            <p :if={@pin_error} class="text-sm text-red-600 mt-2 text-center">{@pin_error}</p>
            <button class="mt-5 w-full rounded-xl bg-indigo-600 text-white py-3 font-semibold">
              View my record
            </button>
          </form>
        </div>
      <% end %>
    </div>
    """
  end

  defp summary(assigns) do
    ~H"""
    <div class="bg-white rounded-2xl border border-slate-200 shadow-sm p-5">
      <div class="text-2xl">{@icon}</div>
      <p class="text-sm text-slate-500 mt-3">{@title}</p>
      <p class="text-3xl font-bold text-slate-900">{@count}</p>
    </div>
    """
  end

  defp triage_list(assigns) do
    ~H"""
    <.data_card title="Triage history" empty="No triage records yet.">
      <div :for={item <- @items} class="border-b border-slate-100 py-4 last:border-0">
        <div class="flex justify-between">
          <b>{format_date(item.date || item.inserted_at)}</b><span class="text-slate-500">BP {item.blood_pressure || "—"} · Pulse {item.pulse_rate || "—"}</span>
        </div>
        <p class="text-sm text-slate-600 mt-1">{item.triage_notes || "No notes recorded."}</p>
      </div>
    </.data_card>
    """
  end

  defp note_list(assigns) do
    ~H"""
    <.data_card title="Doctor notes" empty="No doctor notes yet.">
      <div :for={item <- @items} class="border-b border-slate-100 py-4 last:border-0">
        <b>{format_date(item.date || item.inserted_at)}</b>
        <p class="text-sm text-slate-500 mt-1">Diagnosis: {item.diagnosis || "Not recorded"}</p>
        <p class="text-sm text-slate-700 mt-1">
          {item.clinical_notes || item.impression || item.management || "No clinical notes recorded."}
        </p>
      </div>
    </.data_card>
    """
  end

  defp lab_list(assigns) do
    ~H"""
    <.data_card title="Lab results" empty="No lab results yet.">
      <div :for={item <- @items} class="border-b border-slate-100 py-4 last:border-0">
        <div class="flex justify-between">
          <b>{item.name || "Laboratory test"}</b><span class="text-sm text-slate-500">{format_date(item.date_of_test || item.inserted_at)}</span>
        </div>
        <p class="text-sm text-slate-700 mt-1">
          {item.test_findings || item.lab_report || "Result pending."}
        </p>
      </div>
    </.data_card>
    """
  end

  defp medication_list(assigns) do
    ~H"""
    <.data_card title="Medications" empty="No medications recorded yet.">
      <div :for={item <- @items} class="border-b border-slate-100 py-4 last:border-0">
        <b>{item.prescription || "Medication prescription"}</b>
        <p class="text-sm text-slate-500 mt-1">
          Quantity: {item.quantity || "—"} · {format_date(item.inserted_at)}
        </p>
      </div>
    </.data_card>
    """
  end

  defp visit_list(assigns) do
    ~H"""
    <.data_card title={@title} empty="No visits recorded yet.">
      <div :for={item <- @items} class="border-b border-slate-100 py-4 last:border-0">
        <b>{format_date(item.date || item.inserted_at)}</b>
        <p class="text-sm text-slate-600 mt-1">
          {item.reason || item.visit_type || "Patient visit"} · {item.status || "Recorded"}
        </p>
      </div>
    </.data_card>
    """
  end

  defp data_card(assigns) do
    assigns = assign_new(assigns, :items, fn -> [] end)

    ~H"""
    <div class="bg-white rounded-2xl border border-slate-200 shadow-sm p-5 mt-5">
      <h2 class="text-lg font-bold text-slate-900 mb-2">{@title}</h2>
      <p :if={@items == []} class="text-slate-500 py-5">{@empty}</p>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp tab_label(:doctor_notes), do: "Doctor notes"
  defp tab_label(:lab_results), do: "Lab results"
  defp tab_label(:medications), do: "Medications"
  defp tab_label(tab), do: tab |> Atom.to_string() |> String.capitalize()

  defp patient_name(patient),
    do:
      [patient.first_name, patient.middle_name, patient.last_name]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" ")

  defp patient_age(%{date_of_birth: %Date{} = dob}),
    do: Date.diff(Date.utc_today(), dob) |> div(365)

  defp patient_age(%{age: age}) when is_integer(age), do: age
  defp patient_age(_), do: "—"
  defp format_date(%Date{} = date), do: Calendar.strftime(date, "%d %b %Y")
  defp format_date(%DateTime{} = date), do: Calendar.strftime(date, "%d %b %Y")
  defp format_date(_), do: "—"
end
