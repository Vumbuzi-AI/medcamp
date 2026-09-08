#!/usr/bin/env python3
"""Helpers for removing whole Elixir function clauses / attributes by name.

Formatted Elixir (this repo runs `mix format`) puts every top-level clause of
a module at exactly two spaces of indentation, so a clause runs from its
`def`/`defp`/`@attr` line up to the next line that starts a new one at that
indentation. That makes whole-clause removal reliable without parsing.
"""
import re

CLAUSE_START = re.compile(r"^  (?:@|def |defp |defmacro |defmacrop )", re.M)


def clause_bounds(src, start_idx):
    """End offset of the clause beginning at `start_idx`."""
    nxt = CLAUSE_START.search(src, start_idx + 1)
    return nxt.start() if nxt else len(src)


def remove_clauses(src, pattern, expected=None, label=""):
    """Remove every top-level clause whose opening line matches `pattern`."""
    rx = re.compile(pattern, re.M)
    removed = 0
    while True:
        m = rx.search(src)
        if not m:
            break
        # Walk back to the start of the clause's own line.
        line_start = src.rfind("\n", 0, m.start()) + 1
        end = clause_bounds(src, line_start)
        src = src[:line_start] + src[end:]
        removed += 1
    if expected is not None and removed != expected:
        raise AssertionError(
            f"{label}: expected to remove {expected} clause(s) matching {pattern!r}, removed {removed}"
        )
    if expected is None and removed == 0:
        raise AssertionError(f"{label}: no clause matched {pattern!r}")
    return src, removed


def drop(src, fragment, label="", count=None):
    """Remove an exact fragment, asserting it was present."""
    n = src.count(fragment)
    if n == 0:
        raise AssertionError(f"{label}: fragment not found: {fragment[:80]!r}")
    if count is not None and n != count:
        raise AssertionError(f"{label}: expected {count} occurrences, found {n}: {fragment[:60]!r}")
    return src.replace(fragment, "")


def drop_block(src, pattern, label="", count=1, flags=re.S):
    """Remove a regex-delimited block, asserting the expected hit count."""
    rx = re.compile(pattern, flags)
    src, n = rx.subn("", src, count=count)
    if n != count:
        raise AssertionError(f"{label}: expected {count} block(s) for {pattern[:60]!r}, removed {n}")
    return src
