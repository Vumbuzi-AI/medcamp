#!/usr/bin/env python3
"""Second pass on the doctor-note show LiveView: the leftovers that the
first pass could not anchor (multi-action modals, the charges tab body,
the referrals card and the tab handler's subtab).
"""
import sys

sys.path.insert(0, "scripts")
from elixir_surgery import drop, drop_block  # noqa: E402

P = "lib/medcamp_web/live/doctors_pages/note_live/show.ex"
s = open(P).read()
L = "doctor note show (2)"

s = drop(
    s,
    '    subtab = if tab == "inpatient", do: socket.assigns.inpatient_subtab, else: "admission"\n',
    L,
)
s = s.replace(
    '    path = "#{socket.assigns.note_path}?tab=#{tab}&subtab=#{subtab}"',
    '    path = "#{socket.assigns.note_path}?tab=#{tab}"',
)

# The whole charges tab body.
s = drop_block(
    s,
    r'\n      <div :if=\{@current_tab == "charges"\}>\n(?:.*?\n)*?      </div>\n(?=\n      <\.lab)',
    label=f"{L}: charges tab",
    flags=0,
)

s = drop_block(
    s,
    r"\n      <\.referrals_card\n(?:[^\n]*\n)*?      />",
    label=f"{L}: referrals card",
    flags=0,
)

for action_list, mod in [
    ("[:new_treatment, :edit_treatment]", "TreatmentFormComponent"),
    ("[:new_cadex, :edit_cadex]", "CadexFormComponent"),
]:
    pat = (
        r"\s*<\.modal\n        :if=\{@live_action in "
        + action_list.replace("[", r"\[").replace("]", r"\]")
        + r"\}\n(?:.*?\n)*?      </\.modal>\n"
    )
    s = drop_block(s, pat, label=f"{L}: modal {mod}", flags=0)

open(P, "w").write(s)
print(f"{P}: second pass done")
