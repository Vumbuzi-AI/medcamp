defmodule MedcampWeb.LabPagesEachPatientLabResultLive.Show do
  use MedcampWeb, :lab_each_patient_live_view

  alias Medcamp.LabResults
  alias Medcamp.Patients

  @impl true
  def mount(%{"patient_id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:patient, Patients.get_patient!(id))
     |> assign(:active_tab, :lab_results)}
  end

  @impl true
  def handle_params(%{"id" => id, "complete" => "true"} = _params, _url, socket) do
    lab_result = LabResults.get_lab_result!(id)

    {:noreply,
     socket
     |> assign(:live_action, :complete)
     |> assign(:lab_result, lab_result)
     |> assign(:patient, Patients.get_patient!(lab_result.patient_id))
     |> assign_new(:form, fn ->
       to_form(LabResults.change_lab_result(lab_result))
     end)}
  end

  def handle_params(%{"id" => id} = _params, _url, socket) do
    lab_result = LabResults.get_lab_result!(id)

    {:noreply,
     socket
     |> assign(:live_action, :index)
     |> assign(:patient, Patients.get_patient!(lab_result.patient_id))
     |> assign(:lab_result, lab_result)
     |> assign_new(:form, fn ->
       to_form(LabResults.change_lab_result(lab_result))
     end)}
  end

  @impl true
  def handle_event("refresh-interpretation", %{"id" => id}, socket) do
    case LabResults.refresh_lab_result_interpretation(String.to_integer(id)) do
      {:ok, lab_result} ->
        {:noreply,
         socket
         |> assign(:lab_result, lab_result)
         |> put_flash(:info, "AI lab data generated")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not generate AI lab data right now")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="w-[100%] flex justify-between">
        <.link navigate={"/lab/#{@patient.id}/lab_results"}>
          <Heroicons.icon name="arrow-left" type="outline" class="h-4 w-4 text-darkblue" />
        </.link>
        <.link navigate={"/lab/#{@patient.id}/lab_results/#{@lab_result.id}?complete=true"}>
          <.button :if={!@lab_result.report_complete}>
            Submit Lab Result
          </.button>
        </.link>
      </div>
      <%= if @lab_result.report_complete do %>
        <.complete_lab_result_card form={@form} patient={@patient} lab_result={@lab_result} />
      <% else %>
        <.incomplete_lab_result_card patient={@patient} lab_result={@lab_result} />
      <% end %>

      <.modal
        :if={@live_action in [:complete]}
        id="drug_allocation-modal"
        show
        on_cancel={JS.patch(~p"/lab/lab_results/#{@lab_result.id}")}
      >
        <.live_component
          module={MedcampWeb.LabPagesLabResultLive.FormComponent}
          id={@lab_result.id || :new}
          title="New"
          action={@live_action}
          current_user={@current_user}
          lab_result={@lab_result}
          patch={~p"/lab/lab_results/#{@lab_result.id}"}
        />
      </.modal>
    </div>
    """
  end
end
