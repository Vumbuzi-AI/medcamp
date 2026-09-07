defmodule MedcampWeb.DoctorsPagePatientLive.DoctorProcedureTypeShow do
  use MedcampWeb, :doctor_live_view

  alias Medcamp.DoctorProcedures

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :doctor_procedures)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:total_count, 0)
     |> assign(:total_pages, 0)
     |> assign(:search, "")
     |> assign(:history, [])}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    stats =
      DoctorProcedures.get_procedure_type_stats_for_doctor!(
        socket.assigns.current_user.id,
        id
      )

    {:noreply,
     socket
     |> assign(:page_title, stats.procedure.name)
     |> assign(:procedure_stats, stats)
     |> assign_history(1)}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply, socket |> assign(:search, search) |> assign_history(1)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, assign_history(socket, page)}
  end

  defp assign_history(socket, page) do
    page = normalize_page(page)

    filters = %{
      search: socket.assigns.search,
      procedure_id: socket.assigns.procedure_stats.procedure.id
    }

    total_count =
      DoctorProcedures.count_doctor_procedures_for_doctor(
        socket.assigns.current_user.id,
        filters
      )

    total_pages = max(1, div(total_count + @per_page - 1, @per_page))
    page = min(page, total_pages)

    history =
      DoctorProcedures.list_doctor_procedures_for_doctor_paginated(
        socket.assigns.current_user.id,
        filters,
        page,
        @per_page
      )

    socket
    |> assign(:history, history)
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
  end

  defp normalize_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {value, ""} when value > 0 -> value
      _ -> 1
    end
  end

  defp normalize_page(page) when is_integer(page) and page > 0, do: page
  defp normalize_page(_), do: 1

  defp patient_name(patient) do
    [patient.first_name, patient.middle_name, patient.last_name]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" ")
  end

  defp money(nil), do: "—"
  defp money(amount), do: "KES #{amount}"

  defp format_datetime(nil), do: "Never"
  defp format_datetime(datetime), do: Calendar.strftime(datetime, "%d %b %Y, %H:%M")

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-5">
      <.link
        navigate={~p"/doctor/doctor_procedures/types"}
        class="inline-flex items-center gap-2 text-sm font-medium text-[#373896] hover:underline"
      >
        <Heroicons.icon name="arrow-left" type="outline" class="h-4 w-4" /> Back to procedure types
      </.link>

      <section class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex flex-col justify-between gap-4 sm:flex-row sm:items-start">
          <div>
            <p class="text-sm font-medium text-[#6667ab]">Procedure type</p>
            <h1 class="mt-1 text-2xl font-bold text-slate-900">{@procedure_stats.procedure.name}</h1>
            <p class="mt-2 max-w-3xl text-sm text-slate-600">
              {@procedure_stats.procedure.description}
            </p>
          </div>
          <span class="shrink-0 rounded-lg bg-[#f0f0ff] px-4 py-2 font-semibold text-[#373896]">
            {money(@procedure_stats.procedure.price)}
          </span>
        </div>
      </section>

      <section class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4" aria-label="Procedure statistics">
        <.summary_card label="Times done" value={@procedure_stats.performed_count} />
        <.summary_card label="People treated" value={@procedure_stats.patient_count} />
        <.summary_card label="Paid procedures" value={@procedure_stats.paid_count} />
        <.summary_card label="Amount collected" value={money(@procedure_stats.total_collected)} />
      </section>

      <section class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
        <div class="mb-4 flex flex-col justify-between gap-3 sm:flex-row sm:items-end">
          <div>
            <h2 class="text-lg font-semibold text-slate-900">Procedure history</h2>
            <p class="mt-1 text-sm text-slate-500">
              Last performed: {format_datetime(@procedure_stats.last_performed_at)}
            </p>
          </div>
          <form phx-change="search" class="w-full sm:max-w-sm">
            <.search_input name="search" value={@search} placeholder="Search patient name" />
          </form>
        </div>

        <.table id="procedure_type_history" rows={@history}>
          <:empty_state>
            <tr>
              <td colspan="6" class="px-6 py-12 text-center">
                <p class="font-semibold text-slate-900">
                  {if @search == "",
                    do: "This procedure has not been performed yet",
                    else: "No patients match your search"}
                </p>
              </td>
            </tr>
          </:empty_state>
          <:col :let={record} label="Patient">
            <span class="font-medium text-slate-900">{patient_name(record.patient)}</span>
          </:col>
          <:col :let={record} label="Date done">{format_datetime(record.inserted_at)}</:col>
          <:col :let={record} label="Payment type">{record.payment_type || "—"}</:col>
          <:col :let={record} label="Payment status">
            <span class={[
              "rounded-full px-2 py-1 text-xs font-medium",
              record.has_paid && "bg-green-100 text-green-800",
              !record.has_paid && "bg-red-100 text-red-800"
            ]}>
              {if record.has_paid, do: "Paid", else: "Not paid"}
            </span>
          </:col>
          <:col :let={record} label="Amount paid">
            <span class="font-medium text-slate-900">{money(record.total_amount_paid)}</span>
          </:col>
        </.table>

        <.pagination
          page={@page}
          total_pages={@total_pages}
          total_count={@total_count}
          per_page={@per_page}
          show_when_empty={true}
        />
      </section>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, required: true

  defp summary_card(assigns) do
    ~H"""
    <article class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
      <p class="text-sm font-medium text-slate-500">{@label}</p>
      <p class="mt-2 text-2xl font-bold text-slate-900">{@value}</p>
    </article>
    """
  end
end
