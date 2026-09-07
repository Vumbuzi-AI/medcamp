defmodule MedcampWeb.Supplier.ProfileLive do
  use MedcampWeb, :supplier_live_view

  import MedcampWeb.ProcurementComponents,
    only: [status_badge: 1, registration_stepper: 1, document_slot: 1]

  alias Medcamp.Procurement.Suppliers
  alias Medcamp.Suppliers.SupplierDocument
  alias MedcampWeb.Supplier.LiveHelpers

  @impl true
  def mount(_params, _session, socket) do
    case LiveHelpers.load_supplier(socket.assigns.current_user, create?: true) do
      {:ok, supplier, user} ->
        {:ok,
         socket
         |> LiveHelpers.maybe_assign_current_user(user)
         |> assign(:page_title, "Supplier Profile")
         |> assign_profile(supplier)}

      {:error, :missing_supplier} ->
        {:ok, push_navigate(socket, to: LiveHelpers.registration_path(:company))}
    end
  end

  @impl true
  def handle_info({_event, _payload}, socket) do
    {:noreply, assign_profile(socket, socket.assigns.supplier.id)}
  end

  defp assign_profile(socket, supplier_or_id) do
    supplier =
      case supplier_or_id do
        %{id: id} -> Suppliers.get_supplier!(id)
        id -> Suppliers.get_supplier!(id)
      end

    socket
    |> assign(:supplier, supplier)
    |> assign(:document_map, LiveHelpers.supplier_document_map(supplier))
    |> assign(:progress, LiveHelpers.registration_progress(supplier))
    |> assign(
      :resume_step,
      LiveHelpers.next_incomplete_step(LiveHelpers.registration_progress(supplier))
    )
  end

  defp label_for_document(type), do: SupplierDocument.document_type_label(type)
  defp required_docs, do: ~w(registration_cert pin_cert trade_licence cr12)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
        <div class="space-y-2">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Supplier profile
          </p>
          <h1 class="text-3xl font-semibold tracking-tight text-slate-900">
            {@supplier.legal_name || @supplier.name || "Supplier profile"}
          </h1>
          <p class="max-w-3xl text-sm leading-6 text-slate-500">
            Review company details, uploaded documents, and onboarding completeness from one place.
          </p>
        </div>

        <div class="flex flex-wrap gap-3">
          <.link
            navigate={LiveHelpers.registration_path(@resume_step)}
            class="rounded-xl bg-[#373896] px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-[#2d2d7a]"
          >
            Update Profile
          </.link>
          <.link
            navigate={LiveHelpers.registration_path(:review)}
            class="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50"
          >
            Review submission
          </.link>
        </div>
      </div>

      <div
        :if={@supplier.status != "approved"}
        class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm"
      >
        <div class="flex items-center justify-between gap-3">
          <div>
            <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">Progress</p>
            <h2 class="mt-2 text-xl font-semibold text-slate-900">Registration checklist</h2>
          </div>
          <.status_badge status={@supplier.status} />
        </div>

        <div class="mt-5">
          <.registration_stepper current={@resume_step} progress={@progress} />
        </div>
      </div>

      <div class="grid gap-6 xl:grid-cols-2">
        <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Company details
          </p>
          <div class="mt-5 grid gap-4 sm:grid-cols-2">
            <.profile_line label="Reference" value={@supplier.reference} />
            <.profile_line label="Business type" value={@supplier.nature_of_business} />
            <.profile_line label="Years in operation" value={@supplier.years_in_operation} />
            <.profile_line label="Country" value={@supplier.country} />
            <.profile_line
              label="Categories"
              value={LiveHelpers.maybe_join_list(@supplier.product_categories)}
            />
            <.profile_line label="KRA PIN" value={@supplier.kra_pin} />
          </div>
        </div>

        <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Contacts and address
          </p>
          <div class="mt-5 grid gap-4 sm:grid-cols-2">
            <.profile_line
              label="Contact person"
              value={
                Enum.join(
                  Enum.reject(
                    [@supplier.contact_first_name, @supplier.contact_last_name],
                    &LiveHelpers.blank?/1
                  ),
                  " "
                )
              }
            />
            <.profile_line label="Contact email" value={@supplier.contact_email} />
            <.profile_line label="Telephone" value={@supplier.contact_telephone} />
            <.profile_line label="Physical address" value={@supplier.street_address} />
            <.profile_line label="City" value={@supplier.city} />
            <.profile_line label="County" value={@supplier.county} />
            <.profile_line label="PO Box" value={@supplier.po_box} />
            <.profile_line
              label="Bank"
              value={
                Enum.join(
                  Enum.reject([@supplier.bank_name, @supplier.bank_branch], &LiveHelpers.blank?/1),
                  " / "
                )
              }
            />
          </div>
        </div>
      </div>

      <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
        <div class="flex items-center justify-between gap-3">
          <div>
            <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">Documents</p>
            <h2 class="mt-2 text-xl font-semibold text-slate-900">Uploaded company documents</h2>
          </div>
          <.link
            navigate={LiveHelpers.registration_path(:documents)}
            class="text-sm font-semibold text-[#373896] hover:text-[#2d2d7a]"
          >
            Manage documents
          </.link>
        </div>

        <div class="mt-5 grid gap-4 md:grid-cols-2">
          <div :for={type <- required_docs()}>
            <p class="mb-2 text-sm font-semibold text-slate-700">{label_for_document(type)}</p>
            <.document_slot type={type} document={@document_map[type]} />
          </div>
        </div>
      </div>

      <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
        <div class="flex items-center justify-between gap-3">
          <div>
            <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">Directors</p>
            <h2 class="mt-2 text-xl font-semibold text-slate-900">Registered directors</h2>
          </div>
          <.link
            navigate={LiveHelpers.registration_path(:directors)}
            class="text-sm font-semibold text-[#373896] hover:text-[#2d2d7a]"
          >
            Update directors
          </.link>
        </div>

        <div class="mt-5 space-y-3">
          <div
            :for={director <- @supplier.directors}
            class="rounded-2xl border border-slate-100 bg-slate-50 px-4 py-4"
          >
            <div class="flex items-start justify-between gap-3">
              <div>
                <p class="text-sm font-semibold text-slate-900">
                  {Enum.join(
                    Enum.reject(
                      [director.first_name, director.middle_name, director.last_name],
                      &LiveHelpers.blank?/1
                    ),
                    " "
                  )}
                </p>
                <p class="mt-1 text-sm text-slate-500">{director.id_number}</p>
              </div>
              <.status_badge status={
                if LiveHelpers.present?(director.id_document_path), do: :approved, else: :pending
              } />
            </div>
            <p class="mt-3 text-sm text-slate-500">
              {Enum.join(
                Enum.reject([director.telephone, director.email], &LiveHelpers.blank?/1),
                " • "
              )}
            </p>
          </div>

          <div
            :if={Enum.empty?(@supplier.directors)}
            class="rounded-2xl border border-dashed border-slate-200 px-4 py-6 text-sm text-slate-500"
          >
            No directors added yet. Add at least one director in the registration wizard.
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, default: nil

  defp profile_line(assigns) do
    ~H"""
    <div class="rounded-2xl bg-slate-50 px-4 py-3">
      <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">{@label}</p>
      <p class="mt-2 text-sm font-medium text-slate-800">
        {if LiveHelpers.blank?(@value), do: "Not provided", else: @value}
      </p>
    </div>
    """
  end
end
