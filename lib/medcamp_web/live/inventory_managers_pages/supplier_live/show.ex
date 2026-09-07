defmodule MedcampWeb.SupplierLive.Show do
  use MedcampWeb, :inventory_manager_live_view

  alias Medcamp.Suppliers
  alias Medcamp.Suppliers.SupplierDocument

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :suppliers)
     |> assign(:uploaded_files, [])
     |> allow_upload(:document, accept: ~w(.pdf .jpg .jpeg .png), max_entries: 1)}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    supplier = Suppliers.get_supplier!(id)

    {:noreply,
     socket
     |> assign(:page_title, supplier.name)
     |> assign(:supplier, supplier)
     |> assign(
       :inventories_received,
       Suppliers.list_inventories_received_for_supplier(supplier.id)
     )
     |> assign(:batches, Suppliers.list_batches_for_supplier(supplier.id))
     |> assign(:drugs, Suppliers.list_drugs_for_supplier(supplier))
     |> assign(:nursing_allocations, Suppliers.list_nursing_allocations_for_supplier(supplier.id))
     |> assign(:lab_allocations, Suppliers.list_lab_allocations_for_supplier(supplier.id))
     |> assign(:total_remaining, Suppliers.total_remaining_quantity_for_supplier(supplier.id))
     |> assign(:document_type, "other")}
  end

  @impl true
  def handle_event("save-document", params, socket) do
    supplier_id = socket.assigns.supplier.id
    document_type = params["type"] || socket.assigns.document_type

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
         |> put_flash(:info, "Document uploaded successfully")
         |> assign(:supplier, supplier)}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to save document")}
    end
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :document, ref)}
  end

  def handle_event("set-document-type", %{"type" => type}, socket) do
    {:noreply, assign(socket, :document_type, type)}
  end

  def handle_event("delete-document", %{"id" => id}, socket) do
    doc = Suppliers.get_supplier_document!(id)
    Suppliers.delete_supplier_document(doc)
    supplier = Suppliers.get_supplier!(socket.assigns.supplier.id)

    {:noreply,
     socket
     |> put_flash(:info, "Document deleted")
     |> assign(:supplier, supplier)}
  end

  def document_type_label(type), do: SupplierDocument.document_type_label(type)
end
