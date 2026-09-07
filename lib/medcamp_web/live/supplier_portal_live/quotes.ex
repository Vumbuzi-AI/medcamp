defmodule MedcampWeb.SupplierPortalLive.Quotes do
  @moduledoc """
  Supplier portal: submit and manage quotes.
  """
  use MedcampWeb, :supplier_live_view

  alias Medcamp.Suppliers
  alias Medcamp.Suppliers.SupplierQuote

  @per_page 10

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
       |> assign(:page_title, "Quotes")
       |> assign(:active_tab, :quotes)
       |> assign(:supplier, supplier)
       |> assign(:page, 1)
       |> assign(:per_page, @per_page)
       |> load_quotes()
       |> assign(:form, nil)
       |> assign(:editing, nil)
       |> allow_upload(:quote_file,
         accept: ~w(.pdf .jpg .jpeg .png),
         max_entries: 1,
         max_file_size: 10_000_000
       )}
    end
  end

  defp load_quotes(socket) do
    all = Suppliers.list_supplier_quotes(socket.assigns.supplier.id)
    total_count = length(all)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)
    quotes = Enum.slice(all, (page - 1) * socket.assigns.per_page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:quotes, quotes)
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:form, to_form(Suppliers.change_supplier_quote(%SupplierQuote{})))
    |> assign(:editing, nil)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    quote_rec = Suppliers.get_supplier_quote!(id)

    socket
    |> assign(:form, to_form(Suppliers.change_supplier_quote(quote_rec)))
    |> assign(:editing, quote_rec)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:form, nil)
    |> assign(:editing, nil)
  end

  @impl true
  def handle_event("validate", %{"supplier_quote" => params}, socket) do
    changeset =
      case socket.assigns.editing do
        nil -> Suppliers.change_supplier_quote(%SupplierQuote{}, params)
        q -> Suppliers.change_supplier_quote(q, params)
      end

    {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"supplier_quote" => params}, socket) do
    supplier_id = socket.assigns.supplier.id

    uploaded =
      consume_uploaded_entries(socket, :quote_file, fn %{path: path}, entry ->
        ext = Path.extname(entry.client_name)
        filename = "quote_#{supplier_id}_#{System.unique_integer([:positive])}#{ext}"

        dest_dir =
          Path.join(Application.app_dir(:medcamp, "priv/uploads"), "supplier_quotes")

        File.mkdir_p!(dest_dir)
        File.cp!(path, Path.join(dest_dir, filename))
        {:ok, %{path: "/uploads/supplier_quotes/#{filename}", original: entry.client_name}}
      end)

    file_params =
      case uploaded do
        [%{path: p, original: o} | _] -> %{"file_path" => p, "original_filename" => o}
        _ -> %{}
      end

    full_params = Map.merge(params, Map.merge(file_params, %{"supplier_id" => supplier_id}))

    result =
      case socket.assigns.editing do
        nil -> Suppliers.create_supplier_quote(full_params)
        q -> Suppliers.update_supplier_quote(q, full_params)
      end

    case result do
      {:ok, _} ->
        action = if socket.assigns.editing, do: "updated", else: "submitted"

        {:noreply,
         socket
         |> put_flash(:info, "Quote #{action} successfully.")
         |> load_quotes()
         |> assign(:form, nil)
         |> assign(:editing, nil)
         |> push_patch(to: ~p"/supplier/quotes")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :quote_file, ref)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    Suppliers.delete_supplier_quote(Suppliers.get_supplier_quote!(id))

    {:noreply,
     socket
     |> put_flash(:info, "Quote deleted.")
     |> load_quotes()}
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_quotes()}
  end

  def handle_event("close-form", _params, socket) do
    {:noreply,
     socket
     |> assign(:form, nil)
     |> assign(:editing, nil)
     |> push_patch(to: ~p"/supplier/quotes")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header class="text-[#373896] border-b border-gray-100 pb-4">
        <div class="flex items-center gap-2">
          <Heroicons.icon
            name="clipboard-document-list"
            type="outline"
            class="h-6 w-6 text-[#6667ab]"
          /> Quotes
        </div>
        <:subtitle>Submit price quotes for review and approval by the facility.</:subtitle>
        <:actions>
          <.link patch={~p"/supplier/quotes/new"}>
            <.button class="bg-[#373896] hover:bg-[#6667ab] shadow-sm flex items-center gap-1.5 px-4 py-2.5 text-sm font-semibold">
              <Heroicons.icon name="plus" type="outline" class="h-4 w-4" /> New Quote
            </.button>
          </.link>
        </:actions>
      </.header>

      <%= if @form do %>
        <.modal id="quote-modal" show on_cancel={JS.push("close-form")}>
          <h2 class="text-lg font-semibold text-[#373896] mb-6">
            {if @editing, do: "Edit Quote", else: "Submit New Quote"}
          </h2>
          <.simple_form for={@form} phx-submit="save" phx-change="validate">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <.input field={@form[:quote_number]} label="Quote Number" placeholder="QT-001" />
              <.input
                field={@form[:amount]}
                label="Amount"
                type="number"
                step="0.01"
                placeholder="0.00"
              />
              <.input
                field={@form[:currency]}
                label="Currency"
                type="select"
                options={SupplierQuote.currencies()}
              />
              <.input field={@form[:quote_date]} label="Quote Date" type="date" />
              <.input field={@form[:expiry_date]} label="Expiry Date" type="date" />
              <.input
                field={@form[:status]}
                label="Status"
                type="select"
                options={Enum.map(SupplierQuote.statuses(), &{SupplierQuote.status_label(&1), &1})}
              />
            </div>
            <.input
              field={@form[:notes]}
              label="Notes"
              type="textarea"
              rows="3"
              placeholder="Itemised details, terms, etc."
            />
            <div>
              <label class="block text-sm font-medium text-zinc-700 mb-1">
                Attach Quote File (PDF / image, max 10 MB)
              </label>
              <.live_file_input
                upload={@uploads.quote_file}
                class="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-medium file:bg-[#e7e7ff] file:text-[#373896] hover:file:bg-[#d2d3ff]"
              />
              <%= for entry <- @uploads.quote_file.entries do %>
                <div class="flex items-center gap-2 mt-2 p-2 bg-slate-50 rounded-lg">
                  <span class="text-sm flex-1 truncate">{entry.client_name}</span>
                  <button
                    type="button"
                    phx-click="cancel-upload"
                    phx-value-ref={entry.ref}
                    class="text-rose-500"
                  >
                    <Heroicons.icon name="x-mark" type="outline" class="h-4 w-4" />
                  </button>
                </div>
              <% end %>
            </div>
            <:actions>
              <.button type="submit" class="bg-[#373896] hover:bg-[#6667ab] shadow-sm px-5 py-2.5">
                {if @editing, do: "Update Quote", else: "Submit Quote"}
              </.button>
              <button
                type="button"
                phx-click="close-form"
                class="px-4 py-2.5 text-sm font-medium text-gray-600 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors"
              >
                Cancel
              </button>
            </:actions>
          </.simple_form>
        </.modal>
      <% end %>

      <div class="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
          <h3 class="text-base font-semibold text-[#373896]">All Quotes</h3>
          <span class="text-sm text-gray-500">{@total_count} quote(s)</span>
        </div>

        <%= if Enum.empty?(@quotes) do %>
          <div class="flex flex-col items-center justify-center py-16 text-center">
            <Heroicons.icon
              name="clipboard-document-list"
              type="outline"
              class="h-12 w-12 text-gray-300 mb-3"
            />
            <p class="text-gray-500 font-medium">No quotes submitted yet</p>
            <p class="text-gray-400 text-sm mt-1">Click "New Quote" to submit your first quote.</p>
          </div>
        <% else %>
          <div class="overflow-x-auto">
            <table class="w-full min-w-[900px]">
              <thead class="border-b border-slate-200 bg-slate-50/80">
                <tr>
                  <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Quote #
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Quote Date
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Expiry
                  </th>
                  <th class="px-6 py-4 text-right text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Amount
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Status
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                    File
                  </th>
                  <th class="px-6 py-4 text-right text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 bg-white">
                <tr :for={q <- @quotes} class="group transition-colors hover:bg-slate-50/50">
                  <td class="px-6 py-3 text-sm font-medium text-gray-900">{q.quote_number}</td>
                  <td class="px-6 py-3 text-sm text-gray-600">{q.quote_date || "—"}</td>
                  <td class="px-6 py-3 text-sm text-gray-600">{q.expiry_date || "—"}</td>
                  <td class="px-6 py-3 text-sm text-gray-900 text-right font-medium">
                    {q.currency} {(q.amount &&
                                     :erlang.float_to_binary(Decimal.to_float(q.amount), decimals: 2)) ||
                      "—"}
                  </td>
                  <td class="px-6 py-3 text-sm">
                    <span class={"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{SupplierQuote.status_color(q.status)}"}>
                      {SupplierQuote.status_label(q.status)}
                    </span>
                  </td>
                  <td class="px-6 py-3 text-sm">
                    <%= if q.file_path do %>
                      <a
                        href={q.file_path}
                        target="_blank"
                        class="text-[#6667ab] hover:text-[#373896] flex items-center gap-1"
                      >
                        <Heroicons.icon name="paper-clip" type="outline" class="h-4 w-4" />
                        <span class="truncate max-w-[120px]">{q.original_filename || "File"}</span>
                      </a>
                    <% else %>
                      <span class="text-gray-400">—</span>
                    <% end %>
                  </td>
                  <td class="px-6 py-3 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <.link
                        patch={~p"/supplier/quotes/#{q.id}/edit"}
                        class="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-semibold bg-[#e7e7ff] text-[#373896] hover:bg-[#d2d3ff] transition-colors"
                      >
                        <Heroicons.icon name="pencil-square" type="outline" class="h-3.5 w-3.5" />
                        Edit
                      </.link>
                      <button
                        phx-click="delete"
                        phx-value-id={q.id}
                        data-confirm="Delete this quote?"
                        class="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-semibold bg-rose-50 text-rose-600 hover:bg-rose-100 transition-colors"
                      >
                        <Heroicons.icon name="trash" type="outline" class="h-3.5 w-3.5" /> Delete
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
            <.pagination
              page={@page}
              total_pages={@total_pages}
              total_count={@total_count}
              per_page={@per_page}
              class="px-6 pb-4"
            />
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
