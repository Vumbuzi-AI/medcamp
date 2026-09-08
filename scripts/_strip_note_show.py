#!/usr/bin/env python3
"""Strip inpatient, admission-request, radiology, referral and payment
features out of the two doctor-note LiveViews, leaving the camp flow:
overview -> AI review -> lab work -> medication.
"""
import re
import sys

sys.path.insert(0, "scripts")
from elixir_surgery import remove_clauses, drop, drop_block  # noqa: E402


def strip_modal(src, action, label):
    """Remove a `<.modal :if={@live_action in [...:action...]}> ... </.modal>` block."""
    pat = (
        r"\n      <\.modal\n        :if=\{@live_action in \[:"
        + action
        + r"\][^\n]*\n(?:.*?\n)*?      </\.modal>\n"
    )
    return drop_block(src, pat, label=f"{label}: modal {action}", count=1, flags=0)


def strip_tab(src, tab_id, label):
    pat = r"\n *%\{\s*id: \"" + tab_id + r"\",(?:[^\n]*\n)*?[^\n]*\},?"
    out = re.sub(pat, "", src, count=1)
    if out == src:
        # single-line form
        pat2 = r"\n *%\{id: \"" + tab_id + r"\"[^\n]*\},?"
        out = re.sub(pat2, "", src, count=1)
    if out == src:
        raise AssertionError(f"{label}: tab {tab_id} not found")
    return out


# ---------------------------------------------------------------- doctor ----
P = "lib/medcamp_web/live/doctors_pages/note_live/show.ex"
s = open(P).read()
L = "doctor note show"

for alias_line in [
    "  alias Medcamp.RadiologyResults.RadiologyResult\n",
    "  alias Medcamp.Referrals\n",
    "  alias Medcamp.AdmissionRequests\n",
    "  alias Medcamp.PatientCharges\n",
    "  alias Medcamp.RadiologyResults\n",
    "  alias Medcamp.Inpatient\n",
]:
    s = drop(s, alias_line, L)

s = drop_block(
    s,
    r"  @admission_detail_live_actions \[\n(?:[^\n]*\n)*?  \]\n\n",
    label=f"{L}: admission_detail_live_actions",
)

# mount assigns
s = drop(s, "     |> assign(:inpatient_subtab, \"admission\")\n", L)

# handle_valid_params
s = drop_block(
    s,
    r"    inpatient_subtab = valid_inpatient_subtab\(params\[\"subtab\"\]\)\n",
    label=f"{L}: subtab param",
)
s = drop_block(
    s,
    r"\n    needs_current_admission\? =\n(?:[^\n]*\n)*?      if needs_current_admission\?, do: Inpatient\.get_current_admission\(patient\.id\), else: nil\n",
    label=f"{L}: current_admission",
)

for assign_name, fetch in [
    ("admission_requests", None),
    ("radiology_results", None),
    ("patient_charges", None),
    ("patient_charge_summary", None),
    ("referrals", None),
    ("admission_notes", None),
    ("continuation_notes", None),
    ("treatment_sheets", None),
    ("vital_records", None),
    ("discharge_summary", None),
    ("cadex_notes", None),
]:
    s = drop_block(
        s,
        r"     \|> assign\(\n       :" + assign_name + r",\n(?:[^\n]*\n)*?     \)\n",
        label=f"{L}: assign {assign_name}",
    )

s = drop(s, "     |> assign(:current_admission, current_admission)\n", L)
s = drop(s, "     |> assign(:inpatient_subtab, inpatient_subtab)\n", L)

# helpers
for pat, expected in [
    (r"^  defp inpatient_dataset\(", 1),
    (r"^  defp continuation_notes_for\(", 2),
    (r"^  defp treatment_sheets_for\(", 2),
    (r"^  defp vital_records_for\(", 2),
    (r"^  defp discharge_summary_for\(", 2),
    (r"^  defp cadex_notes_for\(", 2),
    (r"^  defp empty_charge_summary do", 1),
    (r"^  defp valid_inpatient_subtab\(", 3),
    (r"^  defp reload_patient_charges\(", 1),
]:
    s, _ = remove_clauses(s, pat, expected=expected, label=L)

s = s.replace(
    '       when tab in ~w(overview ai_review charges lab_work radiology medication inpatient admission referral),',
    "       when tab in ~w(overview ai_review lab_work medication),",
)

s = drop_block(
    s,
    r"    subtab = Map\.get\(assigns, :inpatient_subtab\) \|\| \"admission\"\n",
    label=f"{L}: subtab in path builder",
)
s = s.replace(
    'if base, do: base <> "?tab=#{tab}&subtab=#{subtab}", else: "#"',
    'if base, do: base <> "?tab=#{tab}", else: "#"',
)

s = drop(
    s,
    "    |> assign(:admission_request_for_line_items, nil)\n"
    "    |> assign(:admission_request_trigger_payment, nil)\n"
    "    |> assign(:line_item_for_trigger, nil)\n",
    L,
)

# apply_action clauses
for name, expected in [
    ("refer_patient", 1),
    ("admit_patient", 1),
    ("line_items", 2),
    ("trigger_payment", 2),
    ("trigger_payment_line_item", 2),
    ("trigger_patient_charge_payment", 1),
    ("new_admission", 1),
    ("new_continuation", 1),
    ("new_treatment", 1),
    ("edit_treatment", 1),
    ("new_vitals", 1),
    ("new_discharge", 1),
    ("new_cadex", 1),
    ("edit_cadex", 1),
]:
    s, _ = remove_clauses(
        s, r"^  defp apply_action\(socket, :" + name + r"[,)]", expected=expected, label=L
    )

# handle_event clauses
for name in [
    "change-inpatient-subtab",
    "delete_referral",
    "delete_radiology",
    "mark_admission_discharged",
    "delete_admission",
    "approve_patient_charge",
    "waive_patient_charge",
]:
    s, _ = remove_clauses(
        s, r'^  def handle_event\("' + name + r'"', expected=1, label=L
    )

# render: tabs
for tab in ["charges", "radiology", "inpatient", "admission", "referral"]:
    s = strip_tab(s, tab, L)

# render: sections
s = drop_block(
    s,
    r"\n      <\.radiology_results_card\n(?:[^\n]*\n)*?      />\n",
    label=f"{L}: radiology card",
)
s = drop_block(
    s,
    r"\n      <\.admission_requests_card\n(?:[^\n]*\n)*?      />\n",
    label=f"{L}: admission card",
)
s = drop_block(
    s,
    r"\n      \n?    <!-- NEW: Inpatient Section -->\n      <\.inpatient_section\n(?:[^\n]*\n)*?      />\n",
    label=f"{L}: inpatient section",
)

for action in [
    "request_radiology_test",
    "admit_patient",
    "line_items",
    "trigger_payment",
    "trigger_payment_line_item",
    "trigger_patient_charge_payment",
    "refer_patient",
    "new_admission",
    "new_continuation",
    "new_treatment",
    "edit_treatment",
    "new_vitals",
    "new_discharge",
    "new_cadex",
    "edit_cadex",
]:
    try:
        s = strip_modal(s, action, L)
    except AssertionError as e:
        print("  (skip)", e)

s = drop_block(s, r"\n      \n?    <!-- NEW: Inpatient Modals -->\n", label=f"{L}: modal comment")

open(P, "w").write(s)
print(f"{P}: rewritten")
