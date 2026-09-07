defmodule MedcampWeb.StockRequests.Print do
  @moduledoc """
  Printable donation/disposal note, styled after the standard Counter
  Requisition and Issue Voucher. Rendered inside a `<.modal>` on whichever
  page already has the disposal loaded - no separate print route needed.
  """

  use MedcampWeb, :html

  @doc "The voucher document itself; callers supply their own modal/print button."
  def voucher(assigns) do
    ~H"""
    <div
      id="donation-note"
      class="mx-auto max-w-4xl bg-white px-10 py-8 shadow-sm print:shadow-none"
      style="max-width: 210mm;"
    >
      {status_banner(assigns)}

      <div class="text-center">
        <img src="/images/logo.png" alt="GHCE Logo" class="mx-auto h-16 w-16" />
        <h1 class="mt-3 text-lg font-bold tracking-wide text-gray-900">
          COUNTER REQUISITION AND ISSUE VOUCHER
        </h1>
        <p class="mt-1 text-xs text-gray-400">Voucher No. {@disposal.id}</p>
      </div>

      <div class="mt-6 space-y-2 text-sm">
        <div class="flex items-baseline gap-2">
          <span class="shrink-0 font-semibold text-gray-700">ISSUE POINT</span>
          <span class="flex-1 border-b border-dotted border-gray-500 pb-0.5">
            {issue_point(@disposal)}
          </span>
        </div>
        <div class="flex items-baseline gap-2">
          <span class="shrink-0 font-semibold text-gray-700">
            POINT OF USE
          </span>
          <span class="flex-1 border-b border-dotted border-gray-500 pb-0.5">
            {@disposal.reason || ""}
          </span>
        </div>
      </div>

      <div class="mt-6 overflow-x-auto">
        <table id="voucher-items" class="w-full border-collapse text-xs">
          <thead>
            <tr>
              <th class="w-8 border-2 border-gray-800 px-1.5 py-1.5 font-bold">No.</th>
              <th class="border-2 border-gray-800 px-2 py-1.5 font-bold">Item Description</th>
              <th class="border-2 border-gray-800 px-2 py-1.5 font-bold">Unit of Issue</th>
              <th class="border-2 border-gray-800 px-2 py-1.5 font-bold">Quantity Requested</th>
              <th class="border-2 border-gray-800 px-2 py-1.5 font-bold">Quantity Issued</th>
              <th class="border-2 border-gray-800 px-2 py-1.5 font-bold">Remarks</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={{item, index} <- Enum.with_index(@disposal.items, 1)}>
              <td class="border-2 border-gray-800 px-1.5 py-1.5 text-center">{index}</td>
              <td class="border-2 border-gray-800 px-2 py-1.5">{item.entity_name}</td>
              <td class="border-2 border-gray-800 px-2 py-1.5">{item.uom || "—"}</td>
              <td class="border-2 border-gray-800 px-2 py-1.5 text-right tabular-nums">
                {item.quantity}
              </td>
              <td class="border-2 border-gray-800 px-2 py-1.5 text-right tabular-nums">
                {if @disposal.status == "approved", do: item.quantity, else: "—"}
              </td>
              <td class="border-2 border-gray-800 px-2 py-1.5">{item.notes || "—"}</td>
            </tr>
            <tr :if={@disposal.items == []}>
              <td colspan="6" class="border-2 border-gray-800 px-2 py-6 text-center text-gray-500">
                No items on this request.
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="mt-8">
        <table class="w-full table-fixed text-sm">
          <tbody>
            <tr>
              {signoff_cell(assigns, "Requested by", @disposal.requested_by.name)}
              {signoff_cell(assigns, "Designation", designation(@disposal.requested_by))}
              {signoff_cell(assigns, "Signature", nil)}
              {signoff_cell(assigns, "Date", format_date(@disposal.date))}
            </tr>
            <tr>
              {signoff_cell(assigns, "Issued by", issued_by_name(@disposal))}
              {signoff_cell(
                assigns,
                "Designation",
                @disposal.status == "approved" && designation(@disposal.approved_by)
              )}
              {signoff_cell(assigns, "Sign", nil)}
              {signoff_cell(assigns, "Date", issued_at(@disposal))}
            </tr>
            <tr>
              {signoff_cell(assigns, "Received by", nil)}
              {signoff_cell(assigns, "Designation", nil)}
              {signoff_cell(assigns, "Sign", nil)}
              {signoff_cell(assigns, "Date", nil)}
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  # One label + blank-line cell of the sign-off table.
  defp signoff_cell(assigns, label, value) do
    assigns = assign(assigns, label: label, value: value || " ")

    ~H"""
    <td class="w-1/4 px-3 py-3 align-top">
      <p class="text-xs font-semibold text-gray-700">{@label}</p>
      <p class="mt-1.5 border-b border-dotted border-gray-500 pb-0.5">{@value}</p>
    </td>
    """
  end

  defp status_banner(assigns) do
    {classes, message} =
      case assigns.disposal.status do
        "draft" ->
          {"bg-slate-50 text-slate-700 border-slate-200",
           "DRAFT — this request has not been submitted for approval. Nothing has been issued yet."}

        "pending" ->
          {"bg-amber-50 text-amber-800 border-amber-200",
           "PENDING APPROVAL — nothing has been issued yet. Quantities below are what was requested, not what has left the building."}

        "rejected" ->
          {"bg-red-50 text-red-800 border-red-200",
           "REJECTED — this request was not approved. No stock was issued."}

        "approved" ->
          {"bg-emerald-50 text-emerald-800 border-emerald-200",
           "APPROVED — the quantities below were issued and deducted from stock."}

        _ ->
          {"bg-slate-50 text-slate-700 border-slate-200", nil}
      end

    assigns = assign(assigns, :classes, classes) |> assign(:message, message)

    ~H"""
    <div
      :if={@message}
      class={["mb-4 rounded-lg border px-4 py-2 text-sm font-medium print:hidden", @classes]}
    >
      {@message}
    </div>
    """
  end

  defp issue_point(%{items: [%{entity_type: type} | _]}) do
    case type do
      "drug_batch" -> "Pharmacy Store, Glocal Health Centre of Excellence"
      "lab_allocation" -> "Laboratory Store, Glocal Health Centre of Excellence"
      "nursing_allocation" -> "Nursing Store, Glocal Health Centre of Excellence"
      "inventory_received" -> "Central Store, Glocal Health Centre of Excellence"
      _ -> "Glocal Health Centre of Excellence"
    end
  end

  defp issue_point(_), do: "Glocal Health Centre of Excellence"

  # System role stands in for a real job title - the closest thing on record.
  defp designation(%{role: role}) when is_binary(role), do: Phoenix.Naming.humanize(role)
  defp designation(_), do: nil

  defp issued_by_name(%{status: "approved", approved_by: %{name: name}}), do: name
  defp issued_by_name(_), do: nil

  defp issued_at(%{status: "approved", approved_at: %DateTime{} = at}),
    do: format_date(DateTime.to_date(at))

  defp issued_at(_), do: nil

  defp format_date(%Date{} = date), do: Calendar.strftime(date, "%d %b %Y")
end
