defmodule MedcampWeb.MedicalCampPages.Home do
  use MedcampWeb, :live_view

  alias MedcampWeb.PublicTenant
  alias Phoenix.LiveView.JS
  alias Medcamp.Triages
  alias Medcamp.DoctorNotes
  alias Medcamp.Accounts
  alias Medcamp.Triages.Triage
  alias Medcamp.DrugAllocations
  alias Medcamp.DrugAllocations.DrugAllocation
  alias Medcamp.LabResults

  @impl true
  def mount(%{"gsrn" => gsrn}, session, socket) do
    patient = PublicTenant.resolve_patient!(gsrn)
    most_recent_triage = Triages.most_recent_triage(patient.id)
    triages = Triages.list_triages_by_patient(patient.id)

    current_user =
      case session["user_token"] do
        nil -> nil
        token -> Accounts.get_user_by_session_token(token)
      end

    authenticated = not is_nil(current_user)

    # Redirect nurse to new triage, doctor to doctor_notes (only from the index route)
    if authenticated and socket.assigns.live_action == :index do
      case current_user.role do
        "nurse" ->
          {:ok,
           socket
           |> push_navigate(to: "/8018/#{gsrn}/medical-camp/triages/new")}

        "doctor" ->
          {:ok,
           socket
           |> push_navigate(to: "/8018/#{gsrn}/medical-camp/doctor_notes")}

        _ ->
          {:ok,
           mount_home(socket, patient, most_recent_triage, triages, current_user, authenticated)}
      end
    else
      {:ok, mount_home(socket, patient, most_recent_triage, triages, current_user, authenticated)}
    end
  end

  defp mount_home(socket, patient, most_recent_triage, triages, current_user, authenticated) do
    socket
    |> assign(:patient, patient)
    |> assign(:most_recent_triage, most_recent_triage)
    |> assign(:page_title, "Patient Details")
    |> assign(:show_otp_modal, !authenticated)
    |> assign(:current_user, current_user)
    |> assign(:triage, %Triage{})
    |> assign(:active_tab, :overview)
    |> assign(:back_url, nil)
    |> assign(:mobile_menu_open, false)
    |> assign(:expanded_sections, MapSet.new())
    |> assign(:show_pharmacy_modal, false)
    |> assign(:show_lab_modal, false)
    |> assign(:show_triage_modal, false)
    |> assign(:selected_triage, nil)
    |> assign(:drug_allocation, %DrugAllocation{})
    |> assign(:triages, triages)
    |> stream(:doctor_notes, DoctorNotes.doctor_notes_for_patient(patient.id))
    |> stream(:drug_allocations, DrugAllocations.list_drug_allocations_for_a_patient(patient.id))
    |> stream(:lab_results, LabResults.list_lab_results_for_patient(patient.id))
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"triage_id" => triage_id}) do
    triage = Triages.get_triage!(triage_id)
    socket |> assign(:page_title, "Edit Triage") |> assign(:triage, triage)
  end

  defp apply_action(socket, _, _params) do
    socket |> assign(:page_title, "Patient Details") |> assign(:triage, %Triage{})
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, String.to_existing_atom(tab))}
  end

  def handle_event("show_triage", %{"id" => id}, socket) do
    triage = Triages.get_triage!(id)
    {:noreply, assign(socket, show_triage_modal: true, selected_triage: triage)}
  end

  def handle_event("close_triage_modal", _, socket) do
    {:noreply, assign(socket, show_triage_modal: false, selected_triage: nil)}
  end

  def handle_event("open_pharmacy_modal", _, socket) do
    {:noreply, assign(socket, show_pharmacy_modal: true, drug_allocation: %DrugAllocation{})}
  end

  def handle_event("close_pharmacy_modal", _, socket) do
    {:noreply, assign(socket, :show_pharmacy_modal, false)}
  end

  def handle_event("open_lab_modal", _, socket) do
    {:noreply, assign(socket, :show_lab_modal, true)}
  end

  def handle_event("close_lab_modal", _, socket) do
    {:noreply, assign(socket, :show_lab_modal, false)}
  end

  @impl true
  def handle_info({:lab_order_saved}, socket) do
    patient = socket.assigns.patient

    {:noreply,
     socket
     |> assign(:show_lab_modal, false)
     |> put_flash(:info, "Lab order submitted successfully")
     |> stream(:lab_results, LabResults.list_lab_results_for_patient(patient.id), reset: true)}
  end

  def handle_info({:drug_allocation_saved}, socket) do
    patient = socket.assigns.patient

    {:noreply,
     socket
     |> assign(:show_pharmacy_modal, false)
     |> put_flash(:info, "Drug allocation saved successfully")
     |> stream(:drug_allocations, DrugAllocations.list_drug_allocations_for_a_patient(patient.id),
       reset: true
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%!-- OTP verification modal --%>
      <div
        :if={@show_otp_modal}
        class="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
      >
        <div class="bg-white rounded-xl shadow-xl p-8 w-full max-w-sm mx-4">
          <h2 class="text-xl font-bold text-gray-800 mb-1">Medical Camp Access</h2>
          <p class="text-sm text-gray-500 mb-6">Enter your 4-digit OTP to continue.</p>

          <form action={"/8018/#{@patient.gsrn}/medical-camp/session"} method="post">
            <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
            <input
              type="text"
              name="otp"
              maxlength="4"
              inputmode="numeric"
              placeholder="_ _ _ _"
              autofocus
              class="w-full text-center text-2xl tracking-[0.5em] border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
            <button
              type="submit"
              class="mt-4 w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2.5 rounded-lg transition-colors"
            >
              Verify OTP
            </button>
          </form>
        </div>
      </div>

      <%!-- Main content (blurred when OTP modal is showing) --%>
      <div class={if @show_otp_modal, do: "pointer-events-none select-none blur-sm", else: ""}>
        <%!-- Patient header --%>
        <div class="bg-white rounded-lg border border-gray-100 shadow-sm p-4 mb-4 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2">
          <div>
            <h2 class="text-lg font-bold text-gray-800">
              {[@patient.first_name, @patient.middle_name, @patient.last_name]
              |> Enum.filter(&(&1 != nil))
              |> Enum.join(" ")}
            </h2>
            <p class="text-sm text-gray-500">
              GSRN: {@patient.gsrn} · {@patient.gender} · {@patient.date_of_birth}
            </p>
          </div>
        </div>

        <.patient_overview_for_camp_details
          most_recent_triage={@most_recent_triage}
          patient={@patient}
          form={%{}}
          triages={@triages}
          back_url="/doctor/patients"
          edit_url="/doctor/patients/#{@patient.id}/edit"
          triage_row_click={fn triage -> JS.push("show_triage", value: %{id: triage.id}) end}
          current_user={@current_user}
        />

        <%!-- Triage details popup --%>
        <.modal
          :if={@show_triage_modal && @selected_triage}
          id="triage-details-modal"
          show
          on_cancel={JS.push("close_triage_modal")}
        >
          <div class="p-2">
            <h2 class="text-lg font-bold text-brand-primary mb-4">Triage Details</h2>
            <div class="grid grid-cols-2 sm:grid-cols-3 gap-3 text-sm">
              <div class="bg-gray-50 rounded p-2">
                <span class="text-gray-500 block">Date</span>
                <span class="font-medium">{@selected_triage.date}</span>
              </div>
              <div class="bg-gray-50 rounded p-2">
                <span class="text-gray-500 block">Time</span>
                <span class="font-medium">{@selected_triage.time || "-"}</span>
              </div>
              <div class="bg-gray-50 rounded p-2">
                <span class="text-gray-500 block">Temperature</span>
                <span class="font-medium">{@selected_triage.temperature || "-"} °C</span>
              </div>
              <div class="bg-gray-50 rounded p-2">
                <span class="text-gray-500 block">Blood Pressure</span>
                <span class="font-medium">{@selected_triage.blood_pressure || "-"}</span>
              </div>
              <div class="bg-gray-50 rounded p-2">
                <span class="text-gray-500 block">Pulse Rate</span>
                <span class="font-medium">{@selected_triage.pulse_rate || "-"} bpm</span>
              </div>
              <div class="bg-gray-50 rounded p-2">
                <span class="text-gray-500 block">O2 Saturation</span>
                <span class="font-medium">{@selected_triage.oxygen_saturation || "-"} %</span>
              </div>
              <div class="bg-gray-50 rounded p-2">
                <span class="text-gray-500 block">Weight</span>
                <span class="font-medium">{@selected_triage.weight || "-"} kg</span>
              </div>
              <div class="bg-gray-50 rounded p-2">
                <span class="text-gray-500 block">Height</span>
                <span class="font-medium">{@selected_triage.height || "-"} cm</span>
              </div>
              <div class="bg-gray-50 rounded p-2">
                <span class="text-gray-500 block">BMI</span>
                <span class="font-medium">{@selected_triage.bmi || "-"}</span>
              </div>
              <div class="bg-gray-50 rounded p-2">
                <span class="text-gray-500 block">Emergency</span>
                <span class={[
                  "font-medium",
                  @selected_triage.emergency_scale == "High" && "text-red-600",
                  @selected_triage.emergency_scale == "Medium" && "text-amber-600",
                  @selected_triage.emergency_scale == "Low" && "text-green-600"
                ]}>
                  {@selected_triage.emergency_scale || "-"}
                </span>
              </div>
            </div>
            <div :if={@selected_triage.allergies} class="mt-3 bg-red-50 rounded p-2 text-sm">
              <span class="text-red-600 font-medium">Allergies: </span>
              <span class="text-red-800">{@selected_triage.allergies}</span>
            </div>
            <div :if={@selected_triage.triage_notes} class="mt-2 bg-gray-50 rounded p-2 text-sm">
              <span class="text-gray-500 font-medium">Notes: </span>
              <span>{@selected_triage.triage_notes}</span>
            </div>
          </div>
        </.modal>

        <%!-- Triage modal (existing) --%>
        <.modal
          :if={@live_action in [:new_triage, :edit_triage]}
          id="triage-modal"
          show
          on_cancel={JS.navigate("/medical-camp/scan")}
        >
          <.live_component
            module={MedcampWeb.NursesPage.TriageFormComponent}
            id={:new}
            title={@page_title}
            current_user={@current_user}
            selected_patient={@patient}
            action={:new}
            triage={@triage}
            patch={"/8018/#{@patient.gsrn}/medical-camp/scan"}
          />
        </.modal>

        <%!-- Pharmacy modal --%>
        <.modal
          :if={@show_pharmacy_modal}
          id="pharmacy-modal"
          show
          on_cancel={JS.push("close_pharmacy_modal")}
        >
          <.live_component
            module={MedcampWeb.PharmacistsLive.DrugAllocationFormComponent}
            id="camp-drug-allocation"
            title="Add Drug Allocation"
            action={:new}
            drug_allocation={@drug_allocation}
            patient={@patient}
            current_user={@current_user}
            force_insurance={true}
            patch={"/8018/#{@patient.gsrn}/medical-camp"}
          />
        </.modal>

        <%!-- Lab Work modal --%>
        <.modal :if={@show_lab_modal} id="lab-modal" show on_cancel={JS.push("close_lab_modal")}>
          <.live_component
            module={MedcampWeb.MedicalCampPages.LabOrderComponent}
            id="camp-lab-order"
            patient={@patient}
            current_user={@current_user}
          />
        </.modal>
      </div>
    </div>
    """
  end
end
