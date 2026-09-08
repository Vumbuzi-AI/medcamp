defmodule MedcampWeb.EditPatientComponent do
  use MedcampWeb, :live_component

  alias Medcamp.Patients
  alias Medcamp.Uploads.Validator

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header>
        Edit Patient
        <:subtitle>
          Update the patient's personal information and documents.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="edit-patient-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
          <.input field={@form[:first_name]} type="text" label="First Name" />
          <.input field={@form[:middle_name]} type="text" label="Middle Name" />

          <.input field={@form[:last_name]} type="text" label="Last Name" />
          <.input field={@form[:email]} type="email" label="Email" />

          <.input field={@form[:phone_number]} type="text" label="Phone Number" />
          <.input field={@form[:date_of_birth]} type="date" label="Date of Birth" />

          <.input
            field={@form[:gender]}
            type="select"
            label="Gender"
            prompt="Select Gender"
            options={["Male", "Female", "Others"]}
          />

          <.input field={@form[:national_id]} type="text" label="National ID Number" />

          <.input field={@form[:home_address]} type="text" label="Residence" />

          <.input field={@form[:emergency_contact_name]} type="text" label="Emergency Contact Name" />

          <.input
            field={@form[:emergency_contact_phone_number]}
            type="text"
            label="Emergency Contact Phone Number"
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
        
    <!-- Documents -->

        <div class="mt-8 rounded-lg border p-6">
          <h3 class="mb-6 text-lg font-semibold">
            Patient Documents
          </h3>

          <div class="flex flex-col gap-6">
            
    <!-- Birth Certificate -->
            <div class="space-y-3">
              <label class="font-medium">
                Birth Certificate
              </label>

              <%= if @birth_certificate do %>
                <div class="rounded border border-green-200 bg-green-50 p-3 text-sm">
                  <p class="font-medium text-green-800">
                    Current Document
                  </p>

                  <p class="text-gray-700">
                    {@birth_certificate.document_name}
                  </p>

                  <a
                    href={~p"/patients/#{@patient.id}/documents/birth_certificate"}
                    target="_blank"
                    class="text-blue-600 hover:underline"
                  >
                    View Current Document
                  </a>
                </div>
              <% end %>

              <label class="text-sm text-gray-500">
                Upload new file to replace the current one
              </label>

              <.live_file_input upload={@uploads.birth_certificate} />

              <div :for={entry <- @uploads.birth_certificate.entries} class="rounded border p-2">
                <div class="flex justify-between text-sm">
                  <span>{entry.client_name}</span>
                  <span>{entry.progress}%</span>
                </div>

                <progress class="mt-2 w-full" value={entry.progress} max="100" />
              </div>

              <p :for={err <- upload_errors(@uploads.birth_certificate)} class="text-sm text-red-600">
                {error_to_string(err)}
              </p>
            </div>
            
    <!-- National ID -->
            <div class="space-y-3">
              <label class="font-medium">
                National ID
              </label>

              <%= if @national_id_document do %>
                <div class="rounded border border-green-200 bg-green-50 p-3 text-sm">
                  <p class="font-medium text-green-800">
                    Current Document
                  </p>

                  <p class="text-gray-700">
                    {@national_id_document.document_name}
                  </p>

                  <a
                    <a
                    href={~p"/patients/#{@patient.id}/documents/national_id"}
                    target="_blank"
                    class="text-blue-600 hover:underline"
                  >
                    View Current Document
                  </a>
                </div>
              <% end %>

              <label class="text-sm text-gray-500">
                Upload new file to replace the current one
              </label>

              <.live_file_input upload={@uploads.national_id} />

              <div :for={entry <- @uploads.national_id.entries} class="rounded border p-2">
                <div class="flex justify-between text-sm">
                  <span>{entry.client_name}</span>
                  <span>{entry.progress}%</span>
                </div>

                <progress class="mt-2 w-full" value={entry.progress} max="100" />
              </div>

              <p :for={err <- upload_errors(@uploads.national_id)} class="text-sm text-red-600">
                {error_to_string(err)}
              </p>
            </div>
          </div>
        </div>

        <:actions>
          <.button phx-disable-with="Updating...">
            Update Patient
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{patient: patient} = assigns, socket) do
    patient =
      Patients.get_patient!(patient.id)
      |> Medcamp.Repo.preload(:documents)

    birth_certificate =
      Enum.find(
        patient.documents,
        &(&1.document_type == :birth_certificate)
      )

    national_id_document =
      Enum.find(
        patient.documents,
        &(&1.document_type == :national_id)
      )

    socket =
      socket
      |> assign(assigns)
      |> assign(:patient, patient)
      |> assign(:birth_certificate, birth_certificate)
      |> assign(:national_id_document, national_id_document)
      |> assign(:form, to_form(Patients.change_patient(patient)))
      |> allow_upload(
        :birth_certificate,
        accept: ~w(.pdf .jpg .jpeg .png),
        max_entries: 1,
        max_file_size: 5_000_000
      )
      |> allow_upload(
        :national_id,
        accept: ~w(.pdf .jpg .jpeg .png),
        max_entries: 1,
        max_file_size: 5_000_000
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"patient" => patient_params}, socket) do
    changeset = Patients.change_patient(socket.assigns.patient, patient_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"patient" => patient_params}, socket) do
    save_patient(socket, patient_params)
  end

  defp save_patient(socket, patient_params) do
    case Patients.update_patient(socket.assigns.patient, patient_params) do
      {:ok, patient} ->
        patient =
          Patients.get_patient!(patient.id)
          |> Medcamp.Repo.preload(:documents)

        upload_errors = save_uploaded_documents(socket, patient)

        updated_patient =
          Patients.get_patient!(patient.id)
          |> Medcamp.Repo.preload(:documents)

        send(self(), {:patient_updated, updated_patient})

        socket =
          socket
          |> put_flash(:info, "Patient updated successfully")
          |> maybe_flash_upload_errors(upload_errors)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_uploaded_documents(socket, patient) do
    birth_cert_results =
      if uploaded?(socket, :birth_certificate) do
        save_document(socket, patient, :birth_certificate, :birth_certificate)
      else
        []
      end

    national_id_results =
      if uploaded?(socket, :national_id) do
        save_document(socket, patient, :national_id, :national_id)
      else
        []
      end

    (birth_cert_results ++ national_id_results)
    |> Enum.filter(&match?({:error, _}, &1))
  end

  defp maybe_flash_upload_errors(socket, []), do: socket

  defp maybe_flash_upload_errors(socket, _errors) do
    put_flash(
      socket,
      :error,
      "Patient was updated, but one or more documents failed to upload. Please try again."
    )
  end

  defp save_document(socket, patient, upload_name, document_type) do
    consume_uploaded_entries(socket, upload_name, fn %{path: path}, entry ->
      upload_dir =
        Path.join([
          File.cwd!(),
          "priv/uploads/patients"
        ])

      with :ok <- File.mkdir_p(upload_dir),
           :ok <- Validator.validate_upload(entry, path) do
        filename = "#{Ecto.UUID.generate()}#{Path.extname(entry.client_name)}"
        destination = Path.join(upload_dir, filename)

        case File.cp(path, destination) do
          :ok ->
            attrs = %{
              patient_id: patient.id,
              document_name: entry.client_name,
              document_type: document_type,
              file_path: filename,
              content_type: entry.client_type
            }

            save_or_replace_document(patient, attrs, destination)

          {:error, reason} ->
            {:error, reason}
        end
      else
        {:error, reason} ->
          {:error, reason}
      end
    end)
  end

  defp save_or_replace_document(patient, attrs, destination) do
    case Patients.get_patient_document(patient.id, attrs.document_type) do
      nil ->
        case Patients.create_patient_document(attrs) do
          {:ok, document} ->
            {:ok, document}

          {:error, changeset} ->
            File.rm(destination)
            {:error, {:database_error, changeset}}
        end

      existing ->
        case Patients.update_patient_document(existing, attrs) do
          {:ok, document} ->
            old_file = Path.join(File.cwd!(), "priv/static#{existing.file_path}")

            if File.exists?(old_file) do
              _ = File.rm(old_file)
            end

            {:ok, document}

          {:error, changeset} ->
            File.rm(destination)
            {:error, {:database_error, changeset}}
        end
    end
  end

  defp uploaded?(socket, upload) do
    socket.assigns.uploads[upload].entries != []
  end

  defp error_to_string(:too_large), do: "File is too large (maximum 5 MB)."
  defp error_to_string(:too_many_files), do: "Only one file is allowed."
  defp error_to_string(:not_accepted), do: "Only PDF, JPG, JPEG, and PNG files are allowed."
  defp error_to_string(error), do: inspect(error)
end
