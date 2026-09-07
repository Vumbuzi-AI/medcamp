defmodule MedcampWeb.AdminInsuranceLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.Insurance

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    insurer_names = Insurance.list_insurer_names()
    opts = %{date_from: "", date_to: "", source: ""}

    {:ok,
     socket
     |> assign(:active_tab, :insurance)
     |> assign(:search, "")
     |> assign(:insurer_filter, "")
     |> assign(:gsrn_filter, "")
     |> assign(:date_from, "")
     |> assign(:date_to, "")
     |> assign(:source_filter, "")
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:insurer_names, insurer_names)
     |> assign(:gsrn_options, load_gsrn_options(opts))
     |> assign_state(load_default_state("", opts))}
  end

  # Pulls the patients list out of a loaded state map and paginates it in memory;
  # every state change restarts from page 1.
  defp assign_state(socket, state) do
    {patients, state} = Map.pop(state, :patients, [])

    socket
    |> assign(state)
    |> assign(:all_patients, patients)
    |> assign(:page, 1)
    |> paginate_patients()
  end

  defp paginate_patients(socket) do
    all_patients = socket.assigns.all_patients
    total_count = length(all_patients)
    total_pages = max(1, Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page))
    page = min(max(1, socket.assigns.page || 1), total_pages)

    patients =
      Enum.slice(all_patients, (page - 1) * socket.assigns.per_page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:patients, patients)
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"search" => %{"query" => query}}, socket) do
    opts = date_opts(socket)

    {:noreply,
     socket
     |> assign(:search, query)
     |> assign_state(
       load_current_state(query, socket.assigns.insurer_filter, socket.assigns.gsrn_filter, opts)
     )}
  end

  @impl true
  def handle_event("clear_search", _, socket) do
    opts = date_opts(socket)

    {:noreply,
     socket
     |> assign(:search, "")
     |> assign_state(
       load_current_state("", socket.assigns.insurer_filter, socket.assigns.gsrn_filter, opts)
     )}
  end

  # The search box and the filter drawer submit independently (two separate
  # <form>s), so a submission from either one only carries its own fields.
  # Merging onto the current filters means a key absent from this submission
  # is left unchanged rather than reset.
  @impl true
  def handle_event("filter", %{"filters" => filters}, socket) do
    current = %{
      "insurer" => socket.assigns.insurer_filter,
      "gsrn" => socket.assigns.gsrn_filter,
      "source" => socket.assigns.source_filter,
      "date_from" => socket.assigns.date_from,
      "date_to" => socket.assigns.date_to
    }

    merged = Map.merge(current, filters)

    insurer = merged["insurer"] || ""
    gsrn = merged["gsrn"] || ""
    source = merged["source"] || ""
    date_from = merged["date_from"] || ""
    date_to = merged["date_to"] || ""

    # Insurer and GSRN are mutually exclusive report views — whichever field
    # changed in this submission wins over the other.
    {insurer, gsrn} =
      cond do
        insurer != current["insurer"] -> {insurer, ""}
        gsrn != current["gsrn"] -> {"", gsrn}
        true -> {insurer, gsrn}
      end

    opts = %{date_from: date_from, date_to: date_to, source: source}

    {:noreply,
     socket
     |> assign(:insurer_filter, insurer)
     |> assign(:gsrn_filter, gsrn)
     |> assign(:source_filter, source)
     |> assign(:date_from, date_from)
     |> assign(:date_to, date_to)
     |> assign(:gsrn_options, load_gsrn_options(opts))
     |> assign_state(load_current_state(socket.assigns.search, insurer, gsrn, opts))}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    opts = %{date_from: "", date_to: "", source: ""}

    {:noreply,
     socket
     |> assign(:insurer_filter, "")
     |> assign(:gsrn_filter, "")
     |> assign(:source_filter, "")
     |> assign(:date_from, "")
     |> assign(:date_to, "")
     |> assign(:gsrn_options, load_gsrn_options(opts))
     |> assign_state(load_current_state(socket.assigns.search, "", "", opts))}
  end

  @impl true
  def handle_event("exclude_invoice_item", %{"type" => type, "id" => id}, socket) do
    opts = date_opts(socket)

    case Insurance.exclude_record_from_invoice(type, id) do
      {:ok, _record} ->
        {:noreply,
         socket
         |> put_flash(:info, "#{invoice_item_type_label(type)} removed from this invoice.")
         |> assign(:gsrn_options, load_gsrn_options(opts))
         |> assign_state(
           load_current_state(
             socket.assigns.search,
             socket.assigns.insurer_filter,
             socket.assigns.gsrn_filter,
             opts
           )
         )}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Unable to remove that item from the invoice.")}
    end
  end

  @impl true
  def handle_event(
        "exclude_invoice_category",
        %{"type" => type, "patient_id" => patient_id, "insurer_name" => insurer_name},
        socket
      ) do
    opts = date_opts(socket)

    case Insurance.exclude_category_from_invoice(patient_id, insurer_name, type, opts) do
      {:ok, count} when count > 0 ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           "#{invoice_item_type_label(type)} removed from this invoice#{if count > 1, do: " (#{count} items)", else: ""}."
         )
         |> assign(:gsrn_options, load_gsrn_options(opts))
         |> assign_state(
           load_current_state(
             socket.assigns.search,
             socket.assigns.insurer_filter,
             socket.assigns.gsrn_filter,
             opts
           )
         )}

      {:ok, 0} ->
        {:noreply, put_flash(socket, :error, "No matching invoice items were found to remove.")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Unable to remove that category from the invoice.")}
    end
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    page_num =
      case Integer.parse(page) do
        {i, _} -> max(1, i)
        :error -> 1
      end

    {:noreply,
     socket
     |> assign(:page, page_num)
     |> paginate_patients()}
  end

  defp count_active_filters(assigns) do
    [
      assigns.insurer_filter != "",
      assigns.gsrn_filter != "",
      assigns.source_filter != "",
      assigns.date_from != "",
      assigns.date_to != ""
    ]
    |> Enum.count(& &1)
  end

  defp date_opts(socket) do
    build_opts(socket)
  end

  defp build_opts(socket, overrides \\ []) do
    %{
      date_from: socket.assigns.date_from,
      date_to: socket.assigns.date_to,
      source: socket.assigns.source_filter
    }
    |> Map.merge(Map.new(overrides))
  end

  defp load_default_state(search, opts) do
    %{
      insurer_summary: nil,
      claim_data: [],
      selected_patient: nil,
      patient_summary: nil,
      patient_claim_data: [],
      patients: Insurance.list_insurance_patients(search, opts)
    }
  end

  defp load_insurer_state(insurer, opts) do
    %{
      insurer_summary: Insurance.insurer_summary(insurer, opts),
      claim_data: Insurance.get_insurer_claim_data(insurer, opts),
      selected_patient: nil,
      patient_summary: nil,
      patient_claim_data: [],
      patients: Insurance.list_patients_for_insurer(insurer, opts)
    }
  end

  defp load_patient_state(gsrn, opts) do
    case Insurance.get_insurance_patient_by_gsrn(gsrn, opts) do
      nil ->
        %{
          insurer_summary: nil,
          claim_data: [],
          selected_patient: nil,
          patient_summary: nil,
          patient_claim_data: [],
          patients: []
        }

      patient ->
        %{
          insurer_summary: nil,
          claim_data: [],
          selected_patient: patient,
          patient_summary: Insurance.patient_insurance_summary(patient.id, opts),
          patient_claim_data: Insurance.get_patient_claim_data(patient.id, opts),
          patients: [patient]
        }
    end
  end

  defp load_current_state(search, insurer, gsrn, opts) do
    cond do
      insurer != "" -> load_insurer_state(insurer, opts)
      gsrn != "" -> load_patient_state(gsrn, opts)
      true -> load_default_state(search, opts)
    end
  end

  defp load_gsrn_options(opts) do
    Insurance.list_insurance_patients("", opts)
    |> Enum.filter(&(&1.gsrn && &1.gsrn != ""))
    |> Enum.sort_by(fn patient -> {patient_full_name(patient), patient.gsrn} end)
  end

  defp patient_full_name(patient) do
    [patient.first_name, patient.middle_name, patient.last_name]
    |> Enum.filter(&(&1 != nil && &1 != ""))
    |> Enum.join(" ")
  end

  defp report_category_meta do
    [
      {"Consultancy", :visit, "bg-slate-50 text-purple-700 ring-purple-200"},
      {"Pharmacy", :drug, "bg-blue-50 text-blue-700 ring-blue-200"},
      {"Lab Tests", :lab, "bg-amber-50 text-amber-700 ring-amber-200"},
      {"Nursing", :nurse_procedure, "bg-teal-50 text-teal-700 ring-teal-200"},
      {"Doctor Procedure", :doctor_procedure, "bg-indigo-50 text-indigo-700 ring-indigo-200"}
    ]
  end

  defp report_summary_badges do
    %{
      visit: {"Consultancy", "bg-purple-100 text-purple-700"},
      drug: {"Pharmacy", "bg-blue-100 text-blue-700"},
      nurse_procedure: {"Nursing", "bg-teal-100 text-teal-700"},
      doctor_procedure: {"Doctor Procedure", "bg-indigo-100 text-indigo-700"},
      lab: {"Lab Tests", "bg-amber-100 text-amber-700"}
    }
  end

  defp report_category_totals(records) do
    report_category_meta()
    |> Enum.map(fn {label, type, classes} ->
      total =
        records
        |> Enum.filter(&(&1.type == type))
        |> Enum.map(&(&1.amount || 0))
        |> Enum.sum()

      {label, total, classes}
    end)
    |> Enum.filter(fn {_, total, _} -> total > 0 end)
  end

  defp report_summary_rows(records) do
    type_meta = report_summary_badges()

    [:visit, :drug, :nurse_procedure, :doctor_procedure, :lab]
    |> Enum.map(fn type ->
      matching_records = Enum.filter(records, &(&1.type == type))
      {label, badge} = Map.fetch!(type_meta, type)

      %{
        type: type,
        label: label,
        badge: badge,
        count: length(matching_records),
        total: Enum.sum(Enum.map(matching_records, &(&1.amount || 0)))
      }
    end)
    |> Enum.filter(&(&1.count > 0))
  end

  defp invoice_item_type_label("visit"), do: "Consultancy"
  defp invoice_item_type_label("drug"), do: "Pharmacy"
  defp invoice_item_type_label("nurse_procedure"), do: "Nursing"
  defp invoice_item_type_label("doctor_procedure"), do: "Doctor procedure"
  defp invoice_item_type_label("lab"), do: "Lab test"

  defp invoice_item_type_label(type) when is_atom(type),
    do: type |> Atom.to_string() |> invoice_item_type_label()

  defp invoice_item_type_label(_), do: "Item"

  defp format_invoice_record_date(%Date{} = date), do: Calendar.strftime(date, "%b %-d, %Y")
  defp format_invoice_record_date(_), do: "—"

  attr :records, :list, required: true

  defp invoice_record_table(assigns) do
    ~H"""
    <div class="mt-4 overflow-hidden rounded-lg border border-slate-200 print:hidden">
      <table class="min-w-full divide-y divide-slate-200 text-sm">
        <thead class="bg-slate-50">
          <tr>
            <th class="px-4 py-2.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
              Item
            </th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
              Date
            </th>
            <th class="px-4 py-2.5 text-right text-xs font-semibold uppercase tracking-wider text-slate-500">
              Amount (KSh)
            </th>
            <th class="px-4 py-2.5 text-right text-xs font-semibold uppercase tracking-wider text-slate-500 print:hidden">
              Action
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-100 bg-white">
          <%= for record <- @records do %>
            <% {label, badge_class} = Map.fetch!(report_summary_badges(), record.type) %>
            <tr>
              <td class="px-4 py-3">
                <div class="flex flex-col gap-1">
                  <div class="flex flex-wrap items-center gap-2">
                    <span class={"inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold #{badge_class}"}>
                      {label}
                    </span>
                    <%= if record.has_paid do %>
                      <span class="inline-flex items-center rounded-full bg-emerald-50 px-2 py-0.5 text-xs font-medium text-emerald-700">
                        Paid
                      </span>
                    <% end %>
                  </div>
                  <p class="text-sm font-medium text-slate-900">{record.description}</p>
                </div>
              </td>
              <td class="px-4 py-3 text-sm text-slate-500">
                {format_invoice_record_date(record.date)}
              </td>
              <td class="px-4 py-3 text-right font-semibold text-slate-900 tabular-nums">
                {Number.Delimit.number_to_delimited(record.amount || 0, precision: 0)}
              </td>
              <td class="px-4 py-3 text-right print:hidden">
                <button
                  type="button"
                  phx-click="exclude_invoice_item"
                  phx-value-type={record.type}
                  phx-value-id={record.id}
                  data-confirm="Remove this item from the insurance invoice?"
                  class="inline-flex items-center rounded-lg border border-rose-200 bg-rose-50 px-3 py-1.5 text-xs font-semibold text-rose-700 hover:bg-rose-100"
                >
                  Remove
                </button>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <%!-- Header --%>
      <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 px-6 py-5 print:hidden">
        <.page_header
          icon_path="M9 12.75L11.25 15 15 9.75M21 12c0 1.268-.63 2.39-1.593 3.068a3.745 3.745 0 01-1.043 3.296 3.745 3.745 0 01-3.296 1.043A3.745 3.745 0 0112 21c-1.268 0-2.39-.63-3.068-1.593a3.746 3.746 0 01-3.296-1.043 3.745 3.745 0 01-1.043-3.296A3.745 3.745 0 013 12c0-1.268.63-2.39 1.593-3.068a3.745 3.745 0 011.043-3.296 3.746 3.746 0 013.296-1.043A3.746 3.746 0 0112 3c1.268 0 2.39.63 3.068 1.593a3.746 3.746 0 013.296 1.043 3.746 3.746 0 011.043 3.296A3.745 3.745 0 0121 12z"
          title={
            if @source_filter == "hospital",
              do: "Hospital Only: Insurance Claims",
              else: "Insurance Claims"
          }
          subtitle={
            if @source_filter == "hospital",
              do: hospital_source_exclusion_label(),
              else: "Search, filter and manage patient insurance claims."
          }
        >
          <:actions>
            <%= if @insurer_filter != "" or @gsrn_filter != "" do %>
              <button
                id="download-pdf-btn"
                phx-hook="DownloadPDF"
                class="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-blue-700"
              >
                <Heroicons.icon name="arrow-down-tray" type="outline" class="h-4 w-4" /> Download PDF
              </button>
            <% end %>
            <span class="inline-flex items-center rounded-full bg-blue-50 px-3 py-1 text-sm font-medium text-blue-700">
              {@total_count} patient{if @total_count != 1, do: "s", else: ""}
            </span>
          </:actions>
        </.page_header>
      </div>

      <%= if @source_filter == "hospital" do %>
        <div class="rounded-xl border border-amber-200 bg-amber-50 px-6 py-4 text-sm text-amber-900 print:hidden">
          <div class="flex items-start gap-3">
            <Heroicons.icon
              name="information-circle"
              type="solid"
              class="mt-0.5 h-5 w-5 shrink-0 text-amber-600"
            />
            <div>
              <p class="font-semibold">Hospital-only report prefix active</p>
              <p class="mt-1 text-amber-800">
                {hospital_source_exclusion_label()}. Insurance claim records that fall on those
                two dates are left out of this report, while records outside those dates remain visible.
              </p>
            </div>
          </div>
        </div>
      <% end %>

      <%!-- Filters --%>
      <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 px-6 py-4 space-y-3 print:hidden">
        <div class="flex items-center gap-3">
          <%= if @insurer_filter == "" and @gsrn_filter == "" do %>
            <form phx-change="search" phx-submit="search" class="flex-1">
              <.search_input
                name="search[query]"
                value={@search}
                placeholder="Search by patient name, GSRN, email, or insurer name"
              />
            </form>
          <% else %>
            <div class="flex-1"></div>
          <% end %>

          <.filter_drawer
            id="insurance-filters"
            title="Filter insurance claims"
            apply_event="filter"
            clear_event="clear_filters"
            active_count={count_active_filters(assigns)}
          >
            <:group label="Insurer and GSRN">
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">Insurer</label>
                <select
                  name="filters[insurer]"
                  class="w-full h-9 rounded-md border border-gray-300 px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
                >
                  <option value="">All insurers</option>
                  <%= for name <- @insurer_names do %>
                    <option value={name} selected={@insurer_filter == name}>{name}</option>
                  <% end %>
                </select>
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">GSRN</label>
                <select
                  name="filters[gsrn]"
                  class="w-full h-9 rounded-md border border-gray-300 px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
                >
                  <option value="">All GSRNs</option>
                  <%= for patient <- @gsrn_options do %>
                    <option value={patient.gsrn} selected={@gsrn_filter == patient.gsrn}>
                      {patient_full_name(patient)} ({patient.gsrn})
                    </option>
                  <% end %>
                </select>
              </div>
            </:group>

            <:group label="Patient Source">
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">Patient Source</label>
                <select
                  name="filters[source]"
                  class="w-full h-9 rounded-md border border-gray-300 px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
                >
                  <option value="" selected={@source_filter == ""}>All patients</option>
                  <option value="hospital" selected={@source_filter == "hospital"}>
                    Hospital only
                  </option>
                  <option value="medical_camp" selected={@source_filter == "medical_camp"}>
                    Medical camp only
                  </option>
                </select>
              </div>
            </:group>

            <:group label="Date Range">
              <.date_range_fields
                from_name="filters[date_from]"
                to_name="filters[date_to]"
                from_value={@date_from}
                to_value={@date_to}
              />
            </:group>
          </.filter_drawer>
        </div>

        <%!-- Active filter badges --%>
        <%= if @date_from != "" or @date_to != "" or @source_filter != "" or @gsrn_filter != "" do %>
          <div class="flex flex-wrap items-center gap-3 pt-1">
            <%= if @date_from != "" or @date_to != "" do %>
              <div class="flex items-center gap-2">
                <Heroicons.icon name="calendar" type="outline" class="h-4 w-4 text-blue-500" />
                <span class="text-xs text-blue-700 font-medium">
                  Showing records
                  <%= if @date_from != "" do %>
                    from <strong>{@date_from}</strong>
                  <% end %>
                  <%= if @date_to != "" do %>
                    to <strong>{@date_to}</strong>
                  <% end %>
                </span>
              </div>
            <% end %>
            <%= if @source_filter != "" do %>
              <div class="flex items-center gap-1.5">
                <Heroicons.icon name="funnel" type="outline" class="h-4 w-4 text-slate-500" />
                <span class="text-xs text-purple-700 font-medium">
                  <%= if @source_filter == "hospital" do %>
                    Hospital patients only • medical camp days excluded
                  <% else %>
                    Medical camp patients only
                  <% end %>
                </span>
              </div>
            <% end %>
            <%= if @gsrn_filter != "" do %>
              <div class="flex items-center gap-1.5">
                <Heroicons.icon name="identification" type="outline" class="h-4 w-4 text-emerald-500" />
                <span class="text-xs text-emerald-700 font-medium">
                  GSRN report for <strong>{@gsrn_filter}</strong>
                </span>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <%!-- ══════════════════════════════════════════════════════════════
           INVOICE VIEW — shown when an insurer is selected
           ══════════════════════════════════════════════════════════════ --%>
      <%= if @insurer_filter != "" or @gsrn_filter != "" do %>
        <div
          id="insurance-invoice"
          class="mx-auto max-w-4xl space-y-0 bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden print:shadow-none print:border-0 print:rounded-none"
        >
          <%!-- Logo bar --%>
          <div class="bg-white px-8 py-4 border-b border-gray-200 flex items-center justify-between">
            <div class="flex items-center gap-3">
              <img src="/images/logo.png" alt="GHCE Logo" class="h-12 w-auto" />
              Glocal Health Centre of Excellence
            </div>
            <div class="text-right text-xs text-gray-400">
              <p class="font-semibold text-gray-700 text-sm">Insurance Claim Statement</p>
              <p>Generated: {Calendar.strftime(Date.utc_today(), "%B %d, %Y")}</p>
              <%= if @date_from != "" or @date_to != "" do %>
                <p class="mt-0.5 text-blue-600 font-medium">
                  Period:
                  <%= if @date_from != "" do %>
                    {@date_from}
                  <% else %>
                    —
                  <% end %>
                  →
                  <%= if @date_to != "" do %>
                    {@date_to}
                  <% else %>
                    present
                  <% end %>
                </p>
              <% end %>
            </div>
          </div>

          <%= if @insurer_filter != "" do %>
            <div class="bg-blue-700 px-8 py-6 text-white">
              <div class="flex items-start justify-between">
                <div>
                  <p class="text-xs font-medium uppercase tracking-widest text-blue-200 mb-1">
                    Insurer
                  </p>
                  <h2 class="text-2xl font-bold">{@insurer_filter}</h2>
                </div>
                <%= if @insurer_summary != nil do %>
                  <div class="text-right">
                    <p class="text-xs text-blue-200 uppercase tracking-wide">Total Claim</p>
                    <p class="text-3xl font-bold mt-0.5 tabular-nums">
                      KSh {Number.Delimit.number_to_delimited(@insurer_summary.total_amount,
                        precision: 0
                      )}
                    </p>
                    <p class="text-xs text-blue-200 mt-1">
                      {@insurer_summary.patient_count} patient{if @insurer_summary.patient_count != 1,
                        do: "s",
                        else: ""} · {@insurer_summary.total_records} record{if @insurer_summary.total_records !=
                                                                                 1,
                                                                               do: "s",
                                                                               else: ""}
                    </p>
                  </div>
                <% end %>
              </div>
            </div>

            <%= if @source_filter == "hospital" do %>
              <div class="border-b border-amber-200 bg-amber-50 px-8 py-3 text-sm text-amber-900">
                <span class="font-semibold">Hospital only prefix:</span>
                {hospital_source_exclusion_label()}
              </div>
            <% end %>

            <%= if not Enum.empty?(@claim_data) do %>
              <% category_totals =
                @claim_data
                |> Enum.flat_map(& &1.records)
                |> report_category_totals() %>
              <div class="bg-gray-50 border-b border-gray-200 px-8 py-4">
                <p class="text-xs font-semibold uppercase tracking-wider text-gray-500 mb-3">
                  Summary by Category
                </p>
                <div class="flex flex-wrap gap-3">
                  <%= for {label, total, classes} <- category_totals do %>
                    <div class={"inline-flex flex-col items-center rounded-xl px-4 py-2 ring-1 #{classes}"}>
                      <span class="text-xs font-medium opacity-80">{label}</span>
                      <span class="text-sm font-bold tabular-nums mt-0.5">
                        KSh {Number.Delimit.number_to_delimited(total, precision: 0)}
                      </span>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>

            <%= if Enum.empty?(@claim_data) do %>
              <div class="flex flex-col items-center justify-center py-16 text-center">
                <Heroicons.icon name="document-text" type="outline" class="h-10 w-10 text-gray-300" />
                <p class="mt-3 text-sm text-gray-500">No records found for this insurer.</p>
              </div>
            <% else %>
              <%= for {entry, idx} <- Enum.with_index(@claim_data) do %>
                <% summary_rows = report_summary_rows(entry.records) %>
                <div class={[
                  "px-8 py-6",
                  if(rem(idx, 2) == 0, do: "bg-white", else: "bg-slate-50/60"),
                  "print:break-inside-avoid"
                ]}>
                  <div class="flex items-center justify-between mb-3">
                    <div class="flex items-center gap-3">
                      <div class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-blue-600 text-white font-bold text-xs">
                        {idx + 1}
                      </div>
                      <div>
                        <p class="font-semibold text-gray-900 text-base">
                          {patient_full_name(entry.patient)}
                        </p>
                        <div class="flex items-center gap-3 mt-0.5 text-xs text-gray-500">
                          <%= if entry.patient.gsrn do %>
                            <span class="font-mono">GSRN: {entry.patient.gsrn}</span>
                          <% end %>
                        </div>
                      </div>
                    </div>
                    <div class="text-right">
                      <p class="text-xs text-gray-400 uppercase tracking-wide">Patient Total</p>
                      <p class="text-xl font-bold text-emerald-700 tabular-nums">
                        KSh {Number.Delimit.number_to_delimited(entry.total_amount, precision: 0)}
                      </p>
                      <p class="text-xs text-gray-400 mt-0.5">
                        {length(entry.records)} item{if length(entry.records) != 1, do: "s", else: ""}
                      </p>
                    </div>
                  </div>

                  <%= if Enum.empty?(summary_rows) do %>
                    <p class="text-sm text-gray-400 italic">No records found.</p>
                  <% else %>
                    <div class="rounded-lg overflow-hidden border border-gray-200">
                      <table class="min-w-full divide-y divide-gray-200 text-sm">
                        <thead class="bg-gray-100">
                          <tr>
                            <th class="px-4 py-2.5 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                              Category
                            </th>
                            <th class="px-4 py-2.5 text-center text-xs font-semibold uppercase tracking-wider text-gray-500 w-24">
                              Items
                            </th>
                            <th class="px-4 py-2.5 text-right text-xs font-semibold uppercase tracking-wider text-gray-500 w-36">
                              Amount (KSh)
                            </th>
                            <th class="px-4 py-2.5 text-right text-xs font-semibold uppercase tracking-wider text-gray-500 w-28 print:hidden">
                              Action
                            </th>
                          </tr>
                        </thead>
                        <tbody class="divide-y divide-gray-100 bg-white">
                          <%= for row <- summary_rows do %>
                            <tr>
                              <td class="px-4 py-3">
                                <span class={"inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold #{row.badge}"}>
                                  {row.label}
                                </span>
                              </td>
                              <td class="px-4 py-3 text-center text-gray-500 tabular-nums">
                                {row.count} item{if row.count != 1, do: "s", else: ""}
                              </td>
                              <td class="px-4 py-3 text-right font-semibold text-gray-900 tabular-nums">
                                {Number.Delimit.number_to_delimited(row.total, precision: 0)}
                              </td>
                              <td class="px-4 py-3 text-right print:hidden">
                                <button
                                  type="button"
                                  phx-click="exclude_invoice_category"
                                  phx-value-type={row.type}
                                  phx-value-patient_id={entry.patient.id}
                                  phx-value-insurer_name={@insurer_filter}
                                  data-confirm={"Remove all #{String.downcase(row.label)} items from this invoice?"}
                                  class="inline-flex items-center rounded-lg border border-rose-200 bg-rose-50 px-3 py-1.5 text-xs font-semibold text-rose-700 hover:bg-rose-100"
                                >
                                  Remove
                                </button>
                              </td>
                            </tr>
                          <% end %>
                        </tbody>
                        <tfoot class="bg-gray-50 border-t border-gray-200">
                          <tr>
                            <td
                              colspan="3"
                              class="px-4 py-2.5 text-right text-sm font-semibold text-gray-700"
                            >
                              Patient Subtotal
                            </td>
                            <td class="px-4 py-2.5 text-right font-bold text-emerald-700 tabular-nums text-sm">
                              {Number.Delimit.number_to_delimited(entry.total_amount, precision: 0)}
                            </td>
                          </tr>
                        </tfoot>
                      </table>
                    </div>

                    <div class="mt-4 print:hidden">
                      <p class="text-xs font-semibold uppercase tracking-wider text-gray-500">
                        Included Items
                      </p>
                      <.invoice_record_table records={entry.records} />
                    </div>
                  <% end %>
                </div>
                <%= if idx < length(@claim_data) - 1 do %>
                  <div class="border-t border-dashed border-gray-300 mx-8" />
                <% end %>
              <% end %>

              <%= if @insurer_summary != nil do %>
                <div class="border-t-2 border-blue-700 bg-blue-700 px-8 py-5 text-white">
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-blue-100">
                        Grand Total — {@insurer_filter}
                      </p>
                      <p class="text-xs text-blue-300 mt-0.5">
                        {@insurer_summary.patient_count} patients · {@insurer_summary.total_records} records
                      </p>
                    </div>
                    <div class="text-right">
                      <p class="text-xs text-blue-300 uppercase tracking-wide">Total Amount Due</p>
                      <p class="text-3xl font-bold mt-0.5 tabular-nums">
                        KSh {Number.Delimit.number_to_delimited(@insurer_summary.total_amount,
                          precision: 0
                        )}
                      </p>
                    </div>
                  </div>
                </div>
              <% end %>
            <% end %>
          <% else %>
            <div class="bg-blue-700 px-8 py-6 text-white">
              <div class="flex items-start justify-between gap-6">
                <div>
                  <p class="text-xs font-medium uppercase tracking-widest text-blue-200 mb-1">
                    Patient GSRN
                  </p>
                  <h2 class="text-2xl font-bold">{@gsrn_filter}</h2>
                  <%= if @selected_patient != nil do %>
                    <p class="mt-2 text-sm text-blue-100">{patient_full_name(@selected_patient)}</p>
                    <div class="mt-1 flex flex-wrap gap-x-4 gap-y-1 text-xs text-blue-200">
                      <span :if={@selected_patient.email}>{@selected_patient.email}</span>
                      <span :if={@selected_patient.phone_number}>
                        {@selected_patient.phone_number}
                      </span>
                      <span :if={@selected_patient.gender}>{@selected_patient.gender}</span>
                    </div>
                  <% end %>
                </div>
                <%= if @patient_summary != nil do %>
                  <div class="text-right">
                    <p class="text-xs text-blue-200 uppercase tracking-wide">Total Claim</p>
                    <p class="text-3xl font-bold mt-0.5 tabular-nums">
                      KSh {Number.Delimit.number_to_delimited(@patient_summary.total_amount,
                        precision: 0
                      )}
                    </p>
                    <p class="text-xs text-blue-200 mt-1">
                      {length(@patient_summary.unique_insurers)} insurer{if length(
                                                                              @patient_summary.unique_insurers
                                                                            ) != 1,
                                                                            do: "s",
                                                                            else: ""} · {@patient_summary.total_records} record{if @patient_summary.total_records !=
                                                                                                                                     1,
                                                                                                                                   do:
                                                                                                                                     "s",
                                                                                                                                   else:
                                                                                                                                     ""}
                    </p>
                  </div>
                <% end %>
              </div>
            </div>

            <%= if @source_filter == "hospital" do %>
              <div class="border-b border-amber-200 bg-amber-50 px-8 py-3 text-sm text-amber-900">
                <span class="font-semibold">Hospital only prefix:</span>
                {hospital_source_exclusion_label()}
              </div>
            <% end %>

            <%= if @selected_patient != nil and not Enum.empty?(@patient_claim_data) do %>
              <div class="bg-gray-50 border-b border-gray-200 px-8 py-4">
                <p class="text-xs font-semibold uppercase tracking-wider text-gray-500 mb-3">
                  Summary by Insurer
                </p>
                <div class="flex flex-wrap gap-3">
                  <%= for entry <- @patient_claim_data do %>
                    <div class="inline-flex flex-col items-center rounded-xl bg-blue-50 px-4 py-2 text-blue-700 ring-1 ring-blue-200">
                      <span class="text-xs font-medium opacity-80">{entry.insurer_name}</span>
                      <span class="text-sm font-bold tabular-nums mt-0.5">
                        KSh {Number.Delimit.number_to_delimited(entry.total_amount, precision: 0)}
                      </span>
                    </div>
                  <% end %>
                </div>
              </div>

              <%= for {entry, idx} <- Enum.with_index(@patient_claim_data) do %>
                <% summary_rows = report_summary_rows(entry.records) %>
                <div class={[
                  "px-8 py-6",
                  if(rem(idx, 2) == 0, do: "bg-white", else: "bg-slate-50/60"),
                  "print:break-inside-avoid"
                ]}>
                  <div class="mb-3 flex items-center justify-between">
                    <div>
                      <p class="text-xs font-medium uppercase tracking-wide text-gray-400">
                        Insurer
                      </p>
                      <p class="text-base font-semibold text-gray-900">{entry.insurer_name}</p>
                    </div>
                    <div class="text-right">
                      <p class="text-xs text-gray-400 uppercase tracking-wide">Insurer Total</p>
                      <p class="text-xl font-bold text-emerald-700 tabular-nums">
                        KSh {Number.Delimit.number_to_delimited(entry.total_amount, precision: 0)}
                      </p>
                      <p class="text-xs text-gray-400 mt-0.5">
                        {length(entry.records)} item{if length(entry.records) != 1, do: "s", else: ""}
                      </p>
                    </div>
                  </div>

                  <%= if Enum.empty?(summary_rows) do %>
                    <p class="text-sm text-gray-400 italic">No records found.</p>
                  <% else %>
                    <div class="rounded-lg overflow-hidden border border-gray-200">
                      <table class="min-w-full divide-y divide-gray-200 text-sm">
                        <thead class="bg-gray-100">
                          <tr>
                            <th class="px-4 py-2.5 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                              Category
                            </th>
                            <th class="px-4 py-2.5 text-center text-xs font-semibold uppercase tracking-wider text-gray-500 w-24">
                              Items
                            </th>
                            <th class="px-4 py-2.5 text-right text-xs font-semibold uppercase tracking-wider text-gray-500 w-36">
                              Amount (KSh)
                            </th>
                            <th class="px-4 py-2.5 text-right text-xs font-semibold uppercase tracking-wider text-gray-500 w-28 print:hidden">
                              Action
                            </th>
                          </tr>
                        </thead>
                        <tbody class="divide-y divide-gray-100 bg-white">
                          <%= for row <- summary_rows do %>
                            <tr>
                              <td class="px-4 py-3">
                                <span class={"inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold #{row.badge}"}>
                                  {row.label}
                                </span>
                              </td>
                              <td class="px-4 py-3 text-center text-gray-500 tabular-nums">
                                {row.count} item{if row.count != 1, do: "s", else: ""}
                              </td>
                              <td class="px-4 py-3 text-right font-semibold text-gray-900 tabular-nums">
                                {Number.Delimit.number_to_delimited(row.total, precision: 0)}
                              </td>
                              <td class="px-4 py-3 text-right print:hidden">
                                <button
                                  type="button"
                                  phx-click="exclude_invoice_category"
                                  phx-value-type={row.type}
                                  phx-value-patient_id={@selected_patient.id}
                                  phx-value-insurer_name={entry.insurer_name}
                                  data-confirm={"Remove all #{String.downcase(row.label)} items from this invoice?"}
                                  class="inline-flex items-center rounded-lg border border-rose-200 bg-rose-50 px-3 py-1.5 text-xs font-semibold text-rose-700 hover:bg-rose-100"
                                >
                                  Remove
                                </button>
                              </td>
                            </tr>
                          <% end %>
                        </tbody>
                        <tfoot class="bg-gray-50 border-t border-gray-200">
                          <tr>
                            <td
                              colspan="3"
                              class="px-4 py-2.5 text-right text-sm font-semibold text-gray-700"
                            >
                              Insurer Subtotal
                            </td>
                            <td class="px-4 py-2.5 text-right font-bold text-emerald-700 tabular-nums text-sm">
                              {Number.Delimit.number_to_delimited(entry.total_amount, precision: 0)}
                            </td>
                          </tr>
                        </tfoot>
                      </table>
                    </div>

                    <div class="mt-4 print:hidden">
                      <p class="text-xs font-semibold uppercase tracking-wider text-gray-500">
                        Included Items
                      </p>
                      <.invoice_record_table records={entry.records} />
                    </div>
                  <% end %>
                </div>
                <%= if idx < length(@patient_claim_data) - 1 do %>
                  <div class="border-t border-dashed border-gray-300 mx-8" />
                <% end %>
              <% end %>

              <%= if @patient_summary != nil do %>
                <div class="border-t-2 border-blue-700 bg-blue-700 px-8 py-5 text-white">
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-blue-100">
                        Grand Total — {patient_full_name(@selected_patient)}
                      </p>
                      <p class="text-xs text-blue-300 mt-0.5">
                        {length(@patient_summary.unique_insurers)} insurers · {@patient_summary.total_records} records
                      </p>
                    </div>
                    <div class="text-right">
                      <p class="text-xs text-blue-300 uppercase tracking-wide">Total Amount Due</p>
                      <p class="text-3xl font-bold mt-0.5 tabular-nums">
                        KSh {Number.Delimit.number_to_delimited(@patient_summary.total_amount,
                          precision: 0
                        )}
                      </p>
                    </div>
                  </div>
                </div>
              <% end %>
            <% else %>
              <div class="flex flex-col items-center justify-center py-16 text-center">
                <Heroicons.icon name="document-text" type="outline" class="h-10 w-10 text-gray-300" />
                <p class="mt-3 text-sm text-gray-500">
                  No insurance records found for GSRN {@gsrn_filter}.
                </p>
              </div>
            <% end %>
          <% end %>
        </div>

        <%!-- ══════════════════════════════════════════════════════════════
           DEFAULT VIEW — all patients table (no insurer selected)
           ══════════════════════════════════════════════════════════════ --%>
      <% else %>
        <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 overflow-hidden">
          <.blank_state
            :if={Enum.empty?(@patients)}
            icon_path="M9 12.75L11.25 15 15 9.75M21 12c0 1.268-.63 2.39-1.593 3.068a3.745 3.745 0 01-1.043 3.296 3.745 3.745 0 01-3.296 1.043A3.745 3.745 0 0112 21c-1.268 0-2.39-.63-3.068-1.593a3.746 3.746 0 01-3.296-1.043 3.745 3.745 0 01-1.043-3.296A3.745 3.745 0 013 12c0-1.268.63-2.39 1.593-3.068a3.745 3.745 0 011.043-3.296 3.746 3.746 0 013.296-1.043A3.746 3.746 0 0112 3c1.268 0 2.39.63 3.068 1.593a3.746 3.746 0 013.296 1.043 3.746 3.746 0 011.043 3.296A3.745 3.745 0 0121 12z"
            title="No insurance patients found"
          >
            <:description_slot>
              <%= if @search != "" do %>
                No patients match "{@search}". Try a different query.
              <% else %>
                No insurance-tagged records exist yet.
              <% end %>
            </:description_slot>
            <:actions :if={@search != "" or count_active_filters(assigns) > 0}>
              <button phx-click="clear_filters" class="text-xs text-[#6667ab] hover:underline">
                Clear filters
              </button>
            </:actions>
          </.blank_state>
          <%= if !Enum.empty?(@patients) do %>
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                    Patient
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                    GSRN
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                    Email
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                    Insurer(s)
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                    Records
                  </th>
                  <th class="px-6 py-3"></th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 bg-white">
                <%= for patient <- @patients do %>
                  <% summary =
                    Insurance.patient_insurance_summary(patient.id, %{
                      date_from: @date_from,
                      date_to: @date_to,
                      source: @source_filter
                    }) %>
                  <tr
                    class="hover:bg-gray-50 transition-colors cursor-pointer"
                    phx-click={JS.navigate("/admin/insurance/#{patient.id}")}
                  >
                    <td class="px-6 py-4">
                      <div class="flex items-center gap-3">
                        <div class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-blue-100 text-blue-700 font-semibold text-sm">
                          {String.first(patient.first_name || "?")}
                        </div>
                        <div>
                          <p class="font-medium text-gray-900">{patient_full_name(patient)}</p>
                          <p class="text-xs text-gray-500">{patient.gender || "—"}</p>
                        </div>
                      </div>
                    </td>
                    <td class="px-6 py-4">
                      <span class="font-mono text-sm text-gray-700">{patient.gsrn || "—"}</span>
                    </td>
                    <td class="px-6 py-4">
                      <span class="text-sm text-gray-700">{patient.email || "—"}</span>
                    </td>
                    <td class="px-6 py-4">
                      <div class="flex flex-wrap gap-1">
                        <%= if Enum.empty?(summary.unique_insurers) do %>
                          <span class="text-sm text-gray-400">—</span>
                        <% else %>
                          <%= for insurer <- summary.unique_insurers do %>
                            <span class="inline-flex items-center rounded-full bg-blue-50 px-2.5 py-0.5 text-xs font-medium text-blue-700 ring-1 ring-inset ring-blue-700/10">
                              {insurer}
                            </span>
                          <% end %>
                        <% end %>
                      </div>
                    </td>
                    <td class="px-6 py-4">
                      <span class="inline-flex items-center rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-medium text-slate-700">
                        {summary.total_records} record{if summary.total_records != 1,
                          do: "s",
                          else: ""}
                      </span>
                    </td>
                    <td class="px-6 py-4 text-right">
                      <.link
                        navigate={"/admin/insurance/#{patient.id}"}
                        class="inline-flex items-center gap-1.5 rounded-lg px-2.5 py-1.5 text-sm font-medium text-blue-600 hover:bg-blue-50 transition-colors"
                      >
                        <Heroicons.icon name="eye" type="outline" class="h-4 w-4" /> View
                      </.link>
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
              class="px-6 pb-4"
            />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp hospital_source_exclusion_label do
    "Excluding medical camp activity from March 28-29, 2026"
  end
end
