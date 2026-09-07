defmodule MedcampWeb.RadiologistPages.RadiologyResultLive.Show do
  use MedcampWeb, :radiologist_live_view

  alias Medcamp.RadiologyResults

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:uploaded_files, [])
     |> allow_upload(:radiology_report, accept: ~w(.jpg .jpeg .png .pdf), max_entries: 1)
     |> assign(:active_tab, :radiology_results)}
  end

  @impl true

  def handle_params(%{"id" => id}, _, socket) do
    radiology_result = RadiologyResults.get_radiology_result!(id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:radiology_result, radiology_result)
     |> assign_new(:form, fn ->
       to_form(RadiologyResults.change_radiology_result(radiology_result))
     end)}
  end

  @impl true
  def handle_event("validate", %{"radiology_result" => radiology_result_params}, socket) do
    changeset =
      RadiologyResults.change_radiology_result(
        socket.assigns.radiology_result,
        radiology_result_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"radiology_result" => radiology_result_params}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :radiology_report, fn %{path: path}, _entry ->
        dest = Path.join([:code.priv_dir(:medcamp), "uploads", Path.basename(path)])

        File.cp!(path, dest)
        {:ok, ~p"/uploads/#{Path.basename(dest)}"}
      end)

    radiology_report = List.first(uploaded_files)

    radiology_result_params =
      radiology_result_params
      |> Map.put("radiology_report", radiology_report)
      |> Map.put("report_complete", true)
      |> Map.put("radiologist_id", socket.assigns.current_user.id)

    case RadiologyResults.update_radiology_result(
           socket.assigns.radiology_result,
           radiology_result_params
         ) do
      {:ok, _radiology_result} ->
        {:noreply,
         socket
         |> put_flash(:info, "Radiology result updated successfully")
         |> push_navigate(
           to: ~p"/radiologist/radiology_results/#{socket.assigns.radiology_result.id}"
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :radiology_report, ref)}
  end

  defp page_title(:show), do: "Show Radiology result"
  defp page_title(:edit), do: "Edit Radiology result"

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
end
