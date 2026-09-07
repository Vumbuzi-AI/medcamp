#!/usr/bin/env python3
"""Tag-balance check for the HEEx inside ~H sigils and .html.heex files.

`scripts/check_syntax.exs` parses Elixir but treats a ~H body as an opaque
string, so a template left with an unclosed `<div>` still parses. Phoenix's
own HEEx engine would catch it, but that needs the dependency tree. This is
the cheap middle ground: pair up every opening and closing tag and report
mismatches.

It understands HTML elements, void elements, self-closing tags, function
components (`<.modal>`), remote components (`<Heroicons.icon>`) and slots
(`<:actions>`), and skips `<%= ... %>` / `<%!-- ... --%>` blocks.

    python3 scripts/check_heex.py
"""
import re
import sys
from pathlib import Path

VOID = {
    "area", "base", "br", "col", "embed", "hr", "img", "input", "link",
    "meta", "param", "source", "track", "wbr", "path", "circle", "rect",
    "line", "polygon", "polyline", "ellipse", "stop", "use",
}

# `<%= ... %>`, `<% ... %>`, `<%!-- ... --%>` and HTML comments.
EEX = re.compile(r"<%!--.*?--%>|<%.*?%>|<!--.*?-->", re.S)
TAG = re.compile(r"<(/?)([A-Za-z][\w.\-]*|\.[\w.]+|:[\w\-]+)((?:[^<>\"']|\"[^\"]*\"|'[^']*')*?)(/?)>", re.S)
SIGIL = re.compile(r'~H"""\n(.*?)\n(\s*)"""', re.S)


def check(template, origin, problems):
    stack = []
    for m in TAG.finditer(EEX.sub(" ", template)):
        closing, name, attrs, self_closing = m.groups()
        if self_closing or (not closing and name.lower() in VOID):
            continue
        line = template.count("\n", 0, m.start()) + 1
        if closing:
            if not stack:
                problems.append(f"{origin}: stray </{name}> near template line {line}")
                return
            open_name, open_line = stack.pop()
            if open_name != name:
                problems.append(
                    f"{origin}: <{open_name}> (line {open_line}) closed by </{name}> (line {line})"
                )
                return
        else:
            stack.append((name, line))
    for name, line in stack:
        problems.append(f"{origin}: <{name}> opened at template line {line} is never closed")


def main():
    problems = []

    for path in sorted(Path("lib").rglob("*.ex")):
        source = path.read_text(encoding="utf8")
        for m in SIGIL.finditer(source):
            start_line = source.count("\n", 0, m.start()) + 1
            check(m.group(1), f"{path}:{start_line} (~H)", problems)

    for path in sorted(Path("lib").rglob("*.heex")):
        check(path.read_text(encoding="utf8"), str(path), problems)

    for problem in problems:
        print(problem)
    print(f"{len(problems)} unbalanced templates")
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
