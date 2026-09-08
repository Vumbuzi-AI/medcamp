defmodule MedcampWeb.AddPatientComponent do
  use MedcampWeb, :live_component

  alias Medcamp.Patients
  alias Medcamp.Uploads.Validator

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Add A New Patient
      </.header>

      <.simple_form
        for={@form}
        id="patient-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div :if={@step == "personal"} class="grid w-full grid-cols-1 gap-4 md:grid-cols-2">
          <.input
            field={@form[:first_name]}
            type="text"
            label="First Name"
            phx-debounce="blur"
            required
          />
          <.input field={@form[:middle_name]} type="text" label="Middle Name" />
          <.input field={@form[:last_name]} type="text" label="Last Name" phx-debounce="blur" />
          <.input field={@form[:email]} type="text" label="Email" phx-debounce="blur" />
          <.input
            field={@form[:phone_number]}
            type="text"
            label="Phone number"
            phx-debounce="blur"
            required
          />
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
          <.input field={@form[:national_id]} type="text" label="National ID" />

          <.input
            field={@form[:home_address]}
            type="text"
            label="Residence"
            phx-debounce="blur"
            required
          />

          <.input
            field={@form[:emergency_contact_name]}
            type="text"
            label="Emergency contact Name"
            phx-debounce="blur"
          />
          <.input
            field={@form[:emergency_contact_phone_number]}
            type="text"
            label="Emergency contact Phone Number"
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

  attr :label, :string, required: true
  attr :existing_document, :string, default: nil
  attr :upload, Phoenix.LiveView.UploadConfig, required: true
  attr :upload_key, :string, required: true
  attr :myself, :any, required: true

  defp document_upload_field(assigns) do
    ~H"""
    <div>
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
      <.live_file_input upload={@upload} class="mt-1" />
      <p class="mt-1 text-xs text-gray-400">JPG, PNG or PDF, up to 8MB.</p>
      <div :for={entry <- @upload.entries} class="mt-1 flex items-center gap-2 text-sm text-gray-600">
        <span class="truncate">{entry.client_name}</span>
        <progress value={entry.progress} max="100">{entry.progress}%</progress>
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
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(Patients.change_patient(patient)))
     |> assign_new(:upload_error, fn -> nil end)
     |> assign_new(:show_path, fn -> nil end)}
  end

  @impl true
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
    case pending_upload_errors(socket) do
      [] ->
        patient_params =
          patient_params
          |> Map.put("creator_id", socket.assigns.current_user.id)
          |> merge_uploaded_document(socket, :national_id_document)
          |> merge_uploaded_document(socket, :birth_certificate_document)

        save_patient(socket, socket.assigns.action, patient_params)

      errors ->
        {:noreply, assign(socket, :upload_error, Enum.join(errors, "; "))}
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
        destination =
          if socket.assigns.show_path, do: socket.assigns.show_path.(patient), else: nil

        {:noreply,
         socket
         |> put_flash(:info, "Patient registered and sent to triage")
         |> push_navigate(to: destination || socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
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
