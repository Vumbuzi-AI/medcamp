defmodule MedcampWeb.SOPsLive.Index do
  use MedcampWeb, :shared_live_view

  import Ecto.Changeset, only: [add_error: 3]

  alias Medcamp.Departments
  alias Medcamp.SOPs
  alias Medcamp.SOPs.SOP

  @upload_dir Path.join(Application.app_dir(:medcamp, "priv/uploads"), "sops")
  @expiring_soon_days 14
  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    {:ok,
     socket
     |> assign(:active_tab, :sops)
     |> assign(:page_title, "SOPs")
     |> assign(:expiring_soon_days, @expiring_soon_days)
     |> assign(:filter_search, "")
     |> assign(:filter_department_id, "")
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:show_upload_modal, false)
     |> assign(:upload_modal_mode, :new)
     |> assign(:editing_sop, nil)
     |> assign(:show_view_modal, false)
     |> assign(:selected_sop, nil)
     |> assign(:departments, Departments.list_departments_for_selection())
     |> allow_upload(:pdf,
       accept: ~w(.pdf),
       max_entries: 1,
       max_file_size: 20_000_000
     )
     |> assign_form(default_form_attrs(current_user))
     |> load_sops()}
  end

  @impl true
  def handle_event("validate", %{"sop" => params}, socket) do
    changeset =
      socket.assigns.editing_sop
      |> changeset_for_form(base_params(params, socket))
      |> maybe_require_pdf(socket)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"sop" => params}, socket) do
    current_user = socket.assigns.current_user
    params = base_params(params, socket)

    changeset =
      socket.assigns.editing_sop
      |> changeset_for_form(params)
      |> maybe_require_pdf(socket)

    if changeset.valid? do
      file_params = maybe_persist_uploaded_pdf(socket)
      full_params = Map.merge(params, file_params)

      case save_sop(socket.assigns.editing_sop, full_params, current_user.id) do
        {:ok, _sop} ->
          {:noreply,
           socket
           |> put_flash(:info, success_message(socket.assigns.editing_sop))
           |> reset_upload_form(clear_uploads: false)
           |> load_sops()}

        {:error, create_changeset} ->
          {:noreply, assign(socket, :form, to_form(create_changeset))}
      end
    else
      {:noreply, assign(socket, :form, to_form(Map.put(changeset, :action, :validate)))}
    end
  end

  # The search box and the filter drawer submit independently (two separate
  # <form>s), so a submission from either one only carries its own fields.
  # Merging onto the current filters means a key absent from this submission
  # is left unchanged rather than reset.
  def handle_event("filter", %{"filters" => filters}, socket) do
    current = %{
      "search" => socket.assigns.filter_search,
      "department_id" => socket.assigns.filter_department_id
    }

    filters = Map.merge(current, filters)

    {:noreply,
     socket
     |> assign(:filter_search, Map.get(filters, "search", "") |> String.trim())
     |> assign(:filter_department_id, Map.get(filters, "department_id", "") |> String.trim())
     |> assign(:page, 1)
     |> load_sops()}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filter_search, "")
     |> assign(:filter_department_id, "")
     |> assign(:page, 1)
     |> load_sops()}
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_sops()}
  end

  def handle_event("clear_chip", %{"field" => field}, socket) do
    handle_event("filter", %{"filters" => %{field => ""}}, socket)
  end

  def handle_event("open-upload-modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_upload_modal, true)
     |> assign(:upload_modal_mode, :new)
     |> assign(:editing_sop, nil)
     |> assign_form(default_form_attrs(socket.assigns.current_user))}
  end

  def handle_event("edit-sop", %{"id" => id}, socket) do
    sop = SOPs.get_sop!(id)

    {:noreply,
     socket
     |> clear_upload_entries()
     |> assign(:show_upload_modal, true)
     |> assign(:upload_modal_mode, :edit)
     |> assign(:editing_sop, sop)
     |> assign_form(edit_form_attrs(sop))}
  end

  def handle_event("close-upload-modal", _params, socket) do
    {:noreply, reset_upload_form(socket, clear_uploads: true)}
  end

  def handle_event("view-sop", %{"id" => id}, socket) do
    sop = SOPs.get_sop!(id)

    {:noreply,
     socket
     |> assign(:selected_sop, sop)
     |> assign(:show_view_modal, true)}
  end

  def handle_event("close-view-modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:selected_sop, nil)
     |> assign(:show_view_modal, false)}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :pdf, ref)}
  end

  defp load_sops(socket) do
    all_sops =
      SOPs.list_sops(
        search: socket.assigns.filter_search,
        department_id: socket.assigns.filter_department_id
      )

    today = Date.utc_today()
    total_count = length(all_sops)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)
    sops = Enum.slice(all_sops, (page - 1) * socket.assigns.per_page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:sops, sops)
    |> assign(:today, today)
    |> assign(:total_sops, total_count)
    |> assign(:expiring_soon_count, Enum.count(all_sops, &expiring_soon?(&1, today)))
    |> assign(
      :department_count,
      all_sops |> Enum.map(& &1.department_id) |> Enum.uniq() |> length()
    )
  end

  defp assign_form(socket, attrs) do
    form =
      socket.assigns.editing_sop
      |> changeset_for_form(attrs)
      |> to_form()

    assign(socket, :form, form)
  end

  defp reset_upload_form(socket, opts) do
    socket =
      if Keyword.get(opts, :clear_uploads, true) do
        clear_upload_entries(socket)
      else
        socket
      end

    socket
    |> assign(:show_upload_modal, false)
    |> assign(:upload_modal_mode, :new)
    |> assign(:editing_sop, nil)
    |> assign_form(default_form_attrs(socket.assigns.current_user))
  end

  defp clear_upload_entries(socket) do
    Enum.reduce(socket.assigns.uploads.pdf.entries, socket, fn entry, acc ->
      safe_cancel_upload(acc, :pdf, entry.ref)
    end)
  end

  defp safe_cancel_upload(socket, name, ref) do
    cancel_upload(socket, name, ref)
  catch
    :exit, _ -> socket
  end

  defp default_form_attrs(current_user) do
    %{
      "name" => "",
      "description" => "",
      "valid_for_days" => "365",
      "department_id" =>
        current_user.department_id && Integer.to_string(current_user.department_id),
      "added_by_id" => Integer.to_string(current_user.id),
      "pdf_path" => "/uploads/sops/placeholder.pdf",
      "original_filename" => "placeholder.pdf"
    }
  end

  defp edit_form_attrs(sop) do
    %{
      "name" => sop.name || "",
      "description" => sop.description || "",
      "valid_for_days" => to_string(sop.valid_for_days || 365),
      "department_id" => sop.department_id && Integer.to_string(sop.department_id),
      "added_by_id" => to_string(sop.added_by_id),
      "pdf_path" => sop.pdf_path || "",
      "original_filename" => sop.original_filename || ""
    }
  end

  defp base_params(params, socket) do
    current_user = socket.assigns.current_user
    editing_sop = socket.assigns.editing_sop

    params
    |> Map.put("added_by_id", current_user.id)
    |> Map.put_new(
      "pdf_path",
      if(editing_sop, do: editing_sop.pdf_path, else: "/uploads/sops/placeholder.pdf")
    )
    |> Map.put_new(
      "original_filename",
      if(editing_sop, do: editing_sop.original_filename, else: placeholder_filename(socket))
    )
  end

  defp placeholder_filename(socket) do
    case socket.assigns.uploads.pdf.entries do
      [%{client_name: client_name} | _] -> client_name
      _ -> "placeholder.pdf"
    end
  end

  defp maybe_require_pdf(changeset, socket) do
    case {socket.assigns.editing_sop, socket.assigns.uploads.pdf.entries} do
      {nil, []} -> add_error(changeset, :pdf_path, "please upload a PDF file")
      _ -> changeset
    end
  end

  defp changeset_for_form(nil, attrs) do
    %SOP{}
    |> SOPs.change_sop(attrs)
  end

  defp changeset_for_form(sop, attrs) do
    SOPs.change_sop(sop, attrs)
  end

  defp maybe_persist_uploaded_pdf(socket) do
    case socket.assigns.uploads.pdf.entries do
      [] -> %{}
      _ -> persist_uploaded_pdf(socket)
    end
  end

  defp persist_uploaded_pdf(socket) do
    [file] =
      consume_uploaded_entries(socket, :pdf, fn %{path: path}, entry ->
        File.mkdir_p!(@upload_dir)

        filename =
          "sop_#{System.unique_integer([:positive])}_#{sanitize_filename(entry.client_name)}"

        destination = Path.join(@upload_dir, filename)
        File.cp!(path, destination)

        {:ok,
         %{
           "pdf_path" => "/uploads/sops/#{filename}",
           "original_filename" => entry.client_name
         }}
      end)

    file
  end

  defp save_sop(nil, full_params, user_id) do
    SOPs.create_sop(full_params, audit_user_id: user_id)
  end

  defp save_sop(sop, full_params, user_id) do
    SOPs.update_sop(sop, full_params, audit_user_id: user_id)
  end

  defp success_message(nil), do: "SOP uploaded successfully."
  defp success_message(_sop), do: "SOP updated successfully."

  defp sanitize_filename(filename) do
    filename
    |> Path.basename()
    |> String.replace(~r/[^A-Za-z0-9._-]/, "_")
  end

  defp valid_until(%SOP{inserted_at: inserted_at, valid_for_days: valid_for_days})
       when not is_nil(inserted_at) and is_integer(valid_for_days) do
    inserted_at
    |> DateTime.to_date()
    |> Date.add(valid_for_days)
  end

  defp valid_until(_), do: nil

  defp expiring_soon?(sop, today) do
    case valid_until(sop) do
      nil ->
        false

      expiry_date ->
        diff = Date.diff(expiry_date, today)
        diff >= 0 and diff <= @expiring_soon_days
    end
  end

  defp validity_badge_class(sop, today) do
    case valid_until(sop) do
      nil ->
        "bg-gray-100 text-gray-700"

      expiry_date ->
        cond do
          Date.compare(expiry_date, today) == :lt -> "bg-rose-100 text-rose-700"
          Date.diff(expiry_date, today) <= @expiring_soon_days -> "bg-amber-100 text-amber-800"
          true -> "bg-emerald-100 text-emerald-700"
        end
    end
  end

  defp validity_label(sop, today) do
    case valid_until(sop) do
      nil ->
        "Unknown"

      expiry_date ->
        cond do
          Date.compare(expiry_date, today) == :lt -> "Expired"
          Date.diff(expiry_date, today) <= @expiring_soon_days -> "Expiring soon"
          true -> "Active"
        end
    end
  end

  defp format_date(%Date{} = date), do: Calendar.strftime(date, "%d %b %Y")
  defp format_date(%DateTime{} = date_time), do: date_time |> DateTime.to_date() |> format_date()
  defp format_date(_), do: "-"

  defp count_active_filters(assigns) do
    [assigns.filter_department_id != ""]
    |> Enum.count(& &1)
  end

  defp filter_chips(filter_department_id, departments) do
    [
      filter_chip(
        filter_department_id,
        "department_id",
        department_name(filter_department_id, departments)
      )
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp department_name(id, departments) do
    case Enum.find(departments, fn {_name, dept_id} -> to_string(dept_id) == to_string(id) end) do
      {name, _id} -> name
      nil -> id
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.page_header
        icon_path="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
        title="SOPs"
        subtitle="Upload and review standard operating procedures across departments in one place."
      >
        <:actions>
          <.button phx-click="open-upload-modal" class="bg-[#6667ab] hover:bg-[#5556a0]">
            Upload SOP
          </.button>
        </:actions>
      </.page_header>

      <div class="grid gap-4 md:grid-cols-3">
        <div class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm">
          <p class="text-sm text-gray-500">Available SOPs</p>
          <p class="mt-2 text-3xl font-semibold text-[#373896]">{@total_sops}</p>
        </div>

        <div class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm">
          <p class="text-sm text-gray-500">Expiring within {@expiring_soon_days} days</p>
          <p class="mt-2 text-3xl font-semibold text-amber-600">{@expiring_soon_count}</p>
        </div>

        <div class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm">
          <p class="text-sm text-gray-500">Departments covered</p>
          <p class="mt-2 text-3xl font-semibold text-emerald-600">{@department_count}</p>
        </div>
      </div>

      <div class="space-y-6">
        <section class="rounded-xl border border-gray-100 bg-white p-6 shadow-sm">
          <.header class="text-[#373896]">
            SOP Library
            <:subtitle>Search across departments and open the latest PDF version directly.</:subtitle>
          </.header>

          <div class="flex flex-wrap items-center gap-3 mb-5 mt-4">
            <form phx-change="filter" class="flex-1">
              <.search_input
                name="filters[search]"
                value={@filter_search}
                placeholder="Name, description, department, uploader"
              />
            </form>

            <.filter_drawer
              id="sop-filters"
              title="Filter SOPs"
              apply_event="filter"
              clear_event="clear_filters"
              active_count={count_active_filters(assigns)}
            >
              <:group label="Department">
                <.input
                  type="select"
                  name="filters[department_id]"
                  value={@filter_department_id}
                  options={@departments}
                  prompt="All departments"
                />
              </:group>

              <:chip
                :for={chip <- filter_chips(@filter_department_id, @departments)}
                label={chip.label}
                clear={JS.push("clear_chip", value: %{"field" => chip.field})}
              />
            </.filter_drawer>
          </div>

          <div class="overflow-x-auto">
            <.blank_state
              :if={@sops == []}
              icon_path="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              title="No SOPs found"
              description={
                if @filter_search != "" or count_active_filters(assigns) > 0,
                  do: "No SOPs match the current filters.",
                  else: "No SOPs have been uploaded yet."
              }
            >
              <:actions :if={@filter_search != "" or count_active_filters(assigns) > 0}>
                <button phx-click="clear_filters" class="text-xs text-[#6667ab] hover:underline">
                  Clear filters
                </button>
              </:actions>
            </.blank_state>
            <table :if={@sops != []} class="min-w-full divide-y divide-gray-200">
              <thead>
                <tr class="text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  <th class="px-3 py-3">SOP</th>
                  <th class="px-3 py-3">Department</th>
                  <th class="px-3 py-3">Validity</th>
                  <th class="px-3 py-3">Added by</th>
                  <th class="px-3 py-3">PDF</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 bg-white text-sm text-gray-700">
                <%= for sop <- @sops do %>
                  <tr>
                    <td class="px-3 py-4 align-top">
                      <div class="font-medium text-gray-900">{sop.name}</div>
                      <div class="mt-1 max-w-xl  text-xs text-gray-500">
                        {sop.description}
                      </div>
                      <div class="mt-2 text-xs text-gray-400">
                        Uploaded {format_date(sop.inserted_at)}
                      </div>
                    </td>
                    <td class="px-3 py-4 align-top">{sop.department.name}</td>
                    <td class="px-3 py-4 align-top">
                      <span class={"inline-flex rounded-full px-2.5 py-1 text-xs font-medium #{validity_badge_class(sop, @today)}"}>
                        {validity_label(sop, @today)}
                      </span>
                      <div class="mt-2 text-xs text-gray-500">{sop.valid_for_days} day(s)</div>
                      <div class="text-xs text-gray-500">Expires {format_date(valid_until(sop))}</div>
                    </td>
                    <td class="px-3 py-4 align-top">{sop.added_by.name}</td>
                    <td class="px-3 py-4 align-top">
                      <div class="flex flex-col items-start gap-2">
                        <div class="flex flex-wrap gap-2">
                          <button
                            type="button"
                            phx-click="view-sop"
                            phx-value-id={sop.id}
                            class="inline-flex items-center gap-2 rounded-lg bg-[#e7e7ff] px-3 py-2 text-xs font-medium text-[#373896] hover:bg-[#d2d3ff]"
                          >
                            <Heroicons.icon name="eye" type="outline" class="h-4 w-4" /> View SOP
                          </button>

                          <button
                            type="button"
                            phx-click="edit-sop"
                            phx-value-id={sop.id}
                            class="inline-flex items-center gap-2 rounded-lg border border-gray-300 px-3 py-2 text-xs font-medium text-gray-700 hover:bg-gray-50"
                          >
                            <Heroicons.icon name="pencil-square" type="outline" class="h-4 w-4" />
                            Edit
                          </button>
                        </div>

                        <a
                          href={sop.pdf_path}
                          target="_blank"
                          rel="noopener noreferrer"
                          class="inline-flex items-center gap-2 text-[#6667ab] hover:text-[#373896]"
                        >
                          <Heroicons.icon name="document-text" type="outline" class="h-4 w-4" />
                          <span class="max-w-[180px] truncate">{sop.original_filename}</span>
                        </a>
                      </div>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
            <.pagination
              page={@page}
              total_pages={@total_pages}
              total_count={@total_count}
              per_page={@per_page}
            />
          </div>
        </section>
      </div>

      <.modal
        :if={@show_upload_modal}
        id="sop-upload-modal"
        show
        on_cancel={JS.push("close-upload-modal")}
      >
        <div class="space-y-5">
          <.header class="text-[#373896]">
            {if @upload_modal_mode == :edit, do: "Edit SOP", else: "Upload SOP"}
            <:subtitle>
              {if @upload_modal_mode == :edit,
                do: "Update the SOP details and optionally replace the PDF.",
                else: "Store the PDF together with the ownership and validity details."}
            </:subtitle>
          </.header>

          <.simple_form for={@form} phx-change="validate" phx-submit="save">
            <.input field={@form[:name]} label="SOP name" placeholder="Hand hygiene procedure" />

            <.input
              field={@form[:description]}
              type="textarea"
              label="Description"
              placeholder="Short summary of what the SOP covers"
            />

            <div class="grid gap-4 md:grid-cols-2">
              <.input
                field={@form[:valid_for_days]}
                type="number"
                min="1"
                max="3650"
                label="Valid for (days)"
              />

              <.input
                field={@form[:department_id]}
                type="select"
                options={@departments}
                prompt="Select department"
                label="Department"
              />
            </div>

            <div class="rounded-xl border border-dashed border-gray-300 bg-gray-50 p-4">
              <div class="mb-2 text-sm font-medium text-gray-700">Added by</div>
              <div class="text-sm text-gray-600">{@current_user.name}</div>
            </div>

            <div>
              <label class="mb-1 block text-sm font-medium text-zinc-700">SOP PDF</label>
              <div
                :if={@upload_modal_mode == :edit && @editing_sop}
                class="mb-2 rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-xs text-gray-600"
              >
                Current file: {@editing_sop.original_filename}
              </div>

              <.live_file_input
                upload={@uploads.pdf}
                class="block w-full text-sm text-gray-500 file:mr-4 file:rounded-lg file:border-0 file:bg-[#e7e7ff] file:px-4 file:py-2 file:text-sm file:font-medium file:text-[#373896] hover:file:bg-[#d2d3ff]"
              />

              <%= for error <- @form[:pdf_path].errors do %>
                <p class="mt-2 text-sm text-rose-600">{translate_error(error)}</p>
              <% end %>

              <%= for entry <- @uploads.pdf.entries do %>
                <div class="mt-2 flex items-center gap-2 rounded-lg bg-slate-50 p-2">
                  <span class="flex-1 truncate text-sm">{entry.client_name}</span>
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

              <p class="mt-2 text-xs text-gray-500">
                {if @upload_modal_mode == :edit,
                  do: "PDF only, up to 20 MB. Leave empty to keep the current file.",
                  else: "PDF only, up to 20 MB."}
              </p>
            </div>

            <:actions>
              <.button class="bg-[#6667ab] hover:bg-[#5556a0]">
                {if @upload_modal_mode == :edit, do: "Save Changes", else: "Upload SOP"}
              </.button>
              <button
                type="button"
                phx-click="close-upload-modal"
                class="px-4 py-2 text-sm text-gray-600 hover:text-gray-800"
              >
                Cancel
              </button>
            </:actions>
          </.simple_form>
        </div>
      </.modal>

      <.modal
        :if={@show_view_modal && @selected_sop}
        id="sop-view-modal"
        show
        on_cancel={JS.push("close-view-modal")}
      >
        <div :if={@selected_sop} class="space-y-5">
          <.header class="text-[#373896]">
            {@selected_sop.name}
            <:subtitle>
              {@selected_sop.department.name} SOP uploaded by {@selected_sop.added_by.name}
            </:subtitle>
          </.header>

          <div class="grid gap-4 md:grid-cols-2">
            <div class="rounded-xl border border-gray-200 bg-gray-50 p-4">
              <div class="text-xs font-semibold uppercase tracking-wider text-gray-500">
                Description
              </div>
              <div class="mt-2 whitespace-pre-wrap text-sm text-gray-700">
                {@selected_sop.description}
              </div>
            </div>

            <div class="rounded-xl border border-gray-200 bg-gray-50 p-4 text-sm text-gray-700">
              <div>
                <span class="font-medium text-gray-900">Valid for:</span> {@selected_sop.valid_for_days} days
              </div>
              <div class="mt-2">
                <span class="font-medium text-gray-900">Uploaded:</span> {format_date(
                  @selected_sop.inserted_at
                )}
              </div>
              <div class="mt-2">
                <span class="font-medium text-gray-900">Expires:</span> {format_date(
                  valid_until(@selected_sop)
                )}
              </div>
              <div class="mt-2">
                <span class="font-medium text-gray-900">File:</span> {@selected_sop.original_filename}
              </div>
            </div>
          </div>

          <div class="overflow-hidden rounded-xl border border-gray-200 bg-white">
            <div class="flex items-center justify-between border-b border-gray-100 px-4 py-3">
              <h3 class="text-sm font-semibold text-gray-900">PDF Preview</h3>
              <a
                href={@selected_sop.pdf_path}
                target="_blank"
                rel="noopener noreferrer"
                class="inline-flex items-center gap-2 text-sm font-medium text-[#6667ab] hover:text-[#373896]"
              >
                <Heroicons.icon name="arrow-top-right-on-square" type="outline" class="h-4 w-4" />
                Open in new tab
              </a>
            </div>

            <iframe
              src={@selected_sop.pdf_path}
              title={@selected_sop.name}
              class="h-[70vh] w-full bg-gray-50"
            />
          </div>
        </div>
      </.modal>
    </div>
    """
  end
end
