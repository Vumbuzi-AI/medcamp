defmodule MedcampWeb.PharmacistsLive.EachPatientDrugAllocationsIndex do
  use MedcampWeb, :pharmacist_each_patient_live_view

  alias Medcamp.DrugAllocations
  alias Medcamp.DrugAllocations.DrugAllocation
  alias Medcamp.Patients

  @per_page 10

  @impl true
  def mount(%{"patient_id" => id}, _session, socket) do
    patients = Patients.list_patients_for_selection()

    {:ok,
     socket
     |> assign(:patients, patients)
     |> assign(:patient, Patients.get_patient!(id))
     |> assign(:active_tab, :drug_allocations)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_drug_allocations()}
  end

  defp load_drug_allocations(socket) do
    patient_id = socket.assigns.patient.id
    total_count = DrugAllocations.count_drug_allocations_for_a_patient(patient_id)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    drug_allocations =
      DrugAllocations.list_drug_allocations_for_a_patient_paginated(
        patient_id,
        page,
        socket.assigns.per_page
      )

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:drug_allocations, drug_allocations)
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Drug allocation")
    |> assign(:drug_allocation, DrugAllocations.get_drug_allocation!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Drug allocation")
    |> assign(:drug_allocation, %DrugAllocation{})
    |> assign(:live_action, :new)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Drug allocations")
    |> assign(:drug_allocation, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    drug_allocation = DrugAllocations.get_drug_allocation!(id)

    case DrugAllocations.delete_drug_allocation(drug_allocation) do
      {:ok, _} ->
        {:noreply, load_drug_allocations(socket)}

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

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_drug_allocations()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-slate-100 p-4">
      <.header class="text-brand-primary border-b border-slate-100 pb-4 mb-4">
        <div class="flex items-center">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5 mr-2 text-brand-accent"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
            />
          </svg>
          Listing Drug allocations for {[
            @patient.first_name,
            @patient.middle_name,
            @patient.last_name
          ]
          |> Enum.filter(&(&1 != nil))
          |> Enum.join(" ")}
        </div>
      </.header>

      <%= if @total_count == 0 do %>
        <div class="text-center py-8 bg-slate-50 rounded-lg border border-dashed border-slate-300">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="mx-auto h-12 w-12 text-slate-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
            />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-slate-900">No drug allocations</h3>
          <p class="mt-1 text-sm text-slate-500">
            No drug allocations have been recorded for this patient yet.
          </p>
        </div>
      <% else %>
        <.data_table
          id="drug_allocations"
          rows={@drug_allocations}
          row_click={
            fn drug_allocation ->
              JS.navigate("/pharmacist/drug_allocations/#{drug_allocation.id}")
            end
          }
          row_id={&"drug_allocations-#{&1.id}"}
        >
          <:col :let={drug_allocation} label="Prescription">
            <div class="max-w-xs py-3">
              <span class="text-slate-700 line-clamp-2">{drug_allocation.prescription}</span>
            </div>
          </:col>

          <:col :let={drug_allocation} label="Has Been Assigned">
            <div class="flex justify-center items-center py-3">
              <%= if drug_allocation.has_been_assigned do %>
                <div class="flex items-center text-green-700">
                  <Heroicons.icon name="check" type="solid" class="h-5 w-5 text-green-500" />
                  <span class="ml-1 text-sm">Assigned</span>
                </div>
              <% else %>
                <div class="flex items-center text-red-700">
                  <Heroicons.icon name="x-mark" type="solid" class="h-5 w-5 text-red-500" />
                  <span class="ml-1 text-sm">Pending</span>
                </div>
              <% end %>
            </div>
          </:col>

          <:col :let={drug_allocation} label="Payment Type">
            <div class="flex items-center py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-blue-100 text-blue-800">
                {drug_allocation.payment_type}
              </span>
            </div>
          </:col>

          <:col :let={drug_allocation} label="Payment Status">
            <div class="flex items-center py-3">
              <%= if drug_allocation.has_paid do %>
                <span class="px-2 py-1 text-xs rounded-full bg-green-100 text-green-800 font-medium">
                  Paid
                </span>
              <% else %>
                <.link patch={"/pharmacist/drug_allocations/#{drug_allocation.id}"}>
                  <.button
                    phx-click="trigger_payment"
                    phx-value-id={drug_allocation.id}
                    class="bg-red-500 hover:bg-red-600 py-1 px-2 text-xs"
                  >
                    Not Paid
                  </.button>
                </.link>
              <% end %>
            </div>
          </:col>

          <:col :let={drug_allocation} label="Pharmacist">
            <div class="flex items-center py-3">
              <%= if drug_allocation.pharmacist && drug_allocation.pharmacist.name do %>
                <span class="px-2 py-1 text-xs rounded-full bg-brand-50 text-brand-primary">
                  {drug_allocation.pharmacist.name}
                </span>
              <% else %>
                <span class="px-2 py-1 text-xs rounded-full bg-slate-100 text-slate-500">
                  Not Assigned
                </span>
              <% end %>
            </div>
          </:col>

          <:col :let={drug_allocation} label="Amount Paid">
            <div class="flex items-center py-3">
              <span class="font-medium text-slate-900">
                KSh {drug_allocation.total_amount_paid || 0}
              </span>
            </div>
          </:col>

          <:col :let={drug_allocation} label="Prompted by Pharmacist">
            <div class="flex items-center py-3">
              <%= if drug_allocation.if_prompted_by_pharmacist do %>
                <span class="px-2 py-1 text-xs rounded-full bg-amber-100 text-amber-800">Yes</span>
              <% else %>
                <span class="px-2 py-1 text-xs rounded-full bg-slate-100 text-slate-600">No</span>
              <% end %>
            </div>
          </:col>

          <:col :let={drug_allocation} label="Actions">
            <div
              id={"actions-#{drug_allocation.id}"}
              class="flex items-center justify-center gap-2 py-3"
            >
              <.link
                navigate={"/pharmacist/drug_allocations/#{drug_allocation.id}"}
                class="flex items-center text-brand-accent hover:text-brand-primary"
              >
                <.icon name="hero-eye" class="h-4 w-4" />
              </.link>
              <%= if (drug_allocation.total_amount_paid || 0) == 0 do %>
                <button
                  phx-click="delete"
                  phx-value-id={drug_allocation.id}
                  data-confirm-message="Are you sure you want to delete this drug allocation?"
                  class="text-red-600 hover:text-red-800"
                >
                  <.icon name="hero-trash" class="h-4 w-4" />
                </button>
              <% end %>
            </div>
          </:col>
        </.data_table>
        <.pagination
          page={@page}
          total_pages={@total_pages}
          total_count={@total_count}
          per_page={@per_page}
        />
      <% end %>

      <.modal
        :if={@live_action in [:new, :edit]}
        id="drug_allocation-modal"
        show
        on_cancel={JS.patch(~p"/pharmacist/#{@patient.id}/drug_allocations")}
      >
        <.live_component
          module={MedcampWeb.PharmacistsLive.DrugAllocationFormComponent}
          id={@drug_allocation.id || :new}
          title={@page_title}
          action={@live_action}
          patient={@patient}
          patients={@patients}
          current_user={@current_user}
          drug_allocation={@drug_allocation}
          patch={~p"/pharmacist/#{@patient.id}/drug_allocations"}
        />
      </.modal>
    </div>
    """
  end
end
