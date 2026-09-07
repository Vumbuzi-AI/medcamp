defmodule MedcampWeb.Supplier.RegistrationLive do
  use MedcampWeb, :supplier_live_view

  import MedcampWeb.ProcurementComponents,
    only: [status_badge: 1, registration_stepper: 1, document_slot: 1, portal_form_shell: 1]

  alias Medcamp.Procurement.SupplierDirector
  alias Medcamp.Procurement.Suppliers
  alias Medcamp.Suppliers.SupplierDocument
  alias MedcampWeb.Options
  alias MedcampWeb.Supplier.LiveHelpers

  @document_uploads [:registration_cert, :pin_cert, :trade_licence, :cr12]
  @required_review_checks ~w(details_confirmed policies_acknowledged terms_accepted)

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> allow_upload(:director_id_document,
        accept: ~w(.pdf .jpg .jpeg .png),
        max_entries: 1,
        max_file_size: 5_000_000
      )
      |> allow_upload(:registration_cert,
        accept: ~w(.pdf),
        max_entries: 1,
        max_file_size: 10_000_000,
        auto_upload: true
      )
      |> allow_upload(:pin_cert,
        accept: ~w(.pdf),
        max_entries: 1,
        max_file_size: 10_000_000,
        auto_upload: true
      )
      |> allow_upload(:trade_licence,
        accept: ~w(.pdf),
        max_entries: 1,
        max_file_size: 10_000_000,
        auto_upload: true
      )
      |> allow_upload(:cr12,
        accept: ~w(.pdf),
        max_entries: 1,
        max_file_size: 10_000_000,
        auto_upload: true
      )
      |> assign(:country_options, Options.country_options())
      |> assign(:product_category_options, Options.supplier_product_category_options())

    case LiveHelpers.load_supplier(socket.assigns.current_user, create?: true) do
      {:ok, supplier, user} ->
        {:ok,
         socket
         |> LiveHelpers.maybe_assign_current_user(user)
         |> assign(:page_title, "Supplier Registration")
         |> assign(:documents_error, nil)
         |> assign(:review_checks, %{})
         |> assign_registration(supplier, :company)}

      {:error, :missing_supplier} ->
        {:ok, push_navigate(socket, to: LiveHelpers.registration_path(:company))}
    end
  end

  @impl true
  def handle_params(%{"step" => step_param}, _uri, socket) do
    step = LiveHelpers.normalize_step(step_param)
    {:noreply, assign_registration(socket, socket.assigns.supplier.id, step)}
  end

  @impl true
  def handle_event("validate", %{"registration" => params}, socket) do
    changeset =
      LiveHelpers.step_completion_changeset(
        socket.assigns.current_step,
        step_source_data(socket.assigns.supplier, socket.assigns.current_step),
        normalize_step_params(socket.assigns.current_step, params)
      )
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :step_form, to_form(changeset, as: :registration))}
  end

  def handle_event("validate_director", %{"director" => params}, socket) do
    changeset =
      %SupplierDirector{}
      |> SupplierDirector.changeset(%{
        supplier_id: socket.assigns.supplier.id,
        first_name: Map.get(params, "first_name"),
        last_name: Map.get(params, "last_name"),
        middle_name: Map.get(params, "middle_name"),
        id_number: Map.get(params, "id_number"),
        telephone: Map.get(params, "telephone"),
        email: Map.get(params, "email")
      })
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :director_form, to_form(changeset, as: :director))}
  end

  def handle_event("validate_documents", _params, socket) do
    {:noreply, assign(socket, :documents_error, nil)}
  end

  def handle_event("save_draft", %{"registration" => params}, socket) do
    {:noreply, save_current_step(socket, params, false)}
  end

  def handle_event("save_draft", _params, socket) do
    {:noreply, save_current_step(socket, %{}, false)}
  end

  def handle_event("next", %{"registration" => params}, socket) do
    {:noreply, save_current_step(socket, params, true)}
  end

  def handle_event("next", _params, socket) do
    {:noreply, save_current_step(socket, %{}, true)}
  end

  def handle_event("prev", _params, socket) do
    {:noreply,
     push_navigate(socket,
       to: LiveHelpers.registration_path(LiveHelpers.previous_step(socket.assigns.current_step))
     )}
  end

  def handle_event("cancel-upload", %{"ref" => ref, "upload" => upload}, socket) do
    upload_name = upload_atom(upload)
    {:noreply, cancel_upload(socket, upload_name, ref)}
  end

  def handle_event("add_director", %{"director" => params}, socket) do
    uploaded =
      LiveHelpers.store_uploads(
        socket,
        :director_id_document,
        "supplier_directors",
        "director_#{socket.assigns.supplier.id}"
      )

    attrs =
      params
      |> Map.put("supplier_id", socket.assigns.supplier.id)
      |> maybe_put_director_document(uploaded)

    case Suppliers.upsert_director(attrs) do
      {:ok, _director} ->
        supplier = Suppliers.get_supplier!(socket.assigns.supplier.id)

        {:noreply,
         socket
         |> put_flash(:info, "Director saved to this supplier profile.")
         |> assign_registration(supplier, :directors)}

      {:error, changeset} ->
        {:noreply,
         assign(socket, :director_form, to_form(%{changeset | action: :validate}, as: :director))}
    end
  end

  def handle_event("remove_director", %{"id" => id}, socket) do
    case Enum.find(socket.assigns.supplier.directors, &(to_string(&1.id) == id)) do
      nil ->
        {:noreply, socket}

      director ->
        {:ok, _deleted} = Suppliers.delete_director(director)
        {:noreply, assign_registration(socket, socket.assigns.supplier.id, :directors)}
    end
  end

  def handle_event("submit_registration", %{"review" => review}, socket) do
    if Enum.all?(@required_review_checks, &(Map.get(review, &1) in ["true", "on"])) do
      case Suppliers.submit_registration(socket.assigns.supplier) do
        {:ok, supplier} ->
          {:noreply,
           socket
           |> assign_registration(supplier, :review)
           |> put_flash(
             :info,
             "Registration submitted successfully. Procurement has been notified."
           )
           |> push_navigate(to: ~p"/supplier/dashboard")}

        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "We could not submit the registration right now.")}
      end
    else
      {:noreply,
       socket
       |> assign(:review_checks, review)
       |> put_flash(:error, "Please confirm all declarations before submitting the registration.")}
    end
  end

  def handle_event("submit_registration", _params, socket) do
    {:noreply,
     put_flash(
       socket,
       :error,
       "Please confirm all declarations before submitting the registration."
     )}
  end

  defp save_current_step(socket, params, advance?) do
    case persist_step(socket, socket.assigns.current_step, params, advance?) do
      {:ok, supplier} ->
        step =
          if advance?,
            do: LiveHelpers.next_step(socket.assigns.current_step),
            else: socket.assigns.current_step

        socket =
          socket
          |> put_flash(:info, if(advance?, do: "Step saved.", else: "Draft saved."))
          |> assign_registration(supplier, step)

        if advance? do
          push_navigate(socket, to: LiveHelpers.registration_path(step))
        else
          socket
        end

      {:error, :documents_incomplete} ->
        socket
        |> assign(:documents_error, "Upload the required procurement documents before moving on.")
        |> put_flash(:error, "Some required supplier documents are still missing.")

      {:error, :director_required} ->
        put_flash(socket, :error, "Add at least one director before moving to the next step.")

      {:error, changeset} ->
        assign(socket, :step_form, to_form(%{changeset | action: :validate}, as: :registration))
    end
  end

  defp persist_step(socket, step, params, advance?) do
    case step do
      :company ->
        persist_supplier_step(socket.assigns.supplier, step, params, advance?)

      :address ->
        persist_supplier_step(socket.assigns.supplier, step, params, advance?)

      :contact ->
        persist_supplier_step(socket.assigns.supplier, step, params, advance?)

      :bank ->
        persist_supplier_step(socket.assigns.supplier, step, params, advance?)

      :directors ->
        if advance? and Enum.empty?(socket.assigns.supplier.directors),
          do: {:error, :director_required},
          else: {:ok, Suppliers.get_supplier!(socket.assigns.supplier.id)}

      :documents ->
        with {:ok, supplier} <- persist_documents(socket) do
          if advance? and not Suppliers.documents_complete?(supplier) do
            {:error, :documents_incomplete}
          else
            {:ok, supplier}
          end
        end

      :review ->
        {:ok, Suppliers.get_supplier!(socket.assigns.supplier.id)}
    end
  end

  defp persist_supplier_step(supplier, step, params, advance?) do
    attrs = normalize_step_params(step, params)

    if advance? do
      changeset =
        LiveHelpers.step_completion_changeset(step, step_source_data(supplier, step), attrs)

      if changeset.valid? do
        Suppliers.update_registration(supplier, attrs)
      else
        {:error, changeset}
      end
    else
      Suppliers.update_registration(supplier, attrs)
    end
  end

  defp persist_documents(socket) do
    Enum.each(@document_uploads, fn upload ->
      if LiveHelpers.upload_entries_have_errors?(socket, upload) do
        throw({:upload_error, upload})
      end
    end)

    supplier_id = socket.assigns.supplier.id

    try do
      Enum.each(@document_uploads, fn upload ->
        files =
          LiveHelpers.store_uploads(
            socket,
            upload,
            "supplier_documents",
            "#{upload}_#{supplier_id}"
          )

        Enum.each(files, fn file ->
          Suppliers.upsert_document(%{
            supplier_id: supplier_id,
            document_type: Atom.to_string(upload),
            file_path: file.path,
            original_filename: file.client_name,
            file_name: file.client_name,
            file_size: file.size
          })
        end)
      end)

      {:ok, Suppliers.get_supplier!(supplier_id)}
    catch
      {:upload_error, _upload} -> {:ok, Suppliers.get_supplier!(supplier_id)}
    end
  end

  defp assign_registration(socket, supplier_or_id, step) do
    supplier =
      case supplier_or_id do
        %{id: id} -> Suppliers.get_supplier!(id)
        id -> Suppliers.get_supplier!(id)
      end

    progress = LiveHelpers.registration_progress(supplier)
    current_step = LiveHelpers.normalize_step(step)

    socket
    |> assign(:supplier, supplier)
    |> assign(:current_step, current_step)
    |> assign(:progress, progress)
    |> assign(:document_uploads, @document_uploads)
    |> assign(:document_map, LiveHelpers.supplier_document_map(supplier))
    |> assign(:step_form, build_step_form(supplier, current_step))
    |> assign(:director_form, build_director_form(supplier.id))
    |> assign(:documents_error, nil)
  end

  defp build_step_form(supplier, step) do
    data = step_source_data(supplier, step)
    attrs = default_step_params(supplier, step)

    step
    |> LiveHelpers.step_completion_changeset(data, attrs)
    |> to_form(as: :registration)
  end

  defp build_director_form(supplier_id) do
    %SupplierDirector{}
    |> SupplierDirector.changeset(%{supplier_id: supplier_id})
    |> to_form(as: :director)
  end

  defp step_source_data(supplier, _step) do
    %{
      name: supplier.name,
      legal_name: supplier.legal_name,
      nature_of_business: supplier.nature_of_business,
      years_in_operation: supplier.years_in_operation,
      country: supplier.country,
      description: supplier.description,
      product_categories: supplier.product_categories,
      street_address: supplier.street_address,
      city: supplier.city,
      county: supplier.county,
      po_box: supplier.po_box,
      location: supplier.location,
      contact_first_name: supplier.contact_first_name,
      contact_last_name: supplier.contact_last_name,
      contact_designation: supplier.contact_designation,
      contact_email: supplier.contact_email,
      contact_telephone: supplier.contact_telephone,
      alternate_contact_name: supplier.alternate_contact_name,
      alternate_contact_email: supplier.alternate_contact_email,
      alternate_contact_telephone: supplier.alternate_contact_telephone,
      email: supplier.email,
      contact: supplier.contact,
      account_name: supplier.account_name,
      account_number: supplier.account_number,
      bank_name: supplier.bank_name,
      bank_branch: supplier.bank_branch,
      swift_code: supplier.swift_code,
      currency: supplier.currency,
      payment_terms: supplier.payment_terms,
      kra_pin: supplier.kra_pin
    }
  end

  defp default_step_params(supplier, :company) do
    %{
      "name" => supplier.name || supplier.legal_name,
      "legal_name" => supplier.legal_name,
      "nature_of_business" => supplier.nature_of_business,
      "years_in_operation" => to_string_or_empty(supplier.years_in_operation),
      "product_categories" => supplier.product_categories || []
    }
  end

  defp default_step_params(supplier, :address) do
    %{
      "country" => supplier.country,
      "street_address" => supplier.street_address,
      "city" => supplier.city,
      "county" => supplier.county,
      "po_box" => supplier.po_box
    }
  end

  defp default_step_params(supplier, :contact) do
    %{
      "contact_first_name" => supplier.contact_first_name,
      "contact_last_name" => supplier.contact_last_name,
      "contact_designation" => supplier.contact_designation,
      "contact_email" => supplier.contact_email || supplier.email,
      "contact_telephone" => supplier.contact_telephone || supplier.contact,
      "alternate_contact_name" => supplier.alternate_contact_name,
      "alternate_contact_email" => supplier.alternate_contact_email,
      "alternate_contact_telephone" => supplier.alternate_contact_telephone,
      "email" => supplier.email,
      "contact" => supplier.contact
    }
  end

  defp default_step_params(supplier, :bank) do
    %{
      "account_name" => supplier.account_name,
      "account_number" => supplier.account_number,
      "bank_name" => supplier.bank_name,
      "bank_branch" => supplier.bank_branch,
      "swift_code" => supplier.swift_code,
      "currency" => supplier.currency || "KES",
      "payment_terms" => supplier.payment_terms || "",
      "kra_pin" => supplier.kra_pin
    }
  end

  defp default_step_params(_supplier, _step), do: %{}

  defp normalize_step_params(:company, params) do
    %{
      name: Map.get(params, "name") || Map.get(params, "legal_name"),
      legal_name: Map.get(params, "legal_name"),
      nature_of_business: Map.get(params, "nature_of_business"),
      years_in_operation: blank_to_nil(Map.get(params, "years_in_operation")),
      product_categories: LiveHelpers.csv_to_list(Map.get(params, "product_categories"))
    }
    |> LiveHelpers.prune_blank_values()
  end

  defp normalize_step_params(:address, params) do
    %{
      country: Map.get(params, "country"),
      street_address: Map.get(params, "street_address"),
      city: Map.get(params, "city"),
      county: Map.get(params, "county"),
      po_box: Map.get(params, "po_box"),
      location: Map.get(params, "city")
    }
    |> LiveHelpers.prune_blank_values()
  end

  defp normalize_step_params(:contact, params) do
    %{
      contact_first_name: Map.get(params, "contact_first_name"),
      contact_last_name: Map.get(params, "contact_last_name"),
      contact_designation: Map.get(params, "contact_designation"),
      contact_email: Map.get(params, "contact_email"),
      contact_telephone: Map.get(params, "contact_telephone"),
      alternate_contact_name: Map.get(params, "alternate_contact_name"),
      alternate_contact_email: Map.get(params, "alternate_contact_email"),
      alternate_contact_telephone: Map.get(params, "alternate_contact_telephone"),
      email: Map.get(params, "contact_email") || Map.get(params, "email"),
      contact: Map.get(params, "contact_telephone") || Map.get(params, "contact")
    }
    |> LiveHelpers.prune_blank_values()
  end

  defp normalize_step_params(:bank, params) do
    %{
      account_name: Map.get(params, "account_name"),
      account_number: Map.get(params, "account_number"),
      bank_name: Map.get(params, "bank_name"),
      bank_branch: Map.get(params, "bank_branch"),
      swift_code: Map.get(params, "swift_code"),
      currency: Map.get(params, "currency"),
      payment_terms: Map.get(params, "payment_terms"),
      kra_pin: Map.get(params, "kra_pin")
    }
    |> LiveHelpers.prune_blank_values()
  end

  defp normalize_step_params(_step, _params), do: %{}

  defp maybe_put_director_document(attrs, [%{path: path} | _]),
    do: Map.put(attrs, "id_document_path", path)

  defp maybe_put_director_document(attrs, _files), do: attrs

  defp upload_atom("director_id_document"), do: :director_id_document
  defp upload_atom("registration_cert"), do: :registration_cert
  defp upload_atom("pin_cert"), do: :pin_cert
  defp upload_atom("trade_licence"), do: :trade_licence
  defp upload_atom("cr12"), do: :cr12
  defp upload_atom(_), do: :director_id_document

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(value) when is_binary(value) and value == "", do: nil
  defp blank_to_nil(value), do: value

  defp to_string_or_empty(nil), do: ""
  defp to_string_or_empty(value), do: to_string(value)

  defp review_checked?(checks, key), do: Map.get(checks, key) in ["true", "on"]

  defp document_label(type), do: SupplierDocument.document_type_label(Atom.to_string(type))

  @impl true
  def render(assigns) do
    ~H"""
    <.portal_form_shell
      eyebrow="Registration Wizard"
      title="Supplier onboarding"
      subtitle="Complete the seven-step registration flow, save progress as a draft, and submit once everything is ready."
      cancel_path={~p"/supplier/profile"}
      max_width="max-w-6xl"
    >
      <:actions>
        <.status_badge status={@supplier.status} />
      </:actions>

      <div class="space-y-6">
        <.registration_stepper current={@current_step} progress={@progress} />

        <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
          <%= case @current_step do %>
            <% :company -> %>
              <.simple_form for={@step_form} phx-change="validate" phx-submit="next">
                <div class="grid gap-4 md:grid-cols-2">
                  <.input field={@step_form[:legal_name]} label="Legal name" />
                  <.input field={@step_form[:name]} label="Display name" />
                  <.input field={@step_form[:nature_of_business]} label="Nature of business" />
                  <.input
                    field={@step_form[:years_in_operation]}
                    type="number"
                    label="Years in operation"
                  />
                  <.input
                    field={@step_form[:product_categories]}
                    label="Product categories"
                    type="select"
                    multiple
                    options={@product_category_options}
                    size="8"
                  />
                </div>
                <:actions>
                  <button
                    type="button"
                    phx-click="save_draft"
                    class="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700"
                  >
                    Save draft
                  </button>
                  <.button class="bg-[#373896] hover:bg-[#2d2d7a]">Save and continue</.button>
                </:actions>
              </.simple_form>
            <% :address -> %>
              <.simple_form for={@step_form} phx-change="validate" phx-submit="next">
                <div class="grid gap-4 md:grid-cols-2">
                  <.input
                    field={@step_form[:street_address]}
                    label="Physical address"
                    placeholder="Street address, floor, building"
                  />
                  <.input field={@step_form[:city]} label="City" />
                  <.input
                    field={@step_form[:country]}
                    label="Country"
                    type="select"
                    options={@country_options}
                    prompt="Select a country"
                  />
                  <.input field={@step_form[:county]} label="County / state" />
                  <.input field={@step_form[:po_box]} label="PO Box" />
                </div>
                <:actions>
                  <button
                    type="button"
                    phx-click="prev"
                    class="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700"
                  >
                    Back
                  </button>
                  <button
                    type="button"
                    phx-click="save_draft"
                    class="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700"
                  >
                    Save draft
                  </button>
                  <.button class="bg-[#373896] hover:bg-[#2d2d7a]">Save and continue</.button>
                </:actions>
              </.simple_form>
            <% :directors -> %>
              <div class="space-y-6">
                <div class="rounded-2xl bg-slate-50 p-5">
                  <h2 class="text-lg font-semibold text-slate-900">Add a director</h2>
                  <.simple_form
                    for={@director_form}
                    phx-change="validate_director"
                    phx-submit="add_director"
                  >
                    <div class="grid  p-2 gap-4 md:grid-cols-2">
                      <.input field={@director_form[:first_name]} label="First name" />
                      <.input field={@director_form[:last_name]} label="Last name" />
                      <.input field={@director_form[:middle_name]} label="Middle name" />
                      <.input field={@director_form[:id_number]} label="ID number" />
                      <.input field={@director_form[:telephone]} label="Telephone" />
                      <.input field={@director_form[:email]} label="Email" />
                    </div>
                    <div class="space-y-2 p-2">
                      <label class="text-sm font-medium text-slate-700">Director ID document</label>
                      <.live_file_input
                        upload={@uploads.director_id_document}
                        class="block w-full rounded-xl border border-slate-200 bg-white px-3 py-3 text-sm text-slate-600"
                      />
                      <div
                        :for={entry <- @uploads.director_id_document.entries}
                        class="flex items-center justify-between rounded-xl bg-white px-3 py-2 text-sm text-slate-600"
                      >
                        <span>{entry.client_name}</span>
                        <button
                          type="button"
                          phx-click="cancel-upload"
                          phx-value-upload="director_id_document"
                          phx-value-ref={entry.ref}
                          class="font-semibold text-rose-600"
                        >
                          Remove
                        </button>
                      </div>
                    </div>

                    <:actions>
                      <div class="p-2">
                        <.button class="bg-[#373896] hover:bg-[#2d2d7a]">Add director</.button>
                      </div>
                    </:actions>
                  </.simple_form>
                </div>

                <div class="space-y-3">
                  <div
                    :for={director <- @supplier.directors}
                    class="rounded-2xl border border-slate-200 px-4 py-4"
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
                      <button
                        type="button"
                        phx-click="remove_director"
                        phx-value-id={director.id}
                        class="text-sm font-semibold text-rose-600"
                      >
                        Remove
                      </button>
                    </div>
                  </div>

                  <div
                    :if={Enum.empty?(@supplier.directors)}
                    class="rounded-2xl border border-dashed border-slate-200 px-4 py-6 text-sm text-slate-500"
                  >
                    Add at least one director to move to the next step.
                  </div>
                </div>

                <div class="flex flex-wrap gap-3">
                  <button
                    type="button"
                    phx-click="prev"
                    class="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700"
                  >
                    Back
                  </button>
                  <button
                    type="button"
                    phx-click="save_draft"
                    class="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700"
                  >
                    Save draft
                  </button>
                  <button
                    type="button"
                    phx-click="next"
                    class="rounded-xl bg-[#373896] px-4 py-2.5 text-sm font-semibold text-white"
                  >
                    Continue
                  </button>
                </div>
              </div>
            <% :contact -> %>
              <.simple_form for={@step_form} phx-change="validate" phx-submit="next">
                <div class="space-y-6">
                  <div class="grid gap-4 md:grid-cols-2">
                    <.input field={@step_form[:contact_first_name]} label="Contact first name" />
                    <.input field={@step_form[:contact_last_name]} label="Contact last name" />
                    <.input field={@step_form[:contact_designation]} label="Designation" />
                    <.input field={@step_form[:contact_email]} label="Contact email" />
                    <.input field={@step_form[:contact_telephone]} label="Contact telephone" />
                  </div>

                  <div class="rounded-2xl bg-slate-50 p-5">
                    <p class="text-sm font-semibold text-slate-900">Alternate contact (optional)</p>
                    <div class="mt-4 grid gap-4 md:grid-cols-2">
                      <.input
                        field={@step_form[:alternate_contact_name]}
                        label="Alternate contact name"
                      />
                      <.input
                        field={@step_form[:alternate_contact_telephone]}
                        label="Alternate contact telephone"
                      />
                      <.input
                        field={@step_form[:alternate_contact_email]}
                        label="Alternate contact email"
                      />
                    </div>
                  </div>
                </div>
                <:actions>
                  <button
                    type="button"
                    phx-click="prev"
                    class="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700"
                  >
                    Back
                  </button>
                  <button
                    type="button"
                    phx-click="save_draft"
                    class="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700"
                  >
                    Save draft
                  </button>
                  <.button class="bg-[#373896] hover:bg-[#2d2d7a]">Save and continue</.button>
                </:actions>
              </.simple_form>
            <% :bank -> %>
              <.simple_form for={@step_form} phx-change="validate" phx-submit="next">
                <div class="grid gap-4 md:grid-cols-2">
                  <.input field={@step_form[:account_name]} label="Account name" />
                  <.input field={@step_form[:account_number]} label="Account number" />
                  <.input field={@step_form[:bank_name]} label="Bank name" />
                  <.input field={@step_form[:bank_branch]} label="Bank branch" />
                  <.input field={@step_form[:swift_code]} label="SWIFT code" />
                  <.input field={@step_form[:currency]} label="Currency" />
                  <.input field={@step_form[:payment_terms]} label="Payment terms" />
                  <.input field={@step_form[:kra_pin]} label="KRA PIN" />
                </div>
                <:actions>
                  <button
                    type="button"
                    phx-click="prev"
                    class="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700"
                  >
                    Back
                  </button>
                  <button
                    type="button"
                    phx-click="save_draft"
                    class="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700"
                  >
                    Save draft
                  </button>
                  <.button class="bg-[#373896] hover:bg-[#2d2d7a]">Save and continue</.button>
                </:actions>
              </.simple_form>
            <% :documents -> %>
              <form phx-change="validate_documents" class="space-y-5">
                <div
                  :if={@documents_error}
                  class="rounded-2xl border border-rose-200 bg-rose-50 px-4 py-4 text-sm text-rose-700"
                >
                  {@documents_error}
                </div>

                <div class="grid gap-4 md:grid-cols-2">
                  <div :for={upload <- @document_uploads}>
                    <p class="mb-2 text-sm font-semibold text-slate-700">{document_label(upload)}</p>
                    <.document_slot
                      type={Atom.to_string(upload)}
                      document={@document_map[Atom.to_string(upload)]}
                      upload_ref={@uploads[upload]}
                    />
                    <div class="mt-3 rounded-2xl border border-slate-200 bg-white px-4 py-4">
                      <.live_file_input
                        upload={@uploads[upload]}
                        class="block w-full text-sm text-slate-600"
                      />
                      <div
                        :for={entry <- @uploads[upload].entries}
                        class="mt-3 flex items-center justify-between rounded-xl bg-slate-50 px-3 py-2 text-sm text-slate-600"
                      >
                        <span>{entry.client_name}</span>
                        <button
                          type="button"
                          phx-click="cancel-upload"
                          phx-value-upload={upload}
                          phx-value-ref={entry.ref}
                          class="font-semibold text-rose-600"
                        >
                          Remove
                        </button>
                      </div>
                    </div>
                  </div>
                </div>

                <div class="flex flex-wrap gap-3">
                  <button
                    type="button"
                    phx-click="prev"
                    class="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700"
                  >
                    Back
                  </button>
                  <button
                    type="button"
                    phx-click="save_draft"
                    class="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700"
                  >
                    Save draft
                  </button>
                  <button
                    type="button"
                    phx-click="next"
                    class="rounded-xl bg-[#373896] px-4 py-2.5 text-sm font-semibold text-white"
                  >
                    Save and continue
                  </button>
                </div>
              </form>
            <% :review -> %>
              <div class="space-y-6">
                <div class="grid gap-6 xl:grid-cols-2">
                  <div class="rounded-2xl bg-slate-50 p-5">
                    <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                      Company
                    </p>
                    <p class="mt-2 text-lg font-semibold text-slate-900">
                      {@supplier.legal_name || "Not provided"}
                    </p>
                    <p class="mt-2 text-sm text-slate-600">
                      {@supplier.nature_of_business || "No business type yet"}
                    </p>
                    <p class="mt-2 text-sm text-slate-500">
                      {LiveHelpers.maybe_join_list(@supplier.product_categories)}
                    </p>
                  </div>

                  <div class="rounded-2xl bg-slate-50 p-5">
                    <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                      Contact
                    </p>
                    <p class="mt-2 text-lg font-semibold text-slate-900">
                      {Enum.join(
                        Enum.reject(
                          [@supplier.contact_first_name, @supplier.contact_last_name],
                          &LiveHelpers.blank?/1
                        ),
                        " "
                      )}
                    </p>
                    <p
                      :if={!LiveHelpers.blank?(@supplier.contact_designation)}
                      class="mt-2 text-sm text-slate-600"
                    >
                      {@supplier.contact_designation}
                    </p>
                    <p class="mt-2 text-sm text-slate-600">{@supplier.contact_email}</p>
                    <p class="mt-2 text-sm text-slate-500">{@supplier.contact_telephone}</p>

                    <div
                      :if={
                        !LiveHelpers.blank?(@supplier.alternate_contact_name) or
                          !LiveHelpers.blank?(@supplier.alternate_contact_email) or
                          !LiveHelpers.blank?(@supplier.alternate_contact_telephone)
                      }
                      class="mt-4 rounded-xl border border-slate-200 bg-white/70 px-4 py-3"
                    >
                      <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                        Alternate contact
                      </p>
                      <p class="mt-2 text-sm font-semibold text-slate-900">
                        {@supplier.alternate_contact_name}
                      </p>
                      <p
                        :if={!LiveHelpers.blank?(@supplier.alternate_contact_email)}
                        class="mt-1 text-sm text-slate-600"
                      >
                        {@supplier.alternate_contact_email}
                      </p>
                      <p
                        :if={!LiveHelpers.blank?(@supplier.alternate_contact_telephone)}
                        class="mt-1 text-sm text-slate-500"
                      >
                        {@supplier.alternate_contact_telephone}
                      </p>
                    </div>
                  </div>
                </div>

                <div class="grid gap-4 md:grid-cols-3">
                  <MedcampWeb.ProcurementComponents.stat_card
                    label="Directors"
                    value={length(@supplier.directors)}
                    sub="Directors added to the profile"
                  />
                  <MedcampWeb.ProcurementComponents.stat_card
                    label="Documents"
                    value={map_size(@document_map)}
                    sub="Uploaded company documents"
                  />
                </div>

                <form
                  phx-submit="submit_registration"
                  class="space-y-4 rounded-2xl border border-slate-200 bg-slate-50 p-5"
                >
                  <label class="flex items-start gap-3 text-sm text-slate-700">
                    <input
                      type="checkbox"
                      name="review[details_confirmed]"
                      checked={review_checked?(@review_checks, "details_confirmed")}
                      class="mt-1 rounded border-slate-300 text-[#373896] focus:ring-[#373896]"
                    />
                    <span>
                      I confirm that the supplier details shared in this registration are accurate.
                    </span>
                  </label>
                  <label class="flex items-start gap-3 text-sm text-slate-700">
                    <input
                      type="checkbox"
                      name="review[policies_acknowledged]"
                      checked={review_checked?(@review_checks, "policies_acknowledged")}
                      class="mt-1 rounded border-slate-300 text-[#373896] focus:ring-[#373896]"
                    />
                    <span>
                      I acknowledge that procurement may request more information before approval.
                    </span>
                  </label>
                  <label class="flex items-start gap-3 text-sm text-slate-700">
                    <input
                      type="checkbox"
                      name="review[terms_accepted]"
                      checked={review_checked?(@review_checks, "terms_accepted")}
                      class="mt-1 rounded border-slate-300 text-[#373896] focus:ring-[#373896]"
                    />
                    <span>I agree to the supplier onboarding declaration and review terms.</span>
                  </label>

                  <div class="flex flex-wrap gap-3">
                    <button
                      type="button"
                      phx-click="prev"
                      class="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700"
                    >
                      Back
                    </button>
                    <button
                      type="button"
                      phx-click="save_draft"
                      class="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700"
                    >
                      Save draft
                    </button>
                    <.button class="bg-[#373896] hover:bg-[#2d2d7a]">Submit registration</.button>
                  </div>
                </form>
              </div>
          <% end %>
        </div>
      </div>
    </.portal_form_shell>
    """
  end
end
