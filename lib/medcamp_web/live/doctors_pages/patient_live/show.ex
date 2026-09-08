defmodule MedcampWeb.DoctorsPagePatientLive.Show do
  use MedcampWeb, :each_patient_live_view

  alias Medcamp.AllergyHistories
  alias Medcamp.AllergyHistories.AllergyHistory
  alias Medcamp.Patients
  alias Medcamp.Triages
  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :overview)
     |> assign(:show_edit_patient_modal, false)
     |> assign(:show_allergy_modal, false)
     |> assign(:editing_allergy, nil)}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    patient = Patients.get_patient!(id)

    most_recent_triage = Triages.most_recent_triage(id)

    {:noreply,
     socket
     |> assign(:page_title, "Patient Overview")
     |> assign(:most_recent_triage, most_recent_triage)
     |> assign(:patient, patient)
     |> assign(:form, to_form(Patients.change_patient(patient)))
     |> assign_allergy_histories()}
  end

  defp assign_allergy_histories(socket) do
    assign(
      socket,
      :allergy_histories,
      AllergyHistories.list_allergy_histories_for_patient(socket.assigns.patient.id)
    )
  end

  @impl true
  def handle_event("validate", %{"patient" => patient_params}, socket) do
    case Patients.update_patient(socket.assigns.patient, patient_params) do
      {:ok, patient} ->
        {:noreply,
         socket
         |> assign(:patient, patient)
         |> assign(:form, to_form(Patients.change_patient(patient)))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("open_allergy_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_allergy_modal, true)
     |> assign(:editing_allergy, nil)
     |> assign(:allergy_form, to_form(AllergyHistories.change_allergy_history(%AllergyHistory{})))}
  end

  def handle_event("edit_allergy", %{"id" => id}, socket) do
    allergy_history = AllergyHistories.get_allergy_history!(id)

    {:noreply,
     socket
     |> assign(:show_allergy_modal, true)
     |> assign(:editing_allergy, allergy_history)
     |> assign(
       :allergy_form,
       to_form(AllergyHistories.change_allergy_history(allergy_history))
     )}
  end

  def handle_event("close_allergy_modal", _params, socket) do
    {:noreply, assign(socket, :show_allergy_modal, false)}
  end

  def handle_event("save_allergy", %{"allergy_history" => params}, socket) do
    params = Map.put(params, "patient_id", socket.assigns.patient.id)

    result =
      case socket.assigns.editing_allergy do
        nil ->
          params = Map.put(params, "recorded_by_id", socket.assigns.current_user.id)
          AllergyHistories.create_allergy_history(params)

        %AllergyHistory{} = allergy_history ->
          AllergyHistories.update_allergy_history(allergy_history, params)
      end

    case result do
      {:ok, _allergy_history} ->
        {:noreply,
         socket
         |> assign(:show_allergy_modal, false)
         |> assign_allergy_histories()
         |> put_flash(:info, "Allergy history saved")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :allergy_form, to_form(changeset))}
    end
  end

  def handle_event("delete_allergy", %{"id" => id}, socket) do
    allergy_history = AllergyHistories.get_allergy_history!(id)
    {:ok, _} = AllergyHistories.delete_allergy_history(allergy_history)

    {:noreply,
     socket
     |> assign_allergy_histories()
     |> put_flash(:info, "Allergy history entry removed")}
  end

  @impl true
  def handle_event("edit_patient", _params, socket) do
    {:noreply, assign(socket, :show_edit_patient_modal, true)}
  end

  @impl true
  def handle_event("close_edit_patient_modal", _params, socket) do
    {:noreply, assign(socket, :show_edit_patient_modal, false)}
  end

  @impl true
  def handle_info({:patient_updated, patient}, socket) do
    patient = Patients.get_patient!(patient.id)

    {:noreply,
     socket
     |> assign(:patient, patient)
     |> assign(:form, to_form(Patients.change_patient(patient)))
     |> assign(:show_edit_patient_modal, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.patient_overview
        most_recent_triage={@most_recent_triage}
        patient={@patient}
        form={@form}
        back_url="/doctor/patients"
      />

      <.modal
        :if={@show_edit_patient_modal}
        id="edit-patient-modal"
        show
        on_cancel={JS.push("close_edit_patient_modal")}
      >
        <.live_component
          module={MedcampWeb.EditPatientComponent}
          id={"edit-patient-#{@patient.id}"}
          patient={@patient}
          current_user={@current_user}
        />
      </.modal>
      <div class="mt-6 rounded-lg border border-gray-100 bg-white p-5 shadow-sm">
        <div class="mb-4 flex items-center justify-between gap-3">
          <div>
            <h3 class="text-lg font-semibold text-brand-primary">Allergy History</h3>
            <p class="text-sm text-gray-500">Known allergies and intolerances for this patient.</p>
          </div>
          <button
            type="button"
            phx-click="open_allergy_modal"
            class="inline-flex items-center gap-2 rounded-lg bg-brand-primary px-3 py-2 text-sm font-medium text-white hover:bg-[#2f327d]"
          >
            <.icon name="hero-plus" class="h-4 w-4" /> Add Allergy
          </button>
        </div>

        <%= if @allergy_histories == [] do %>
          <p class="text-sm text-gray-500">No allergy history recorded for this patient.</p>
        <% else %>
          <ul class="divide-y divide-gray-200">
            <li :for={allergy <- @allergy_histories} class="py-3">
              <div class="flex items-start justify-between gap-4">
                <div class="min-w-0">
                  <div class="flex flex-wrap items-center gap-2">
                    <p class="font-medium text-gray-900">{allergy.substance_name}</p>
                    <span class={[
                      "px-2 py-0.5 rounded-full text-xs font-medium",
                      criticality_badge_class(allergy.criticality)
                    ]}>
                      {Phoenix.Naming.humanize(allergy.criticality)} criticality
                    </span>
                    <span class={[
                      "px-2 py-0.5 rounded-full text-xs font-medium",
                      clinical_status_badge_class(allergy.clinical_status)
                    ]}>
                      {Phoenix.Naming.humanize(allergy.clinical_status)}
                    </span>
                  </div>
                  <p class="mt-1 text-sm text-gray-500">
                    {Phoenix.Naming.humanize(allergy.category)} · {Phoenix.Naming.humanize(
                      allergy.type
                    )}
                    <%= if allergy.reaction_manifestation do %>
                      · Reaction: {allergy.reaction_manifestation}
                      <%= if allergy.reaction_severity do %>
                        ({allergy.reaction_severity})
                      <% end %>
                    <% end %>
                  </p>
                  <p :if={allergy.notes} class="mt-1 text-sm text-gray-700">{allergy.notes}</p>
                  <p class="mt-1 text-xs text-gray-400">
                    Recorded {Calendar.strftime(allergy.inserted_at, "%d %b %Y")}
                    <%= if allergy.recorded_by do %>
                      by {allergy.recorded_by.name}
                    <% end %>
                  </p>
                </div>
                <div class="flex shrink-0 items-center gap-3">
                  <button
                    type="button"
                    phx-click="edit_allergy"
                    phx-value-id={allergy.id}
                    class="text-sm font-medium text-brand-primary hover:text-[#2f327d]"
                  >
                    Edit
                  </button>
                  <button
                    type="button"
                    phx-click="delete_allergy"
                    phx-value-id={allergy.id}
                    data-confirm="Remove this allergy history entry?"
                    class="text-sm font-medium text-rose-600 hover:text-rose-800"
                  >
                    Remove
                  </button>
                </div>
              </div>
            </li>
          </ul>
        <% end %>
      </div>

      <.modal
        :if={@show_allergy_modal}
        id="allergy-history-modal"
        show
        on_cancel={JS.push("close_allergy_modal")}
      >
        <h3 class="text-lg font-semibold text-gray-900">
          {if @editing_allergy, do: "Edit Allergy", else: "Add Allergy"}
        </h3>

        <.simple_form for={@allergy_form} phx-submit="save_allergy" class="mt-4">
          <.input
            field={@allergy_form[:substance_name]}
            type="text"
            label="Allergen / Substance"
            required
          />

          <div class="grid grid-cols-2 gap-4">
            <.input
              field={@allergy_form[:category]}
              type="select"
              label="Category"
              prompt="Select category"
              options={Enum.map(AllergyHistory.categories(), &{Phoenix.Naming.humanize(&1), &1})}
            />
            <.input
              field={@allergy_form[:type]}
              type="select"
              label="Type"
              prompt="Select type"
              options={Enum.map(AllergyHistory.types(), &{Phoenix.Naming.humanize(&1), &1})}
            />
            <.input
              field={@allergy_form[:criticality]}
              type="select"
              label="Criticality"
              prompt="Select criticality"
              options={Enum.map(AllergyHistory.criticalities(), &{Phoenix.Naming.humanize(&1), &1})}
            />
            <.input
              field={@allergy_form[:clinical_status]}
              type="select"
              label="Clinical status"
              options={
                Enum.map(AllergyHistory.clinical_statuses(), &{Phoenix.Naming.humanize(&1), &1})
              }
            />
            <.input
              field={@allergy_form[:verification_status]}
              type="select"
              label="Verification status"
              options={
                Enum.map(AllergyHistory.verification_statuses(), &{Phoenix.Naming.humanize(&1), &1})
              }
            />
            <.input field={@allergy_form[:onset_date]} type="date" label="Onset date" />
          </div>

          <.input
            field={@allergy_form[:reaction_manifestation]}
            type="text"
            label="Reaction (what happens)"
            placeholder="e.g. Hives, swelling, anaphylaxis"
          />
          <.input
            field={@allergy_form[:reaction_severity]}
            type="select"
            label="Reaction severity"
            prompt="Select severity"
            options={Enum.map(AllergyHistory.severities(), &{Phoenix.Naming.humanize(&1), &1})}
          />
          <.input field={@allergy_form[:notes]} type="textarea" label="Notes" />

          <:actions>
            <button
              type="button"
              phx-click="close_allergy_modal"
              class="px-4 py-2 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-100"
            >
              Cancel
            </button>
            <.button phx-disable-with="Saving...">Save Allergy</.button>
          </:actions>
        </.simple_form>
      </.modal>
    </div>
    """
  end

  defp criticality_badge_class("high"), do: "bg-rose-100 text-rose-800"
  defp criticality_badge_class("low"), do: "bg-green-100 text-green-800"
  defp criticality_badge_class(_), do: "bg-slate-100 text-slate-600"

  defp clinical_status_badge_class("active"), do: "bg-amber-100 text-amber-800"
  defp clinical_status_badge_class("resolved"), do: "bg-slate-100 text-slate-600"
  defp clinical_status_badge_class(_), do: "bg-slate-100 text-slate-600"
end
