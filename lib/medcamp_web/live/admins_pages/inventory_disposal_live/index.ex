defmodule MedcampWeb.AdminInventoryDisposalLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.InventoryDisposals
  alias Medcamp.InventoryDisposals.InventoryDisposal

  @upload_dir Path.join(Application.app_dir(:medcamp, "priv/uploads"), "donations")

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :inventory_disposals)
     |> assign(:kind, "donation")
     |> assign(:show_new_form, false)
     |> allow_upload(:supporting_document,
       accept: ~w(.pdf),
       max_entries: 1,
       max_file_size: 20_000_000
     )
     |> assign_form()
     |> load_disposals()}
  end

  @impl true
  def handle_event("select_kind", %{"kind" => kind}, socket)
      when kind in ["donation", "expiry"] do
    {:noreply,
     socket
     |> assign(:kind, kind)
     |> assign(:show_new_form, false)
     |> assign_form()
     |> load_disposals()}
  end

  def handle_event("show_new_form", _, socket),
    do: {:noreply, socket |> assign(:show_new_form, true) |> assign_form()}

  def handle_event("cancel_new", _, socket),
    do: {:noreply, assign(socket, :show_new_form, false)}

  def handle_event("validate", %{"inventory_disposal" => params}, socket) do
    attrs =
      params
      |> Map.put("kind", socket.assigns.kind)
      |> Map.put("requested_by_id", socket.assigns.current_user.id)

    form =
      %InventoryDisposal{}
      |> InventoryDisposals.change_disposal(attrs)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("create", %{"inventory_disposal" => params}, socket) do
    with {:ok, document_attrs} <- supporting_document_attrs(socket),
         attrs <-
           params
           |> Map.put("kind", socket.assigns.kind)
           |> Map.put("requested_by_id", socket.assigns.current_user.id)
           |> Map.merge(document_attrs),
         {:ok, disposal} <- InventoryDisposals.create_disposal(attrs) do
      {:noreply,
       socket
       |> put_flash(
         :info,
         "#{kind_label(socket.assigns.kind)} request created. Add its items next."
       )
       |> push_navigate(to: "/admin/inventory_disposals/#{disposal.id}")}
    else
      {:error, :document_required} ->
        {:noreply, put_flash(socket, :error, "Upload the donation request PDF.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="rounded-xl border border-slate-200 bg-white px-6 py-5 shadow-sm">
        <div class="flex flex-wrap items-center gap-3">
          <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-amber-100">
            <Heroicons.icon name="arrow-up-tray" type="outline" class="h-5 w-5 text-amber-700" />
          </div>
          <div class="flex-1">
            <h1 class="text-lg font-semibold text-slate-900">Donations & Expiry</h1>
            <p class="text-sm text-slate-500">
              Review and approve stock leaving inventory, with a complete audit trail.
            </p>
          </div>
          <button
            phx-click="show_new_form"
            class="rounded-lg bg-[#373896] px-4 py-2 text-sm font-semibold text-white hover:bg-[#2d2e7b]"
          >
            New {kind_label(@kind)} request
          </button>
        </div>

        <div class="mt-5 flex gap-1 border-b border-slate-200">
          <%= for {kind, label} <- [{"donation", "Donations"}, {"expiry", "Expiry"}] do %>
            <button
              phx-click="select_kind"
              phx-value-kind={kind}
              class={[
                "border-b-2 px-5 py-2.5 text-sm font-semibold",
                @kind == kind && "border-[#373896] text-[#373896]",
                @kind != kind && "border-transparent text-slate-500 hover:text-slate-700"
              ]}
            >
              {label}
            </button>
          <% end %>
        </div>
      </div>

      <%= if @show_new_form do %>
        <div class="rounded-xl border border-indigo-200 bg-white p-6 shadow-sm">
          <h2 class="mb-4 font-semibold text-slate-900">New {kind_label(@kind)} request</h2>
          <.form for={@form} phx-change="validate" phx-submit="create">
            <div class="grid gap-4 md:grid-cols-2">
              <.input field={@form[:date]} type="date" label="Date" />
              <div class="md:col-span-2">
                <.input
                  field={@form[:reason]}
                  type="textarea"
                  label={if @kind == "donation", do: "Recipient / reason", else: "Expiry notes"}
                />
              </div>
              <%= if @kind == "donation" do %>
                <div class="md:col-span-2">
                  <label class="mb-2 block text-sm font-medium text-slate-700">
                    Donation request PDF <span class="text-red-600">*</span>
                  </label>
                  <.live_file_input
                    upload={@uploads.supporting_document}
                    class="block w-full rounded-lg border border-slate-300 p-2 text-sm"
                  />
                  <p class="mt-1 text-xs text-slate-500">PDF only, up to 20 MB.</p>
                  <%= for entry <- @uploads.supporting_document.entries do %>
                    <p class="mt-2 text-sm text-slate-700">{entry.client_name}</p>
                    <%= for err <- upload_errors(@uploads.supporting_document, entry) do %>
                      <p class="text-sm text-red-600">{upload_error(err)}</p>
                    <% end %>
                  <% end %>
                </div>
              <% end %>
            </div>
            <div class="mt-5 flex justify-end gap-3">
              <button type="button" phx-click="cancel_new" class="rounded-lg border px-4 py-2 text-sm">
                Cancel
              </button>
              <button class="rounded-lg bg-[#373896] px-4 py-2 text-sm font-semibold text-white">
                Create and add items
              </button>
            </div>
          </.form>
        </div>
      <% end %>

      <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="bg-slate-50 text-left text-xs uppercase tracking-wide text-slate-500">
              <tr>
                <th class="px-5 py-3">Reference</th>
                <th class="px-5 py-3">Date</th>
                <th class="px-5 py-3">Requested by</th>
                <th class="px-5 py-3">Items</th>
                <th class="px-5 py-3">Status</th>
                <th class="px-5 py-3">Evidence</th>
                <th class="px-5 py-3"></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
              <%= for disposal <- @disposals do %>
                <tr class="hover:bg-slate-50">
                  <td class="px-5 py-4 font-semibold text-slate-800">#{disposal.id}</td>
                  <td class="px-5 py-4">{format_date(disposal.date)}</td>
                  <td class="px-5 py-4">{disposal.requested_by.name}</td>
                  <td class="px-5 py-4">{length(disposal.items)}</td>
                  <td class="px-5 py-4">{status_badge(assigns, disposal.status)}</td>
                  <td class="px-5 py-4">
                    <%= if disposal.supporting_document_path do %>
                      <a
                        href={disposal.supporting_document_path}
                        target="_blank"
                        class="font-medium text-[#373896] hover:underline"
                      >
                        View PDF
                      </a>
                    <% else %>
                      <span class="text-slate-400">—</span>
                    <% end %>
                  </td>
                  <td class="px-5 py-4 text-right">
                    <.link
                      navigate={"/admin/inventory_disposals/#{disposal.id}"}
                      class="font-semibold text-[#373896] hover:underline"
                    >
                      Open
                    </.link>
                  </td>
                </tr>
              <% end %>
              <%= if @disposals == [] do %>
                <tr>
                  <td colspan="7" class="px-5 py-12 text-center text-slate-500">
                    No {String.downcase(kind_label(@kind))} requests yet.
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  defp assign_form(socket) do
    attrs = %{kind: socket.assigns.kind, date: Date.utc_today()}

    assign(
      socket,
      :form,
      to_form(InventoryDisposals.change_disposal(%InventoryDisposal{}, attrs))
    )
  end

  defp load_disposals(socket),
    do: assign(socket, :disposals, InventoryDisposals.list_disposals(socket.assigns.kind))

  defp supporting_document_attrs(%{assigns: %{kind: "expiry"}}), do: {:ok, %{}}

  defp supporting_document_attrs(socket) do
    case socket.assigns.uploads.supporting_document.entries do
      [] ->
        {:error, :document_required}

      _ ->
        [attrs] =
          consume_uploaded_entries(socket, :supporting_document, fn %{path: path}, entry ->
            File.mkdir_p!(@upload_dir)
            filename = "donation_#{System.unique_integer([:positive])}.pdf"
            File.cp!(path, Path.join(@upload_dir, filename))

            {:ok,
             %{
               "supporting_document_path" => "/uploads/donations/#{filename}",
               "supporting_document_name" => entry.client_name
             }}
          end)

        {:ok, attrs}
    end
  end

  defp kind_label("donation"), do: "Donation"
  defp kind_label("expiry"), do: "Expiry"
  defp format_date(nil), do: "—"
  defp format_date(date), do: Calendar.strftime(date, "%d %b %Y")

  defp upload_error(:too_large), do: "File is too large."
  defp upload_error(:not_accepted), do: "Only PDF files are accepted."
  defp upload_error(error), do: inspect(error)

  defp status_badge(assigns, status) do
    assigns = assign(assigns, :status, status)

    ~H"""
    <span class={[
      "inline-flex rounded-full px-2.5 py-1 text-xs font-semibold capitalize",
      @status == "draft" && "bg-slate-100 text-slate-700",
      @status == "pending" && "bg-amber-100 text-amber-800",
      @status == "approved" && "bg-emerald-100 text-emerald-800",
      @status == "rejected" && "bg-red-100 text-red-800"
    ]}>
      {@status}
    </span>
    """
  end
end
