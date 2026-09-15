defmodule MedcampWeb.DoctorsPagePatientLive.DoctorNoteShow do
  use MedcampWeb, :each_patient_live_view
  require Logger
  alias Medcamp.Patients
  alias Medcamp.DoctorNotes
  alias Medcamp.LabResults
  alias Medcamp.LabTestTemplates
  alias Medcamp.LabResults.LabResult
  alias Medcamp.DrugAllocations.DrugAllocation
  alias Medcamp.DrugAllocations
  alias Medcamp.AIDocReviewer

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :doctor_notes)
     |> assign(:current_tab, "overview")
     |> assign(:note_path, nil)
     |> assign(:view_lab_report_entry, nil)
     |> assign(:view_lab_report_template, nil)
     |> assign(:view_lab_report_lab_result, nil)
     |> assign(:view_lab_report_patient, nil)
     |> assign(:view_lab_report_doctor, nil)
     |> assign(:show_sub_note_modal, false)
     |> assign(:sub_note_form, nil)
     |> assign(:expanded_sub_note_ids, [])
     |> assign(:main_note_expanded, true)
     |> assign(:patient_charge_batch, nil)
     |> assign(:ai_review_loading, false)
     |> stream(:doctor_notes, DoctorNotes.list_doctor_notes())}
  end

  @impl true
  def handle_params(%{"id" => id, "note_id" => note_id} = params, _url, socket) do
    patient = Patients.get_patient!(id)
    doctor_note = DoctorNotes.get_doctor_note!(note_id)

    if doctor_note.patient_id != patient.id do
      {:noreply,
       socket
       |> put_flash(:error, "That note could not be found for this patient.")
       |> push_navigate(to: "/doctor/patients/#{patient.id}/notes")}
    else
      handle_valid_params(patient, doctor_note, params, socket)
    end
  end

  defp handle_valid_params(patient, doctor_note, params, socket) do
    note_path = "/doctor/patients/#{patient.id}/notes/#{doctor_note.id}"
    current_tab = valid_tab(params["tab"])
    live_action = socket.assigns.live_action

    {view_entry, view_template, view_lab_result, view_patient, view_doctor} =
      resolve_view_lab_report(params, doctor_note, patient)

    {:noreply,
     socket
     |> assign(:patient, patient)
     |> assign(:note_path, note_path)
     |> assign(:view_lab_report_entry, view_entry)
     |> assign(:view_lab_report_template, view_template)
     |> assign(:view_lab_report_lab_result, view_lab_result)
     |> assign(:view_lab_report_patient, view_patient)
     |> assign(:view_lab_report_doctor, view_doctor)
     |> assign(
       :drug_allocations,
       tab_dataset(current_tab, "medication", fn ->
         DrugAllocations.list_drug_allocations_for_a_doctor_note(doctor_note.id)
       end)
     )
     |> assign(
       :lab_results,
       tab_dataset(current_tab, "lab_work", fn ->
         LabResults.list_lab_results_for_doctor_note(doctor_note.id)
       end)
     )
     |> assign_new(:form, fn -> to_form(DoctorNotes.change_doctor_note(doctor_note)) end)
     |> assign(:doctor_note, doctor_note)
     |> assign(:child_notes, DoctorNotes.get_child_notes_for_note(doctor_note.id))
     |> assign(:current_tab, current_tab)
     |> apply_action(live_action, params)
     |> then(fn s ->
       assign(s, :note_path_with_params, build_note_path_with_params(s.assigns))
     end)}
  end

  defp resolve_view_lab_report(%{"view_lab_report" => entry_id}, doctor_note, patient) do
    entry =
      try do
        LabTestTemplates.get_entry!(entry_id)
      rescue
        Ecto.NoResultsError -> nil
      end

    cond do
      entry == nil ->
        {nil, nil, nil, nil, nil}

      entry.lab_result == nil ->
        {nil, nil, nil, nil, nil}

      entry.lab_result.doctor_note_id != doctor_note.id ->
        {nil, nil, nil, nil, nil}

      entry.lab_result.patient_id != patient.id ->
        {nil, nil, nil, nil, nil}

      true ->
        lab_result = entry.lab_result
        template = entry.template
        {entry, template, lab_result, lab_result.patient, lab_result.doctor}
    end
  end

  defp resolve_view_lab_report(_params, _doctor_note, _patient), do: {nil, nil, nil, nil, nil}

  defp tab_dataset(current_tab, target_tab, fetch_fun, default \\ []) do
    if current_tab == target_tab, do: fetch_fun.(), else: default
  end

  defp valid_tab(nil), do: "overview"

  defp valid_tab(tab)
       when tab in ~w(overview medication lab_work),
       do: tab

  defp valid_tab(_), do: "overview"

  defp build_note_path_with_params(assigns) do
    base = Map.get(assigns, :note_path)
    tab = Map.get(assigns, :current_tab) || "overview"
    if base, do: base <> "?tab=#{tab}", else: "#"
  end

  # ... (keep existing apply_action functions) ...

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Add Doctor notes")
  end

  defp apply_action(socket, :after_create, _params) do
    socket |> assign(:page_title, "Listing Doctor notes") |> assign(:live_action, :after_create)
  end

  defp apply_action(socket, :request_lab, _params) do
    socket |> assign(:page_title, "Listing Doctor notes") |> assign(:live_action, :request_lab)
  end

  defp apply_action(socket, :request_radiology_test, _params) do
    socket
    |> assign(:page_title, "Request radiology test")
    |> assign(:live_action, :request_radiology_test)
  end

  defp apply_action(socket, :prescribe_drug, _params) do
    socket |> assign(:page_title, "Listing Doctor notes") |> assign(:live_action, :prescribe_drug)
  end

  defp apply_action(socket, :assign_new_drug, %{"drug_allocation_id" => drug_allocation_id}) do
    drug_allocation = DrugAllocations.get_drug_allocation!(drug_allocation_id)

    socket
    |> assign(:page_title, "Add Drug")
    |> assign(:drug_allocation, drug_allocation)
    |> assign(:live_action, :assign_new_drug)
  end

  # ... (keep other existing apply_action functions) ...

  @impl true
  def handle_event("validate", %{"doctor_note" => doctor_note_params}, socket) do
    params = maybe_fill_diagnosis_from_icd(doctor_note_params)
    changeset = DoctorNotes.change_doctor_note(socket.assigns.doctor_note, params)
    {:noreply, socket |> assign(:form, to_form(changeset, action: :validate))}
  end

  def handle_event("change-tab", %{"tab" => tab}, socket) do
    tab = valid_tab(tab)
    path = "#{socket.assigns.note_path}?tab=#{tab}"
    {:noreply, push_patch(socket, to: path)}
  end

  def handle_event("refresh-interpretation", %{"id" => id}, socket) do
    case LabResults.refresh_lab_result_interpretation(String.to_integer(id)) do
      {:ok, _lab_result} ->
        lab_results =
          LabResults.list_lab_results_for_doctor_note(socket.assigns.doctor_note.id)

        {:noreply,
         socket
         |> assign(:lab_results, lab_results)
         |> put_flash(:info, "AI analysis regenerated")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not regenerate the analysis right now")}
    end
  end

  def handle_event("run_ai_review", _params, socket) do
    doctor_note = socket.assigns.doctor_note

    cond do
      socket.assigns.ai_review_loading ->
        {:noreply, socket}

      not has_ai_review_source_data?(doctor_note) ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Add complaints, clinical notes, past medical history, impression, management, or investigations before running an AI review."
         )}

      true ->
        ai_client = ai_doc_reviewer_client()

        {:noreply,
         socket
         |> assign(:ai_review_loading, true)
         |> start_async(:run_ai_review, fn ->
           AIDocReviewer.refresh_doctor_note_review(doctor_note, ai_client)
         end)}
    end
  end

  # ... (keep all existing handle_event functions) ...

  def handle_event("save", %{"doctor_note" => doctor_note_params}, socket) do
    doctor_note_params =
      doctor_note_params
      |> Map.put("patient_id", socket.assigns.patient.id)
      |> Map.put("doctor_id", socket.assigns.current_user.id)

    case DoctorNotes.update_doctor_note(socket.assigns.doctor_note, doctor_note_params) do
      {:ok, _doctor_note} ->
        {:noreply,
         socket
         |> put_flash(:info, "Doctor note created successfully")
         |> push_event("draft_saved", %{})}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event(
        "delete_drug_assigned",
        %{"id" => id, "drug_allocation_id" => drug_allocation_id},
        socket
      ) do
    drug_allocation = DrugAllocations.get_drug_allocation!(drug_allocation_id)

    case DrugAllocations.remove_drug_assigned(drug_allocation, id) do
      {:ok, _updated_allocation} ->
        drug_allocations =
          DrugAllocations.list_drug_allocations_for_a_doctor_note(socket.assigns.doctor_note.id)

        {:noreply,
         socket
         |> assign(:drug_allocations, drug_allocations)
         |> put_flash(:info, "Drug removed successfully")}

      {:error, :already_dispensed} ->
        {:noreply,
         put_flash(socket, :error, "You cannot delete a drug that has already been given")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to remove drug")}
    end
  end

  def handle_event("remove_drug_allocation", %{"id" => id}, socket) do
    drug_allocation = DrugAllocations.get_drug_allocation!(id)

    case DrugAllocations.delete_drug_allocation(drug_allocation) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(
           :drug_allocations,
           DrugAllocations.list_drug_allocations_for_a_doctor_note(socket.assigns.doctor_note.id)
         )
         |> put_flash(:info, "Drug allocation deleted successfully")}

      {:error, :dispensed_drugs} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "You cannot delete a prescription after any drug has been given"
         )}

      {:error, :paid_prescription} ->
        {:noreply, put_flash(socket, :error, "You cannot delete a paid prescription")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to delete prescription")}
    end
  end

  def handle_event("toggle_main_note", _params, socket) do
    {:noreply, assign(socket, :main_note_expanded, !socket.assigns.main_note_expanded)}
  end

  def handle_event("open_add_sub_note", _params, socket) do
    sub_note_changeset = DoctorNotes.change_doctor_note(%Medcamp.DoctorNotes.DoctorNote{})

    {:noreply,
     socket
     |> assign(:show_sub_note_modal, true)
     |> assign(:sub_note_form, to_form(sub_note_changeset, as: :sub_doctor_note))}
  end

  def handle_event("close_sub_note_modal", _params, socket) do
    {:noreply, assign(socket, :show_sub_note_modal, false)}
  end

  def handle_event("validate_sub_note", %{"sub_doctor_note" => params}, socket) do
    changeset = DoctorNotes.change_doctor_note(%Medcamp.DoctorNotes.DoctorNote{}, params)

    {:noreply,
     assign(socket, :sub_note_form, to_form(changeset, action: :validate, as: :sub_doctor_note))}
  end

  def handle_event("save_sub_note", %{"sub_doctor_note" => params}, socket) do
    attrs =
      params
      |> Map.put("patient_id", socket.assigns.patient.id)
      |> Map.put("doctor_id", socket.assigns.current_user.id)
      |> Map.put("parent_id", socket.assigns.doctor_note.id)

    case DoctorNotes.create_child_doctor_note(attrs) do
      {:ok, _child_note} ->
        {:noreply,
         socket
         |> assign(:show_sub_note_modal, false)
         |> assign(
           :child_notes,
           DoctorNotes.get_child_notes_for_note(socket.assigns.doctor_note.id)
         )
         |> put_flash(:info, "Sub-note added successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :sub_note_form, to_form(changeset, as: :sub_doctor_note))}
    end
  end

  def handle_event("toggle_sub_note", %{"id" => id}, socket) do
    id = String.to_integer(id)
    expanded = socket.assigns.expanded_sub_note_ids

    new_expanded =
      if id in expanded do
        List.delete(expanded, id)
      else
        [id | expanded]
      end

    {:noreply, assign(socket, :expanded_sub_note_ids, new_expanded)}
  end

  defp ai_doc_reviewer_client do
    Application.get_env(:medcamp, :ai_doc_reviewer_client, Medcamp.ArtificialIntelligence.OpenAI)
  end

  @impl true
  def handle_async(:run_ai_review, {:ok, {:ok, doctor_note}}, socket) do
    {:noreply,
     socket
     |> assign(:ai_review_loading, false)
     |> assign(:doctor_note, doctor_note)
     |> put_flash(:info, "AI review generated")}
  end

  def handle_async(:run_ai_review, {:ok, {:error, reason}}, socket) do
    Logger.error(
      "AI review failed for doctor_note=#{socket.assigns.doctor_note.id}: #{inspect(reason)}"
    )

    {:noreply,
     socket
     |> assign(:ai_review_loading, false)
     |> put_flash(:error, "Could not generate the AI review right now")}
  end

  def handle_async(:run_ai_review, {:exit, reason}, socket) do
    Logger.error(
      "AI review task crashed for doctor_note=#{socket.assigns.doctor_note.id}: #{inspect(reason)}"
    )

    {:noreply,
     socket
     |> assign(:ai_review_loading, false)
     |> put_flash(:error, "Could not generate the AI review right now")}
  end

  defp maybe_fill_diagnosis_from_icd(params) do
    case Map.get(params, "diagnosis_icd_code") do
      nil ->
        params

      "" ->
        params

      code ->
        title = Medcamp.Icd11.list() |> Enum.find_value(fn {c, t} -> if c == code, do: t end)
        if title, do: Map.put(params, "diagnosis", title), else: params
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="w-full flex justify-between items-center mb-4">
        <.link
          navigate={"/doctor/patients/#{@patient.id}/notes"}
          class="flex gap-2 cursor-pointer text-brand-primary font-semibold items-center hover:text-brand-accent transition-colors"
        >
          <Heroicons.icon name="arrow-left" type="outline" class="h-4 w-4" />
          <p>Back to Doctor's Notes</p>
        </.link>
      </div>

      <.doctor_note_tabs
        current_tab={@current_tab}
        tabs={[
          %{id: "overview", label: "Overview", icon_name: "document-text"},
          %{
            id: "medication",
            label: "Medication",
            icon_markup: "<i class=\"fa fa-diamond\" aria-hidden=\"true\"></i>",
            icon_name: nil
          },
          %{id: "lab_work", label: "Lab Work", icon_name: "beaker"}
        ]}
      />

      <div :if={@current_tab == "overview"}>
        <div class="bg-white rounded-lg shadow-sm border border-slate-200 mb-4 overflow-hidden">
          <button
            type="button"
            phx-click="toggle_main_note"
            class="w-full flex items-center justify-between px-6 py-4 hover:bg-slate-50 transition-colors text-left"
          >
            <div class="flex items-center gap-2">
              <Heroicons.icon name="document-text" type="outline" class="h-5 w-5 text-brand-accent" />
              <span class="text-base font-semibold text-brand-primary">
                Consultation Details — Dr. {@doctor_note.doctor.name}
              </span>
              <span class="text-xs text-slate-500 ml-1">
                {@doctor_note.date} at {@doctor_note.time}
              </span>
            </div>
            <Heroicons.icon
              name={if @main_note_expanded, do: "chevron-up", else: "chevron-down"}
              type="outline"
              class="h-5 w-5 text-slate-400 flex-shrink-0"
            />
          </button>
          <div :if={@main_note_expanded} class="border-t border-slate-100 px-2 py-2">
            <.doctor_notes_form
              patient={@patient}
              show_lab_imaging_request={true}
              form={@form}
              draft_key={"doctor_note:#{@patient.id}:#{@doctor_note.id}"}
            />
          </div>
        </div>
      </div>

      <div :if={@current_tab == "ai_review"}>
        <div class="bg-white rounded-lg shadow-sm border border-slate-200 mb-4 overflow-hidden">
          <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100">
            <div class="flex items-center gap-2">
              <Heroicons.icon name="sparkles" type="outline" class="h-5 w-5 text-brand-accent" />
              <span class="text-base font-semibold text-brand-primary">AI Review</span>
            </div>
            <button
              :if={has_ai_review_source_data?(@doctor_note)}
              type="button"
              phx-click="run_ai_review"
              phx-disable-with="Reviewing..."
              disabled={@ai_review_loading}
              class="inline-flex items-center gap-1.5 rounded-lg bg-brand-accent px-3 py-1.5 text-sm font-medium text-white hover:bg-brand-accent-dark disabled:opacity-60 disabled:cursor-not-allowed"
            >
              {if @doctor_note.ai_review_status == "completed",
                do: "Regenerate",
                else: "Run AI Review"}
            </button>
          </div>

          <div class="px-6 py-4">
            <%= cond do %>
              <% @ai_review_loading -> %>
                <div class="flex flex-col items-center justify-center gap-3 py-10 text-center">
                  <div class="h-8 w-8 animate-spin rounded-full border-2 border-brand-accent border-t-transparent">
                  </div>
                  <p class="text-sm text-slate-500">
                    Generating your AI review — this can take a few seconds...
                  </p>
                </div>
              <% !has_ai_review_source_data?(@doctor_note) -> %>
                <p class="text-sm text-slate-500">
                  Add complaints, clinical notes, past medical history, impression, management,
                  or investigations to enable an AI review.
                </p>
              <% @doctor_note.ai_review_status != "completed" -> %>
                <p class="text-sm text-slate-500">
                  Run an AI review to get an independent second opinion on this case — a tailored,
                  case-specific reference lookup, not a replacement for your own judgement.
                </p>
              <% Map.get(@doctor_note.ai_review_payload, "schema_version") != "2.0" -> %>
                <p class="text-sm text-slate-500">
                  This review was generated by an earlier version of the AI Review format.
                  Regenerate to see it in the current format.
                </p>
              <% true -> %>
                <% payload = @doctor_note.ai_review_payload %>
                <% data_quality = Map.get(payload, "data_quality", %{}) %>
                <% urgency = Map.get(payload, "urgency", %{}) %>
                <% impression = Map.get(payload, "independent_impression", %{}) %>
                <% medication_review = Map.get(payload, "medication_review", %{}) %>
                <% medication_options = Map.get(medication_review, "options_to_consider", []) %>
                <% medication_concerns =
                  Map.get(medication_review, "allergy_conflicts", []) ++
                    Map.get(medication_review, "interaction_warnings", []) ++
                    Map.get(medication_review, "existing_medication_concerns", []) %>
                <% closeness = Map.get(payload, "closeness", %{}) %>
                <div class="space-y-5">
                  <div
                    :if={Map.get(data_quality, "sufficient_for_review", true) == false}
                    class="rounded-lg border border-amber-200 bg-amber-50 p-3"
                  >
                    <h4 class="text-sm font-semibold text-amber-900">
                      Complete the clinical picture
                    </h4>
                    <ul class="mt-1 list-disc space-y-0.5 pl-5">
                      <li
                        :for={
                          item <-
                            Map.get(data_quality, "missing_critical_information", []) |> Enum.take(3)
                        }
                        class="text-sm text-amber-800"
                      >
                        {item}
                      </li>
                    </ul>
                  </div>

                  <div class="rounded-lg border border-slate-200 bg-slate-50 p-4">
                    <div class="flex flex-wrap items-center gap-2">
                      <h4 class="text-sm font-semibold text-slate-900">Clinical impression</h4>
                      <span class={[
                        "px-2 py-0.5 text-xs rounded-full font-medium",
                        urgency_badge_class(Map.get(urgency, "level"))
                      ]}>
                        {Map.get(urgency, "level", "routine") |> to_string() |> String.capitalize()} priority
                      </span>
                      <span class="rounded-full bg-white px-2 py-0.5 text-xs font-medium text-slate-600 ring-1 ring-slate-200">
                        {Map.get(impression, "evidence_strength", "weak") |> String.capitalize()} evidence
                      </span>
                      <span
                        :if={Map.get(closeness, "status") == "computed"}
                        class="rounded-full bg-brand-50 px-2 py-0.5 text-xs font-medium text-brand-primary"
                      >
                        {Map.get(closeness, "score")}% diagnosis alignment
                      </span>
                    </div>
                    <p class="mt-2 text-sm text-slate-700">{Map.get(impression, "summary")}</p>
                    <p
                      :if={Map.get(closeness, "status") == "computed" and closeness["explanation"]}
                      class="mt-1 text-xs text-slate-500"
                    >
                      {closeness["explanation"]}
                    </p>

                    <div
                      :if={Map.get(urgency, "red_flags", []) != []}
                      class="mt-3 border-t border-slate-200 pt-3"
                    >
                      <p class="mb-1 text-xs font-semibold uppercase tracking-wide text-red-700">
                        Red flags
                      </p>
                      <ul class="space-y-1.5">
                        <li
                          :for={flag <- Map.get(urgency, "red_flags", []) |> Enum.take(3)}
                          class="text-sm text-red-800"
                        >
                          <span class="font-medium">{flag["finding"]}</span>
                          <span :if={flag["suggested_action"]}>— {flag["suggested_action"]}</span>
                        </li>
                      </ul>
                    </div>
                  </div>

                  <div class="grid gap-5 lg:grid-cols-2">
                    <div :if={Map.get(payload, "differential_diagnoses", []) != []}>
                      <h4 class="mb-2 text-sm font-semibold text-slate-900">Top differentials</h4>
                      <ol class="space-y-2">
                        <li
                          :for={
                            {dx, index} <-
                              Map.get(payload, "differential_diagnoses", [])
                              |> Enum.take(3)
                              |> Enum.with_index(1)
                          }
                          class="flex gap-2 text-sm text-slate-700"
                        >
                          <span class="font-semibold text-slate-400">{index}.</span>
                          <div>
                            <div class="flex flex-wrap items-center gap-1.5">
                              <span class="font-medium">{dx["condition"]}</span>
                              <span class={[
                                "rounded-full px-2 py-0.5 text-xs font-medium",
                                likelihood_badge_class(dx["likelihood"])
                              ]}>
                                {String.replace(dx["likelihood"] || "possible", "_", " ")
                                |> String.capitalize()}
                              </span>
                            </div>
                            <p :if={dx["rationale"]} class="mt-0.5 text-xs text-slate-500">
                              {dx["rationale"]}
                            </p>
                          </div>
                        </li>
                      </ol>
                    </div>

                    <div :if={Map.get(payload, "recommended_next_steps", []) != []}>
                      <h4 class="mb-2 text-sm font-semibold text-slate-900">Priority actions</h4>
                      <ul class="space-y-2">
                        <li
                          :for={
                            step <-
                              Map.get(payload, "recommended_next_steps", []) |> Enum.take(4)
                          }
                          class="flex items-start gap-2 text-sm text-slate-700"
                        >
                          <span class={[
                            "mt-0.5 rounded-full px-2 py-0.5 text-xs font-medium",
                            urgency_badge_class(step["priority"])
                          ]}>
                            {String.capitalize(step["priority"] || "routine")}
                          </span>
                          <span class="font-medium">{step["action"]}</span>
                        </li>
                      </ul>
                    </div>
                  </div>

                  <div
                    :if={medication_options != []}
                    class="rounded-lg border border-indigo-200 bg-indigo-50 p-4"
                  >
                    <div class="mb-2 flex items-center gap-2">
                      <Heroicons.icon name="beaker" type="outline" class="h-4 w-4 text-indigo-700" />
                      <h4 class="text-sm font-semibold text-indigo-950">
                        Suggested medications
                      </h4>
                    </div>
                    <ul class="grid gap-3 lg:grid-cols-3">
                      <li
                        :for={option <- Enum.take(medication_options, 3)}
                        class="rounded-md border border-indigo-100 bg-white p-3 text-sm"
                      >
                        <p class="font-semibold text-slate-900">{option["generic_name"]}</p>
                        <p :if={option["dose"]} class="font-medium text-indigo-800">
                          {option["dose"]}
                        </p>
                        <p :if={option["indication"]} class="mt-1 text-xs text-slate-600">
                          For {option["indication"]}
                        </p>
                        <p
                          :if={Map.get(option, "contraindications_or_cautions", []) != []}
                          class="mt-1 text-xs text-amber-700"
                        >
                          Caution: {option["contraindications_or_cautions"]
                          |> Enum.take(2)
                          |> Enum.join("; ")}
                        </p>
                      </li>
                    </ul>
                    <p class="mt-2 text-xs text-indigo-700">
                      Confirm allergies, contraindications, interactions, and patient-specific dosing before prescribing.
                    </p>
                  </div>

                  <div
                    :if={medication_concerns != [] or Map.get(payload, "safety_netting", []) != []}
                    class="grid gap-3 lg:grid-cols-2"
                  >
                    <div
                      :if={medication_concerns != []}
                      class="rounded-lg border border-red-200 bg-red-50 p-3"
                    >
                      <h4 class="text-sm font-semibold text-red-900">Medication warnings</h4>
                      <ul class="mt-1 list-disc space-y-0.5 pl-5">
                        <li
                          :for={warning <- Enum.take(medication_concerns, 3)}
                          class="text-sm text-red-800"
                        >
                          {warning}
                        </li>
                      </ul>
                    </div>

                    <div
                      :if={Map.get(payload, "safety_netting", []) != []}
                      class="rounded-lg border border-amber-200 bg-amber-50 p-3"
                    >
                      <h4 class="text-sm font-semibold text-amber-900">Escalate if</h4>
                      <ul class="mt-1 space-y-1">
                        <li
                          :for={item <- Map.get(payload, "safety_netting", []) |> Enum.take(3)}
                          class="text-sm text-amber-800"
                        >
                          <span class="font-medium">{item["trigger"]}:</span> {item["action"]}
                        </li>
                      </ul>
                    </div>
                  </div>

                  <p class="text-xs text-slate-400 border-t border-slate-100 pt-3">
                    {Map.get(payload, "disclaimer")}
                    <span :if={@doctor_note.ai_review_generated_at}>
                      · Generated {format_datetime(@doctor_note.ai_review_generated_at)}
                    </span>
                  </p>
                </div>
            <% end %>
          </div>
        </div>
      </div>

      <div :if={@current_tab == "overview"}>
        <.child_doctor_notes_section
          child_notes={@child_notes}
          parent_note_id={@doctor_note.id}
          current_user={@current_user}
          expanded_ids={@expanded_sub_note_ids}
        />
      </div>

      <.lab_results_card
        :if={@current_tab == "lab_work"}
        lab_results={@lab_results}
        patient={@patient}
        doctor_note={@doctor_note}
        note_path={@note_path}
        regenerate={true}
      />

      <.drug_allocations_section
        :if={@current_tab == "medication"}
        drug_allocations={@drug_allocations}
        patient={@patient}
        doctor_note={@doctor_note}
      />
      
    <!-- Keep all existing modals... -->
      <.modal
        :if={@live_action in [:after_create]}
        id="patient-modal"
        show
        on_cancel={JS.patch(@note_path_with_params)}
      >
        <.live_component
          module={MedcampWeb.AfterCreateNoteComponent}
          id={:new}
          title={@page_title}
          action={@live_action}
          patient={@patient}
          doctor_note={@doctor_note}
          patch={@note_path_with_params}
        />
      </.modal>

      <.modal
        :if={@live_action in [:request_lab, :prescribe_drug]}
        id="patient-modal"
        show
        on_cancel={JS.patch(@note_path_with_params)}
      >
        <.live_component
          module={
            if @live_action == :request_lab,
              do: MedcampWeb.RequestLabComponent,
              else: MedcampWeb.PrescribeMedicineComponent
          }
          id={:request_lab}
          title={@page_title}
          lab_result={%LabResult{}}
          drug_allocation={%DrugAllocation{}}
          action={@live_action}
          current_user={@current_user}
          patient={@patient}
          return_url={@note_path_with_params}
          doctor_note={@doctor_note}
          patch={@note_path_with_params}
        />
      </.modal>

      <.modal
        :if={@live_action in [:assign_new_drug]}
        id="patient-modal"
        show
        on_cancel={JS.patch(@note_path_with_params)}
      >
        <.live_component
          module={MedcampWeb.NewDrugAssignedComponent}
          id={:request_lab}
          title={@page_title}
          drug_allocation={@drug_allocation}
          action={@live_action}
          current_user={@current_user}
          patient={@patient}
          return_url={@note_path_with_params}
          doctor_note={@doctor_note}
          patch={@note_path_with_params}
        />
      </.modal>
      <.modal
        :if={@show_sub_note_modal}
        id="sub-note-modal"
        show
        on_cancel={JS.push("close_sub_note_modal")}
      >
        <div class="px-2 py-2">
          <div class="flex items-center gap-2 mb-4">
            <Heroicons.icon name="document-plus" type="outline" class="h-5 w-5 text-brand-accent" />
            <h3 class="text-lg font-semibold text-brand-primary">Add Sub-note</h3>
          </div>
          <p class="text-sm text-slate-500 mb-4">
            Adding a sub-note to the note started by Dr. {@doctor_note.doctor.name} on {@doctor_note.date}.
          </p>
          <.sub_doctor_note_form form={@sub_note_form} patient={@patient} />
        </div>
      </.modal>

      <.modal
        :if={@view_lab_report_entry}
        id="lab-report-modal"
        show
        on_cancel={JS.patch(@note_path_with_params)}
      >
        <.live_component
          module={MedcampWeb.LabPagesLabResultLive.TestResultDocumentComponent}
          id={:doctor_view_results}
          entry={@view_lab_report_entry}
          template={@view_lab_report_template}
          lab_result={@view_lab_report_lab_result}
          patient={@view_lab_report_patient}
          doctor={@view_lab_report_doctor}
          back_to={@note_path_with_params}
          back_label="Back to Note"
        />
      </.modal>
    </div>
    """
  end

  defp has_ai_review_source_data?(doctor_note) do
    [
      doctor_note.reason_for_consulatation,
      doctor_note.clinical_notes,
      doctor_note.past_medical_history,
      doctor_note.impression,
      doctor_note.management,
      doctor_note.investigations
    ]
    |> Enum.any?(fn
      value when is_binary(value) -> String.trim(value) != ""
      _value -> false
    end)
  end

  defp urgency_badge_class("emergency"), do: "bg-red-100 text-red-800"
  defp urgency_badge_class("urgent"), do: "bg-orange-100 text-orange-800"
  defp urgency_badge_class("routine"), do: "bg-green-100 text-green-800"
  defp urgency_badge_class(_), do: "bg-slate-100 text-slate-700"

  defp likelihood_badge_class("most_likely"), do: "bg-brand-50 text-brand-primary"
  defp likelihood_badge_class("possible"), do: "bg-slate-100 text-slate-700"
  defp likelihood_badge_class("less_likely"), do: "bg-slate-50 text-slate-500"
  defp likelihood_badge_class(_), do: "bg-slate-100 text-slate-700"

  defp format_datetime(nil), do: "—"

  defp format_datetime(%NaiveDateTime{} = datetime) do
    Calendar.strftime(datetime, "%d %b %Y %H:%M")
  end

  defp format_datetime(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%d %b %Y %H:%M")
  end
end
