defmodule MedcampWeb.AddPatientComponent do
  use MedcampWeb, :live_component

  alias Medcamp.Patients
  alias Medcamp.Patients.Patient
  alias Medcamp.Uploads.Validator

  @impl true
  def render(%{step: "find"} = assigns) do
    ~H"""
    <div>
      <.header>Add a patient</.header>

      <.no_active_camp_warning active_camp={@active_camp} />

      <p class="mt-1 text-sm text-slate-500">
        Enter the patient's National ID to look them up.
      </p>

      <form phx-submit="lookup" phx-target={@myself} class="mt-6 space-y-4">
        <.input
          type="text"
          name="national_id"
          value={@lookup_id}
          label="National ID"
          autocomplete="off"
          phx-mounted={JS.focus()}
        />
        <div class="flex flex-wrap items-center gap-4">
          <.button phx-disable-with="Checking...">Continue</.button>
          <button
            type="button"
            phx-click="register_new"
            phx-target={@myself}
            class="text-sm font-semibold text-brand-primary hover:underline"
          >
            Patient has no ID
          </button>
        </div>
      </form>
    </div>
    """
  end

  def render(%{step: "confirm"} = assigns) do
    ~H"""
    <div>
      <.header>Patient found</.header>

      <.no_active_camp_warning active_camp={@active_camp} />

      <div class="mt-5 rounded-xl border border-slate-200 bg-slate-50 p-4">
        <p class="text-lg font-semibold text-slate-900">{full_name(@matched_patient)}</p>
        <p
          :if={@matched_patient.date_of_birth || @matched_patient.phone_number}
          class="mt-1 text-sm text-slate-600"
        >
          <span :if={@matched_patient.date_of_birth}>Born {@matched_patient.date_of_birth}</span>
          <span :if={@matched_patient.date_of_birth && @matched_patient.phone_number}>·</span>
          <span :if={@matched_patient.phone_number}>{@matched_patient.phone_number}</span>
        </p>
        <p class="mt-2 flex items-center gap-2 text-xs">
          <span class="font-semibold uppercase tracking-wide text-slate-400">GSRN</span>
          <span class="font-mono text-slate-700">{@matched_patient.gsrn}</span>
        </p>
      </div>

      <div
        :if={@existing_visit}
        class="mt-4 rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-800"
      >
        Already registered for this camp <span class="font-medium">
          (visit #{@existing_visit.id}, {Medcamp.PatientVisits.PatientVisit.status_label(
            @existing_visit.status
          )})
        </span>.
      </div>

      <div class="mt-6 flex flex-wrap items-center gap-3">
        <button
          type="button"
          phx-click="back_to_find"
          phx-target={@myself}
          class="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
        >
          Not them
        </button>
        <.link
          :if={@existing_visit && @show_path}
          navigate={@show_path.(@matched_patient)}
          class="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
        >
          Open patient
        </.link>
        <.button phx-click="register_visit" phx-target={@myself} phx-disable-with="Creating...">
          {if @existing_visit, do: "Register another visit", else: "Register visit"}
        </.button>
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Add A New Patient
      </.header>

      <.no_active_camp_warning active_camp={@active_camp} />

      <button
        type="button"
        phx-click="back_to_find"
        phx-target={@myself}
        class="mt-2 inline-flex items-center gap-1 text-sm font-medium text-slate-500 hover:text-slate-700"
      >
        &larr; Back to lookup
      </button>

      <.simple_form
        for={@form}
        id="patient-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div
          :if={@duplicate_match}
          class="rounded-xl border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800"
        >
          A patient with this National ID is already on file: <span class="font-semibold">{full_name(@duplicate_match)}</span>.
          <button
            type="button"
            phx-click="open_duplicate"
            phx-target={@myself}
            class="font-semibold underline"
          >
            Open their record
          </button>
        </div>

        <div class="w-full space-y-8">
          <section class="space-y-4">
            <.form_section_heading>Patient details</.form_section_heading>
            <div class="grid grid-cols-1 gap-4 md:grid-cols-2 [&>*]:min-w-0">
              <.input
                field={@form[:first_name]}
                type="text"
                label="First Name"
                phx-debounce="blur"
                required
              />
              <.input field={@form[:middle_name]} type="text" label="Middle Name" />
              <.input field={@form[:last_name]} type="text" label="Last Name" phx-debounce="blur" />
              <.input
                field={@form[:date_of_birth]}
                type="date"
                label="Date of birth"
                max={Date.to_iso8601(Date.utc_today())}
                required
              />
              <.input
                field={@form[:gender]}
                type="select"
                label="Gender"
                prompt="Select Gender"
                options={["Male", "Female", "Others"]}
                required
              />
              <.input
                :if={@lookup_id not in [nil, ""] or @action == :edit}
                field={@form[:national_id]}
                type="text"
                label="National ID"
              />
            </div>
          </section>

          <section class="space-y-4 border-t border-slate-200 pt-7">
            <.form_section_heading>Contact</.form_section_heading>
            <div class="grid grid-cols-1 gap-4 md:grid-cols-2 [&>*]:min-w-0">
              <.input
                field={@form[:phone_number]}
                type="text"
                label="Phone number"
                phx-debounce="blur"
                required
              />
              <.input field={@form[:email]} type="text" label="Email" phx-debounce="blur" />
              <.input
                field={@form[:home_address]}
                type="text"
                label="Residence"
                phx-debounce="blur"
                required
              />
            </div>
          </section>

          <section class="space-y-4 border-t border-slate-200 pt-7">
            <.form_section_heading note="optional">Emergency contact</.form_section_heading>
            <div class="grid grid-cols-1 gap-4 md:grid-cols-2 [&>*]:min-w-0">
              <.input
                field={@form[:emergency_contact_name]}
                type="text"
                label="Name"
                phx-debounce="blur"
              />
              <.input
                field={@form[:emergency_contact_phone_number]}
                type="text"
                label="Phone number"
                phx-debounce="blur"
              />
              <.input
                field={@form[:emergency_contact_relationship]}
                type="select"
                label="Relationship"
                prompt="Select Relationship"
                options={[
                  "Mother",
                  "Father",
                  "Spouse",
                  "Child",
                  "Sibling",
                  "Grandparent",
                  "Guardian",
                  "Friend",
                  "Other"
                ]}
              />
            </div>
          </section>

          <section class="space-y-4 border-t border-slate-200 pt-7">
            <.form_section_heading note="optional">Documents</.form_section_heading>
            <div class="grid grid-cols-1 gap-4 md:grid-cols-2 [&>*]:min-w-0">
              <.document_upload_field
                label="National ID Document"
                existing_document={@patient.national_id_document}
                upload={@uploads.national_id_document}
                upload_key="national_id_document"
                myself={@myself}
              />
              <.document_upload_field
                label="Birth Certificate Document"
                existing_document={@patient.birth_certificate_document}
                upload={@uploads.birth_certificate_document}
                upload_key="birth_certificate_document"
                myself={@myself}
              />
            </div>
          </section>
        </div>

        <p :if={@upload_error} class="text-sm text-rose-600">{@upload_error}</p>

        <:actions>
          <.button phx-disable-with="Saving...">
            Save Patient
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  attr :active_camp, :any, required: true

  defp no_active_camp_warning(assigns) do
    ~H"""
    <div
      :if={is_nil(@active_camp)}
      class="mb-5 flex items-start gap-2 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800"
    >
      <.icon name="hero-exclamation-triangle" class="mt-0.5 h-4 w-4 shrink-0" />
      <span>
        No camp is active. Patients registered now won't be attributed to any camp.
        Activate one on <span class="font-semibold">Camps</span> first.
      </span>
    </div>
    """
  end

  defp safe_active_camp do
    Medcamp.Camps.get_active_camp()
  rescue
    _ -> nil
  end

  # A plain form subheading - deliberately not an uppercase/tracked eyebrow.
  attr :note, :string, default: nil, doc: ~s(a muted suffix, e.g. "optional")
  slot :inner_block, required: true

  defp form_section_heading(assigns) do
    ~H"""
    <h3 class="text-sm font-semibold text-slate-900">
      {render_slot(@inner_block)}
      <span :if={@note} class="ml-1 font-normal text-slate-400">({@note})</span>
    </h3>
    """
  end

  attr :label, :string, required: true
  attr :existing_document, :string, default: nil
  attr :upload, Phoenix.LiveView.UploadConfig, required: true
  attr :upload_key, :string, required: true
  attr :myself, :any, required: true

  defp document_upload_field(assigns) do
    ~H"""
    <div class="min-w-0">
      <label class="block text-sm font-medium leading-6 text-zinc-800">{@label}</label>
      <div :if={@existing_document} class="mt-1">
        <a
          href={@existing_document}
          download={@label <> Path.extname(@existing_document)}
          target="_blank"
          class="text-sm text-blue-600 hover:text-blue-800"
        >
          View current document
        </a>
      </div>
      <.live_file_input
        upload={@upload}
        class="mt-1 block w-full max-w-full text-sm text-slate-600 file:mr-3 file:rounded-md file:border-0 file:bg-slate-100 file:px-3 file:py-2 file:text-sm file:font-medium file:text-slate-700 hover:file:bg-slate-200"
      />
      <p class="mt-1 text-xs text-slate-400">JPG, PNG or PDF, up to 8MB.</p>
      <div :for={entry <- @upload.entries} class="mt-1 flex items-center gap-2 text-sm text-slate-600">
        <span class="truncate">{entry.client_name}</span>
        <progress value={entry.progress} max="100" class="max-w-full">{entry.progress}%</progress>
        <button
          type="button"
          phx-click="cancel-upload"
          phx-value-ref={entry.ref}
          phx-value-upload={@upload_key}
          phx-target={@myself}
          aria-label="cancel"
          class="text-rose-600"
        >
          &times;
        </button>
      </div>
      <p
        :for={{entry, err} <- entry_errors(@upload)}
        class="mt-1 flex items-center gap-2 text-sm text-rose-600"
      >
        {upload_error_to_string(err)}
        <button
          type="button"
          phx-click="cancel-upload"
          phx-value-ref={entry.ref}
          phx-value-upload={@upload_key}
          phx-target={@myself}
          aria-label="remove"
          class="text-rose-600 underline"
        >
          Remove
        </button>
      </p>
      <p :for={err <- upload_errors(@upload)} class="mt-1 text-sm text-rose-600">
        {upload_error_to_string(err)}
      </p>
    </div>
    """
  end

  defp entry_errors(upload) do
    for entry <- upload.entries, err <- upload_errors(upload, entry), do: {entry, err}
  end

  defp upload_error_to_string(:too_large), do: "File is too large"
  defp upload_error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp upload_error_to_string(:too_many_files), do: "You have selected too many files"
  defp upload_error_to_string(:external_client_failure), do: "The upload failed, please try again"
  defp upload_error_to_string(_other), do: "This file could not be uploaded"

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> allow_upload(:national_id_document,
       accept: ~w(.jpg .jpeg .png .pdf),
       max_entries: 1,
       max_file_size: 8_000_000,
       auto_upload: true
     )
     |> allow_upload(:birth_certificate_document,
       accept: ~w(.jpg .jpeg .png .pdf),
       max_entries: 1,
       max_file_size: 8_000_000,
       auto_upload: true
     )}
  end

  @impl true
  def update(%{patient: patient} = assigns, socket) do
    # New patients enter through the "find" lookup step; edits go straight to
    # the form. `step="personal"` from older callers is treated as "find".
    step =
      cond do
        assigns[:action] == :edit -> "register"
        assigns[:step] in [nil, "personal", "find"] -> "find"
        true -> assigns[:step]
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:step, step)
     |> assign(:active_camp, safe_active_camp())
     |> assign(:form, to_form(Patients.change_patient(patient)))
     |> assign_new(:lookup_id, fn -> nil end)
     |> assign_new(:matched_patient, fn -> nil end)
     |> assign_new(:existing_visit, fn -> nil end)
     |> assign_new(:duplicate_match, fn -> nil end)
     |> assign_new(:upload_error, fn -> nil end)
     |> assign_new(:show_path, fn -> nil end)
     |> assign_new(:notify_parent_on_save, fn -> false end)}
  end

  # After a successful registration or visit, either hand control back to the
  # parent LiveView (so it can show a wristband/print screen) or navigate on.
  defp after_registration(socket, patient, flash_message) do
    if socket.assigns.notify_parent_on_save do
      send(self(), {:patient_registered, patient})
      {:noreply, socket}
    else
      {:noreply,
       socket
       |> put_flash(:info, flash_message)
       |> push_navigate(to: destination(socket, patient))}
    end
  end

  @impl true
  def handle_event("lookup", %{"national_id" => national_id}, socket) do
    case Patients.find_by_national_id(national_id) do
      nil ->
        changeset =
          Patients.change_patient(%Patient{}, %{"national_id" => String.trim(national_id)})

        {:noreply,
         socket
         |> assign(step: "register", lookup_id: String.trim(national_id))
         |> assign(:form, to_form(changeset))}

      %Patient{} = found ->
        {:noreply,
         socket
         |> assign(
           step: "confirm",
           matched_patient: found,
           existing_visit: Medcamp.PatientVisits.current_visit_for_patient(found.id)
         )}
    end
  end

  def handle_event("register_new", _params, socket) do
    {:noreply,
     socket
     |> assign(step: "register", lookup_id: nil, duplicate_match: nil)
     |> assign(:form, to_form(Patients.change_patient(%Patient{})))}
  end

  def handle_event("back_to_find", _params, socket) do
    {:noreply,
     assign(socket,
       step: "find",
       matched_patient: nil,
       existing_visit: nil,
       duplicate_match: nil
     )}
  end

  def handle_event("open_duplicate", _params, socket) do
    patient = socket.assigns.duplicate_match

    {:noreply,
     assign(socket,
       step: "confirm",
       matched_patient: patient,
       existing_visit: patient && Medcamp.PatientVisits.current_visit_for_patient(patient.id),
       duplicate_match: nil
     )}
  end

  def handle_event("register_visit", _params, socket) do
    case Patients.register_visit_for_existing(
           socket.assigns.matched_patient,
           socket.assigns.current_user
         ) do
      {:ok, {patient, _visit}} ->
        after_registration(socket, patient, "Visit created for #{full_name(patient)}")

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not create the visit. Try again.")}
    end
  end

  def handle_event("validate", %{"patient" => patient_params}, socket) do
    changeset = Patients.change_patient(socket.assigns.patient, patient_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("switch_tab", %{"step" => step}, socket) do
    {:noreply,
     socket
     |> assign(:step, step)}
  end

  def handle_event("save", %{"patient" => patient_params}, socket) do
    duplicate =
      socket.assigns.action == :new &&
        Patients.find_by_national_id(patient_params["national_id"] || "")

    cond do
      match?(%Patient{}, duplicate) ->
        {:noreply, assign(socket, :duplicate_match, duplicate)}

      (errors = pending_upload_errors(socket)) != [] ->
        {:noreply, assign(socket, :upload_error, Enum.join(errors, "; "))}

      true ->
        patient_params =
          patient_params
          |> Map.put("creator_id", socket.assigns.current_user.id)
          |> merge_uploaded_document(socket, :national_id_document)
          |> merge_uploaded_document(socket, :birth_certificate_document)

        save_patient(socket, socket.assigns.action, patient_params)
    end
  end

  def handle_event("cancel-upload", %{"ref" => ref, "upload" => upload}, socket) do
    key = normalize_upload_key(upload)

    {:noreply,
     socket
     |> maybe_cancel_upload(key, ref)
     |> assign(:upload_error, nil)}
  end

  defp pending_upload_errors(socket) do
    uploads = Map.get(socket.assigns, :uploads, %{})

    for key <- [:national_id_document, :birth_certificate_document],
        conf = Map.get(uploads, key),
        is_map(conf),
        entry <- conf.entries,
        not (entry.valid? and entry.done?) do
      label = upload_key_label(key)

      case upload_errors(conf, entry) do
        [err | _] -> "#{label}: #{upload_error_to_string(err)}"
        [] -> "#{label} is still uploading, please wait"
      end
    end
  end

  defp upload_key_label(:national_id_document), do: "National ID Document"
  defp upload_key_label(:birth_certificate_document), do: "Birth Certificate Document"

  defp normalize_upload_key("national_id_document"), do: :national_id_document
  defp normalize_upload_key("birth_certificate_document"), do: :birth_certificate_document
  defp normalize_upload_key(_other), do: nil

  defp maybe_cancel_upload(socket, nil, _ref), do: socket
  defp maybe_cancel_upload(socket, key, ref), do: cancel_upload(socket, key, ref)

  defp merge_uploaded_document(patient_params, socket, key) do
    uploaded_paths =
      consume_uploaded_entries(socket, key, fn %{path: path}, entry ->
        uploads_dir =
          Path.join([to_string(:code.priv_dir(:medcamp)), "static", "uploads", "patients"])

        document_subdir = document_type_slug(key)
        scoped_uploads_dir = Path.join(uploads_dir, document_subdir)

        with :ok <- File.mkdir_p(scoped_uploads_dir),
             :ok <- Validator.validate_upload(entry, path),
             filename = structured_upload_filename(key, entry),
             dest = Path.join(scoped_uploads_dir, filename),
             :ok <- File.cp(path, dest) do
          {:ok, "/uploads/patients/#{document_subdir}/#{filename}"}
        else
          {:error, _reason} -> {:postpone, nil}
        end
      end)

    case uploaded_paths do
      [{:ok, uploaded_path} | _] when is_binary(uploaded_path) ->
        Map.put(patient_params, Atom.to_string(key), uploaded_path)

      [uploaded_path | _] when is_binary(uploaded_path) ->
        Map.put(patient_params, Atom.to_string(key), uploaded_path)

      _ ->
        patient_params
    end
  end

  defp structured_upload_filename(key, entry) do
    ext = safe_extension(entry)
    prefix = document_type_slug(key)
    timestamp = Calendar.strftime(DateTime.utc_now(), "%Y%m%dT%H%M%SZ")
    random = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)

    "#{prefix}-#{timestamp}-#{random}#{ext}"
  end

  defp safe_extension(%{client_type: "application/pdf"}), do: ".pdf"
  defp safe_extension(%{client_type: "image/png"}), do: ".png"
  defp safe_extension(%{client_type: "image/jpeg"}), do: ".jpeg"

  defp safe_extension(%{client_name: name}) when is_binary(name) do
    ext = name |> Path.extname() |> String.downcase()
    if ext in ~w(.pdf .png .jpg .jpeg), do: ext, else: ".bin"
  end

  defp safe_extension(_), do: ".bin"

  defp document_type_slug(:national_id_document), do: "national-id"
  defp document_type_slug(:birth_certificate_document), do: "birth-certificate"

  defp save_patient(socket, :edit, patient_params) do
    old_patient = socket.assigns.patient

    case Patients.update_patient(old_patient, patient_params) do
      {:ok, updated_patient} ->
        delete_replaced_document(
          old_patient.national_id_document,
          patient_params["national_id_document"]
        )

        delete_replaced_document(
          old_patient.birth_certificate_document,
          patient_params["birth_certificate_document"]
        )

        destination =
          if socket.assigns.show_path, do: socket.assigns.show_path.(updated_patient), else: nil

        {:noreply,
         socket
         |> put_flash(:info, "Patient updated successfully")
         |> push_navigate(to: destination || socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_patient(socket, :new, patient_params) do
    # Registering someone opens their camp visit in the same transaction, so
    # they land in the triage queue without anyone opening a second form.
    case Patients.register_for_camp(patient_params, socket.assigns.current_user) do
      {:ok, {patient, _visit}} ->
        after_registration(socket, patient, "Patient registered and sent to triage")

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp destination(socket, patient) do
    (socket.assigns.show_path && socket.assigns.show_path.(patient)) || socket.assigns.patch
  end

  defp full_name(patient) do
    [patient.first_name, patient.middle_name, patient.last_name]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" ")
    |> case do
      "" -> "this patient"
      name -> name
    end
  end

  defp delete_replaced_document(old_path, new_path)
       when is_binary(old_path) and is_binary(new_path) and old_path != new_path do
    relative_path = String.trim_leading(old_path, "/uploads/")

    full_path =
      Path.join([to_string(:code.priv_dir(:medcamp)), "static", "uploads", relative_path])

    File.rm(full_path)
    :ok
  end

  defp delete_replaced_document(_old_path, _new_path), do: :ok
end
