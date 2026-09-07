#!/usr/bin/env python3
# Replace the admin visits list's payment filters and column with the camp
# visit status, and swap the payment-mix chart on the admin and doctor
# dashboards for a visit-status mix.
import re
import sys

sys.path.insert(0, "scripts")
from elixir_surgery import drop, drop_block, remove_clauses  # noqa: E402

# ----------------------------------------------- admin visits list ---------
P = "lib/medcamp_web/live/admins_pages/patient_visit_live/index.ex"
s = open(P).read()
L = "admin visits"

s = s.replace(
    "    payment_type: nil,\n    has_paid: nil,\n", "    status: nil,\n"
)
s = s.replace(
    '      payment_type: nilify(params["payment_type"]),\n      has_paid: nilify(params["has_paid"]),\n',
    '      status: nilify(params["status"]),\n',
)
s = s.replace(
    "  @filter_keys ~w(search date_from date_to visit_type payment_type has_paid\n                  gender age_group doctor_id)a",
    "  @filter_keys ~w(search date_from date_to visit_type status\n                  gender age_group doctor_id)a",
)
s = s.replace(
    '      filter_chip(filters.payment_type, "payment_type", filters.payment_type),\n'
    '      filter_chip(filters.has_paid, "has_paid", has_paid_label(filters.has_paid)),\n',
    '      filter_chip(filters.status, "status", PatientVisit.status_label(filters.status)),\n',
)
s, _ = remove_clauses(s, r"^  defp has_paid_label\(", label=L)

s = drop_block(
    s,
    r'\n            <div>\n              <label class="block text-xs font-medium text-gray-600 mb-1">Payment Type</label>\n'
    r"(?:.*?\n)*?              </select>\n            </div>",
    label=f"{L}: payment type filter",
    flags=0,
)
s = s.replace(
    """            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Payment Status</label>
              <select
                name="has_paid"
                class="w-full rounded-lg border-gray-300 text-sm focus:border-[#6667ab] focus:ring-[#6667ab]"
              >
                <option value="">All</option>
                <option value="true" selected={@filters.has_paid == "true"}>Paid</option>
                <option value="false" selected={@filters.has_paid == "false"}>Unpaid</option>
              </select>
            </div>""",
    """            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Status</label>
              <select
                name="status"
                class="w-full rounded-lg border-gray-300 text-sm focus:border-[#6667ab] focus:ring-[#6667ab]"
              >
                <option value="">All</option>
                <%= for status <- PatientVisit.statuses() do %>
                  <option value={status} selected={@filters.status == status}>
                    {PatientVisit.status_label(status)}
                  </option>
                <% end %>
              </select>
            </div>""",
)
s = s.replace(
    """        <:col :let={pv} label="Payment">
          <div class="py-2">
            <p class="text-sm text-gray-700">{pv.payment_type || "—"}</p>
            <span class={[
              "inline-block mt-1 px-1.5 py-0.5 text-xs rounded-full font-medium",
              if(pv.has_paid, do: "bg-green-100 text-green-700", else: "bg-red-100 text-red-700")
            ]}>
              {if pv.has_paid, do: "Paid", else: "Unpaid"}
            </span>
          </div>
        </:col>""",
    """        <:col :let={pv} label="Status">
          <div class="py-2">
            <span class="inline-block px-1.5 py-0.5 text-xs rounded-full font-medium bg-[#e7e7ff] text-[#373896]">
              {PatientVisit.status_label(pv.status)}
            </span>
          </div>
        </:col>""",
)

if "alias Medcamp.PatientVisits.PatientVisit" not in s:
    s = s.replace(
        "  alias Medcamp.PatientVisits\n",
        "  alias Medcamp.PatientVisits\n  alias Medcamp.PatientVisits.PatientVisit\n",
        1,
    )

leftovers = [l for l in s.splitlines() if "has_paid" in l or "payment_type" in l]
assert not leftovers, leftovers
open(P, "w").write(s)
print(f"{P}: payment filters -> status")

# ------------------------------------------------------- dashboards --------
for P, L in [
    ("lib/medcamp_web/live/admins_pages/dashboard_live/index.ex", "admin dashboard"),
    ("lib/medcamp_web/live/doctors_pages/doctor_dashboard_live/index.ex", "doctor dashboard"),
]:
    s = open(P).read()
    s = s.replace("    payment_types = build_payment_types(visits)\n", "    visit_statuses = build_visit_statuses(visits)\n")
    s = s.replace("    |> assign(:payment_types, payment_types)\n", "    |> assign(:visit_statuses, visit_statuses)\n")
    s = s.replace("payment_types={@payment_types}", "payment_types={@visit_statuses}")
    s = s.replace(
        "  defp build_payment_types(visits) do",
        "  # Camp visits carry no payment, so the old payment-mix chart now shows\n"
        "  # where patients are in the camp flow instead.\n"
        "  defp build_visit_statuses(visits) do",
    )
    s = s.replace(
        'Enum.group_by(fn v -> v.payment_type || "Unspecified" end)',
        "Enum.group_by(fn v -> Medcamp.PatientVisits.PatientVisit.status_label(v.status) end)",
    )
    leftovers = [l for l in s.splitlines() if "payment_type" in l or "build_payment_types" in l]
    assert not leftovers, (P, leftovers)
    open(P, "w").write(s)
    print(f"{P}: payment mix -> visit status mix")
