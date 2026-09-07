defmodule MedcampWeb.DutyRotaLive.Index do
  use MedcampWeb, :shared_live_view

  alias MedcampWeb.DutyRotaDocx

  @docx_file "SEPTEMBER  2026 GHC  STAFF DUTY ROTA.docx"

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    layout = layout_for_role(current_user && current_user.role)
    today = Date.utc_today()

    docx_path =
      :medcamp
      |> :code.priv_dir()
      |> Path.join("static/images")
      |> Path.join(@docx_file)
      |> to_string()

    rota =
      case DutyRotaDocx.parse(docx_path) do
        {:ok, data} -> {:ok, data}
        {:error, reason} -> {:error, reason}
      end

    {:ok,
     socket
     |> assign(:page_title, "Duty Rota")
     |> assign(:active_tab, :duty_rota)
     |> assign(:today, today)
     |> assign(:docx_url, "/images/" <> URI.encode(@docx_file))
     |> assign(:rota, rota), layout: layout}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="rounded-lg border border-gray-100 bg-white p-4 shadow-sm">
      <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div class="min-w-0">
          <.header class="text-[#373896]">
            Duty Rota
            <:subtitle :if={match?({:ok, _}, @rota)}>
              <%= case @rota do %>
                <% {:ok, data} -> %>
                  <span class="text-gray-500">
                    {Enum.join(Enum.take(data.headings, 2), " · ")}
                  </span>
              <% end %>
            </:subtitle>
          </.header>
        </div>

        <div class="shrink-0">
          <.link
            href={@docx_url}
            target="_blank"
            class="inline-flex items-center gap-2 rounded-lg bg-[#373896] px-3 py-2 text-sm font-semibold text-white hover:bg-[#2f307a]"
          >
            <Heroicons.icon name="arrow-down-tray" type="outline" class="h-4 w-4" /> Download DOCX
          </.link>
        </div>
      </div>

      <%= case @rota do %>
        <% {:error, reason} -> %>
          <div class="mt-6 rounded-lg border border-rose-100 bg-rose-50 p-4 text-sm text-rose-800">
            <p class="font-semibold">Could not load rota file.</p>
            <p class="mt-1 break-words text-rose-700">{inspect(reason)}</p>
          </div>
        <% {:ok, data} -> %>
          <div class="mt-6 flex flex-col gap-4">
            <div class="flex flex-wrap items-center gap-2">
              <span class="text-xs font-semibold uppercase tracking-wide text-gray-500">Key</span>
              <%= for item <- data.key do %>
                <span class={"inline-flex items-center gap-2 rounded-full px-3 py-1 text-xs font-semibold ring-1 ring-inset #{code_badge_classes(item.code)}"}>
                  <span class="rounded bg-white/70 px-1.5 py-0.5 font-mono text-[11px]">
                    {item.code}
                  </span>
                  {item.label}
                </span>
              <% end %>
              <span :if={data.prepared_by} class="ml-auto text-xs text-gray-500">
                {data.prepared_by}
              </span>
            </div>

            <div :if={data.activities != []} class="rounded-lg border border-gray-100 bg-gray-50 p-3">
              <div class="text-xs font-semibold uppercase tracking-wide text-gray-500">Notes</div>
              <ul class="mt-2 list-disc space-y-1 pl-6 text-sm text-gray-700">
                <li :for={note <- data.activities}>{note}</li>
              </ul>
            </div>

            <div class="overflow-x-auto rounded-lg border border-gray-200">
              <table class="min-w-max border-separate border-spacing-0 text-sm">
                <thead>
                  <tr class="bg-[#f7f7ff] text-[#373896]">
                    <th class="sticky top-0 z-10 border-b border-gray-200 bg-[#f7f7ff] px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide">
                      Staff
                    </th>
                    <th
                      :for={col <- data.columns}
                      class={[
                        "sticky top-0 z-10 border-b border-gray-200 px-2 py-2 text-center text-xs font-semibold uppercase tracking-wide",
                        day_column_header_classes(col, @today)
                      ]}
                    >
                      <div class={[
                        "leading-4",
                        if(today_column?(col, @today), do: "text-[#4d4eb2]", else: "text-gray-500")
                      ]}>
                        {col.day_label || ""}
                      </div>
                      <div class={[
                        "mt-1 inline-flex min-w-[2rem] items-center justify-center rounded-full px-2 py-1",
                        if(today_column?(col, @today),
                          do: "bg-white text-[#23246b] shadow-sm ring-1 ring-[#6667ab]/25",
                          else: "text-[#373896]"
                        )
                      ]}>
                        {col.date_label}
                      </div>
                      <div
                        :if={today_column?(col, @today)}
                        class="mt-2 inline-flex items-center rounded-full bg-[#4d4eb2] px-2 py-0.5 text-[10px] font-bold tracking-[0.18em] text-white shadow-sm"
                      >
                        Today
                      </div>
                    </th>
                  </tr>
                </thead>
                <tbody>
                  <tr :for={row <- data.staff_rows} class="odd:bg-white even:bg-gray-50">
                    <td class="whitespace-nowrap border-b border-gray-100 px-3 py-2 font-semibold text-gray-800">
                      {row.name}
                    </td>
                    <td
                      :for={{code, idx} <- Enum.with_index(row.codes)}
                      class={[
                        "border-b border-gray-100 px-2 py-2 text-center font-semibold",
                        day_column_cell_classes(Enum.at(data.columns, idx), @today)
                      ]}
                    >
                      <span class={[
                        "inline-flex h-7 w-7 items-center justify-center rounded-md text-xs ring-1 ring-inset",
                        code_cell_classes(code),
                        day_code_classes(Enum.at(data.columns, idx), @today)
                      ]}>
                        {code}
                      </span>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
      <% end %>
    </div>
    """
  end

  defp layout_for_role("doctor"), do: {MedcampWeb.Layouts, :doctor}
  defp layout_for_role("nurse"), do: {MedcampWeb.Layouts, :nurse}
  defp layout_for_role("reception"), do: {MedcampWeb.Layouts, :reception}
  defp layout_for_role("pharmacist"), do: {MedcampWeb.Layouts, :pharmacist}
  defp layout_for_role("labtechnician"), do: {MedcampWeb.Layouts, :lab}
  defp layout_for_role("radiologist"), do: {MedcampWeb.Layouts, :radiologist}
  defp layout_for_role("admin"), do: {MedcampWeb.Layouts, :admin}
  defp layout_for_role("support staff"), do: {MedcampWeb.Layouts, :support_staff}
  defp layout_for_role("inventory_manager"), do: {MedcampWeb.Layouts, :inventory_manager}
  defp layout_for_role(_), do: {MedcampWeb.Layouts, :shared}

  defp code_badge_classes("X"), do: "bg-emerald-50 text-emerald-700 ring-emerald-200"
  defp code_badge_classes("O"), do: "bg-slate-50 text-slate-700 ring-slate-200"
  defp code_badge_classes("D"), do: "bg-sky-50 text-sky-700 ring-sky-200"
  defp code_badge_classes("M"), do: "bg-amber-50 text-amber-800 ring-amber-200"
  defp code_badge_classes(_), do: "bg-gray-50 text-gray-700 ring-gray-200"

  defp today_column?(%{date: %Date{} = date}, %Date{} = today),
    do: Date.compare(date, today) == :eq

  defp today_column?(_, _), do: false

  defp day_column_header_classes(col, today) do
    if today_column?(col, today) do
      "bg-gradient-to-b from-[#dfe4ff] to-[#eef1ff] border-x-2 border-[#6670d8] shadow-[inset_0_-3px_0_0_#4d4eb2]"
    else
      "bg-[#f7f7ff]"
    end
  end

  defp day_column_cell_classes(col, today) do
    if today_column?(col, today) do
      "border-x-2 border-[#cfd5ff] bg-gradient-to-b from-[#f7f8ff] to-[#eef2ff]"
    end
  end

  defp day_code_classes(col, today) do
    if today_column?(col, today) do
      "scale-105 shadow-sm ring-[#6667ab]/25"
    end
  end

  defp code_cell_classes("X"), do: "bg-emerald-50 text-emerald-700 ring-emerald-200"
  defp code_cell_classes("O"), do: "bg-slate-50 text-slate-700 ring-slate-200"
  defp code_cell_classes("D"), do: "bg-sky-50 text-sky-700 ring-sky-200"
  defp code_cell_classes("M"), do: "bg-amber-50 text-amber-800 ring-amber-200"
  defp code_cell_classes(_), do: "bg-gray-50 text-gray-700 ring-gray-200"
end
