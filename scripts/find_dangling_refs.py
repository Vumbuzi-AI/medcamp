#!/usr/bin/env python3
"""Find references in surviving code to modules that no longer exist.

Without a compiler available this is the substitute: collect every module
defined in the tree, then flag every `Medcamp*`/`MedcampWeb*` alias or fully
qualified call that does not resolve to one of them.
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)

SRC_DIRS = ["lib", "test", "priv/repo"]

defined = set()
files = []
for d in SRC_DIRS:
    for dirpath, _, filenames in os.walk(d):
        for fn in filenames:
            if fn.endswith((".ex", ".exs", ".heex")):
                files.append(os.path.join(dirpath, fn))

for f in files:
    for m in re.finditer(r"^\s*defmodule\s+([A-Z][\w.]*)", open(f, encoding="utf8").read(), re.M):
        defined.add(m.group(1))

# Modules that come from dependencies, not this repo.
EXTERNAL_PREFIXES = (
    "Ecto", "Phoenix", "Plug", "Swoosh", "Timex", "Poison", "Jason", "Finch",
    "Scrivener", "Sentry", "HTTPoison", "HTTPotion", "Bcrypt", "Floki",
    "NimbleCSV", "Number", "Decimal", "DNSCluster", "Telemetry", "Logger",
    "Application", "Enum", "Map", "String", "Date", "DateTime", "Integer",
    "Float", "Kernel", "Task", "Process", "Registry", "Supervisor", "Agent",
    "GenServer", "File", "Path", "System", "URI", "Base", "Regex", "MapSet",
    "Keyword", "List", "Tuple", "Access", "Stream", "IO", "Code", "Module",
    "Exception", "Range", "Calendar", "NaiveDateTime", "Time", "Version",
    "Mix", "ExUnit", "Req", "Tesla", "Oban", "Quantum", "Crontab", "Heroicons",
)

# Runtime process names and generated modules that are never `defmodule`d here.
NOT_MODULES = {
    "Medcamp.Repo", "Medcamp.PubSub", "Medcamp.Finch", "Medcamp.Supervisor",
    "Medcamp.TaskSupervisor", "Medcamp.BalanceBatchInventory",
}

pattern = re.compile(r"\b(Medcamp(?:Web)?(?:\.[A-Z][\w]*)+)")

problems = {}
by_file = {}
for f in files:
    text = open(f, encoding="utf8").read()
    for lineno, line in enumerate(text.splitlines(), 1):
        stripped = line.strip()
        if stripped.startswith("#"):
            continue
        for m in pattern.finditer(line):
            mod = m.group(1)
            if mod in defined or mod in NOT_MODULES:
                continue
            if mod.startswith("Medcamp.Repo.Migrations."):
                continue
            # `Foo.Bar.function_name` - trim trailing lowercase segments
            parts = mod.split(".")
            while len(parts) > 1 and parts[-1][0].isupper() is False:
                parts.pop()
            trimmed = ".".join(parts)
            if trimmed in defined or trimmed in NOT_MODULES:
                continue
            # Struct/alias nesting: `Medcamp.Drugs.Drug` defined inside its file
            if any(d.startswith(mod + ".") for d in defined):
                continue
            if mod.startswith(EXTERNAL_PREFIXES):
                continue
            problems.setdefault(mod, []).append(f"{f}:{lineno}")
            by_file.setdefault(f, set()).add(mod)

if "--by-file" in sys.argv:
    for f in sorted(by_file, key=lambda x: -len(by_file[x])):
        print(f"{f}  ({len(by_file[f])})")
        print("    " + ", ".join(sorted(by_file[f])))
    print(f"\n{len(by_file)} files, {len(problems)} unresolved modules")
    sys.exit(1 if problems else 0)

for mod in sorted(problems):
    locs = problems[mod]
    print(f"{mod}  ({len(locs)} refs)")
    for l in locs[:6]:
        print(f"    {l}")
    if len(locs) > 6:
        print(f"    ... {len(locs) - 6} more")

print(f"\n{len(problems)} unresolved modules")
sys.exit(1 if problems else 0)
