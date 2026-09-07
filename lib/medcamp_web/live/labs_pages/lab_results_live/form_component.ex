defmodule MedcampWeb.LabPagesLabResultLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.LabResults

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Fill in the lab result details
      </.header>

      <.simple_form
        for={@form}
        id="lab_result-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.live_file_input upload={@uploads.lab_report} />

        <section phx-drop-target={@uploads.lab_report.ref}>
          <article :for={entry <- @uploads.lab_report.entries} class="upload-entry">
            <figure>
              <.live_img_preview :if={entry.client_type != "application/pdf"} entry={entry} />
              <figcaption>{entry.client_name}</figcaption>
            </figure>

            <progress value={entry.progress} max="100">{entry.progress}%</progress>

            <button
              type="button"
              phx-click="cancel-upload"
              phx-value-ref={entry.ref}
              phx-target={@myself}
              aria-label="cancel"
            >
              &times;
            </button>

            <p :for={err <- upload_errors(@uploads.lab_report, entry)} class="alert alert-danger">
              {error_to_string(err)}
            </p>
          </article>

          <p :for={err <- upload_errors(@uploads.lab_report)} class="alert alert-danger">
            {error_to_string(err)}
          </p>
        </section>

        <.input field={@form[:test_findings]} required type="textarea" label="Test findings" />
        <.input
          field={@form[:sample_collection_description]}
          type="textarea"
          required
          label="Sample collection description"
        />
        <div class="grid grid-cols-2 w-[100%] gap-4">
          <.input
            field={@form[:sample_collection_date]}
            required
            type="date"
            label="Sample collection Date"
          />
          <.input required field={@form[:date_of_test]} type="date" label="Date of test" />
        </div>
        <.input required field={@form[:time]} type="time" label="Time test was requested" />
        <:actions>
          <.button phx-disable-with="Saving...">Complete And Submit Lab Report</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{lab_result: lab_result} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:uploaded_files, [])
     |> allow_upload(:lab_report, accept: ~w(.pdf), max_entries: 5)
     |> assign_new(:form, fn ->
       to_form(LabResults.change_lab_result(lab_result))
     end)}
  end

  @impl true
  def handle_event("validate", %{"lab_result" => lab_result_params}, socket) do
    changeset = LabResults.change_lab_result(socket.assigns.lab_result, lab_result_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"lab_result" => lab_result_params}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :lab_report, fn %{path: path}, entry ->
        original_name = entry.client_name
        # Remove spaces from the base name
        base_name =
          Path.rootname(Path.basename(original_name))
          |> String.replace(" ", "_")

        new_filename = "#{base_name}-#{:rand.uniform(1_000_000)}.pdf"

        dest = Path.join(Application.app_dir(:medcamp, "priv/uploads"), new_filename)
        File.cp!(path, dest)
        {:ok, %{size: file_size}} = File.stat(path)
        original_filename = entry.client_name

        {:ok,
         %{
           path: ~p"/uploads/#{Path.basename(dest)}",
           size: file_size,
           filename: original_filename
         }}
      end)

    IO.inspect(uploaded_files, label: "Uploaded files")

    lab_report = uploaded_files |> Enum.map(& &1.path) |> Enum.join(",")

    lab_result_params =
      lab_result_params
      |> Map.put("lab_report", lab_report)
      |> Map.put("lab_technician_id", socket.assigns.current_user.id)
      |> Map.put("report_complete", true)

    case LabResults.update_lab_result(socket.assigns.lab_result, lab_result_params) do
      {:ok, _lab_result} ->
        {:noreply,
         socket
         |> put_flash(:info, "Lab result updated successfully")
         |> push_navigate(to: ~p"/lab/lab_results/#{socket.assigns.lab_result.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :lab_report, ref)}
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
end
