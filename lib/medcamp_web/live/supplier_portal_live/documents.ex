defmodule MedcampWeb.SupplierPortalLive.Documents do
  @moduledoc """
  Supplier portal: company documentation uploads (CR12, incorporation, licences, etc.)
  """
  use MedcampWeb, :supplier_live_view

  alias Medcamp.Suppliers
  alias Medcamp.Suppliers.SupplierDocument

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    if is_nil(user.supplier_id) do
      {:ok,
       socket
       |> put_flash(:error, "Your account is not linked to a supplier.")
       |> push_navigate(to: ~p"/users/log_out")}
    else
      supplier = Suppliers.get_supplier!(user.supplier_id)

      {:ok,
       socket
       |> assign(:page_title, "Company Documents")
       |> assign(:active_tab, :documents)
       |> assign(:supplier, supplier)
       |> assign(:document_type, "other")
       |> allow_upload(:document,
         accept: ~w(.pdf .jpg .jpeg .png),
         max_entries: 1,
         max_file_size: 10_000_000
       )}
    end
  end

  @impl true
  def handle_event("validate", %{"document_type" => type}, socket) do
    {:noreply, assign(socket, :document_type, type)}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save-document", %{"document_type" => type} = _params, socket) do
    supplier_id = socket.assigns.supplier.id
    document_type = type

    entries = socket.assigns.uploads.document.entries

    cond do
      Enum.empty?(entries) ->
        {:noreply, put_flash(socket, :error, "Please select a file before uploading.")}

      Enum.any?(upload_errors(socket.assigns.uploads.document), & &1) ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "The selected file has errors. Please check the file type and size."
         )}

      true ->
        uploaded_files =
          consume_uploaded_entries(socket, :document, fn %{path: path}, entry ->
            ext = Path.extname(entry.client_name)

            filename =
              "supplier_#{supplier_id}_#{document_type}_#{System.unique_integer([:positive])}#{ext}"

            dest_dir =
              Path.join(Application.app_dir(:medcamp, "priv/uploads"), "supplier_documents")

            File.mkdir_p!(dest_dir)
            dest = Path.join(dest_dir, filename)
            File.cp!(path, dest)
            {:ok, %{path: "/uploads/supplier_documents/#{filename}", original: entry.client_name}}
          end)

        result =
          case uploaded_files do
            [%{path: path, original: original} | _] ->
              Suppliers.create_supplier_document(%{
                "supplier_id" => supplier_id,
                "document_type" => document_type,
                "file_path" => path,
                "original_filename" => original
              })

            _ ->
              {:error, :no_file}
          end

        case result do
          {:ok, _doc} ->
            supplier = Suppliers.get_supplier!(supplier_id)

            {:noreply,
             socket
             |> put_flash(:info, "Document uploaded successfully.")
             |> assign(:supplier, supplier)
             |> assign(:document_type, document_type)}

          {:error, :no_file} ->
            {:noreply,
             put_flash(socket, :error, "No file received. Please select a file and try again.")}

          {:error, changeset} ->
            errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
            {:noreply, put_flash(socket, :error, "Could not save document: #{inspect(errors)}")}
        end
    end
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :document, ref)}
  end

  def handle_event("delete-document", %{"id" => id}, socket) do
    doc = Suppliers.get_supplier_document!(id)
    Suppliers.delete_supplier_document(doc)
    supplier = Suppliers.get_supplier!(socket.assigns.supplier.id)

    {:noreply,
     socket
     |> put_flash(:info, "Document deleted.")
     |> assign(:supplier, supplier)}
  end

  defp document_type_label(type), do: SupplierDocument.document_type_label(type)

  defp doc_icon("pdf"), do: "document-text"
  defp doc_icon(_), do: "photo"

  defp file_ext(path) when is_binary(path),
    do: path |> Path.extname() |> String.downcase() |> String.trim_leading(".")

  defp file_ext(_), do: ""

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header class="text-[#373896] border-b border-gray-100 pb-4">
        <div class="flex items-center gap-2">
          <Heroicons.icon name="folder-open" type="outline" class="h-6 w-6 text-[#6667ab]" />
          Company Documents
        </div>
        <:subtitle>
          Upload and manage your company's official documentation. All files are stored securely.
        </:subtitle>
      </.header>

      <%!-- Upload form --%>
      <div class="bg-white border border-gray-200 rounded-xl p-6 shadow-sm">
        <h3 class="text-base font-semibold text-[#373896] mb-4">Upload a Document</h3>
        <form phx-submit="save-document" phx-change="validate">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Document Type</label>
              <select
                name="document_type"
                class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-[#6667ab] focus:border-[#6667ab] outline-none"
              >
                <option value="cr12">CR12</option>
                <option value="letter_of_incorporation">Letter of Incorporation</option>
                <option value="license_certificate">License Certificate</option>
                <option value="other" selected>Other</option>
              </select>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                File (PDF, JPG, PNG — max 10 MB)
              </label>
              <.live_file_input
                upload={@uploads.document}
                class="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-medium file:bg-[#e7e7ff] file:text-[#373896] hover:file:bg-[#d2d3ff]"
              />
            </div>
          </div>

          <%= for entry <- @uploads.document.entries do %>
            <div class="flex items-center gap-3 p-3 bg-slate-50 rounded-lg mb-3">
              <Heroicons.icon name="paper-clip" type="outline" class="h-4 w-4 text-gray-400" />
              <span class="text-sm text-gray-700 flex-1 truncate">{entry.client_name}</span>
              <span class="text-xs text-gray-500">
                {Float.round(entry.client_size / 1_048_576, 2)} MB
              </span>
              <button
                type="button"
                phx-click="cancel-upload"
                phx-value-ref={entry.ref}
                class="text-rose-500 hover:text-rose-700"
              >
                <Heroicons.icon name="x-mark" type="outline" class="h-4 w-4" />
              </button>
            </div>
            <%= for err <- upload_errors(@uploads.document, entry) do %>
              <p class="text-rose-600 text-xs mt-1">{err}</p>
            <% end %>
          <% end %>

          <.button type="submit" class="bg-[#373896] hover:bg-[#6667ab]">
            <Heroicons.icon name="arrow-up-tray" type="outline" class="h-4 w-4 mr-2" />
            Upload Document
          </.button>
        </form>
      </div>

      <%!-- Documents table --%>
      <div class="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
          <h3 class="text-base font-semibold text-[#373896]">Uploaded Documents</h3>
          <span class="text-sm text-gray-500">{length(@supplier.supplier_documents)} file(s)</span>
        </div>

        <%= if Enum.empty?(@supplier.supplier_documents) do %>
          <div class="flex flex-col items-center justify-center py-16 text-center">
            <Heroicons.icon name="folder-open" type="outline" class="h-12 w-12 text-gray-300 mb-3" />
            <p class="text-gray-500 font-medium">No documents uploaded yet</p>
            <p class="text-gray-400 text-sm mt-1">
              Use the form above to upload your company documents.
            </p>
          </div>
        <% else %>
          <div class="overflow-x-auto">
            <table class="w-full min-w-[700px]">
              <thead class="border-b border-slate-200 bg-slate-50/80">
                <tr>
                  <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                    File
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Type
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Uploaded
                  </th>
                  <th class="px-6 py-4 text-right text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 bg-white">
                <tr
                  :for={doc <- @supplier.supplier_documents}
                  class="group transition-colors hover:bg-slate-50/50"
                >
                  <td class="px-6 py-3 text-sm">
                    <div class="flex items-center gap-3">
                      <div class="h-8 w-8 rounded-lg bg-[#e7e7ff] flex items-center justify-center flex-shrink-0">
                        <Heroicons.icon
                          name={doc_icon(file_ext(doc.file_path))}
                          type="outline"
                          class="h-4 w-4 text-[#373896]"
                        />
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 truncate max-w-[260px]">
                          {doc.original_filename || "Document"}
                        </p>
                        <p class="text-xs text-gray-400 uppercase">{file_ext(doc.file_path)}</p>
                      </div>
                    </div>
                  </td>
                  <td class="px-6 py-3 text-sm">
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-[#e7e7ff] text-[#373896]">
                      {document_type_label(doc.document_type)}
                    </span>
                  </td>
                  <td class="px-6 py-3 text-sm text-gray-500">
                    {Calendar.strftime(doc.inserted_at, "%d %b %Y")}
                  </td>
                  <td class="px-6 py-3 text-sm text-right">
                    <div class="flex items-center justify-end gap-3">
                      <a
                        href={doc.file_path}
                        target="_blank"
                        class="text-[#6667ab] hover:text-[#373896] font-medium"
                      >
                        View
                      </a>
                      <button
                        phx-click="delete-document"
                        phx-value-id={doc.id}
                        data-confirm="Delete this document?"
                        class="text-rose-500 hover:text-rose-700 font-medium"
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
