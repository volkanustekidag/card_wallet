#!/usr/bin/env python3
"""Counts store metadata fields in docs/store/**.md against their limits.

Every field is a fenced ```text block under a heading like

    #### App Store — Subtitle (≤30)
    #### App Store — Keywords (≤100 bytes)

and belongs to the closest `## <locale>` heading above it. Characters are
Unicode code points (what both consoles count). App Store keywords are
limited in UTF-8 bytes, so Turkish/Polish letters count double there.

Usage:
  python3 tools/check_store_text.py docs/store/v2.1/listing.md          # report
  python3 tools/check_store_text.py --write docs/store/v2.1/*.md        # refresh tables

With --write, the table between <!-- lengths:start --> and
<!-- lengths:end --> in each file is regenerated. Exit code 1 if any
field is over its limit.
"""

import re
import sys
from pathlib import Path

FIELD_RE = re.compile(r"^#### (?P<label>.+?) \(≤(?P<limit>\d+)(?P<bytes> bytes)?\)\s*$")
LOCALE_RE = re.compile(r"^## (?P<locale>[a-z]{2}-[A-Z]{2})\b")
START, END = "<!-- lengths:start -->", "<!-- lengths:end -->"


def fields(text):
    locale, field = None, None
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if m := LOCALE_RE.match(line):
            locale, field = m["locale"], None
        elif m := FIELD_RE.match(line):
            field = (m["label"], int(m["limit"]), bool(m["bytes"]))
        elif line.strip() == "```text" and field and locale:
            body = []
            i += 1
            while lines[i].strip() != "```":
                body.append(lines[i])
                i += 1
            value = "\n".join(body)
            label, limit, in_bytes = field
            size = len(value.encode("utf-8")) if in_bytes else len(value)
            yield locale, label, size, limit, in_bytes, value
            field = None
        i += 1


def table(rows):
    out = ["| Dil | Alan | Uzunluk | Sınır | Durum |", "|---|---|---:|---:|---|"]
    for locale, label, size, limit, in_bytes, _ in rows:
        unit = " bayt" if in_bytes else ""
        ok = "✅" if size <= limit else "❌ AŞIYOR"
        out.append(f"| {locale} | {label} | {size}{unit} | {limit}{unit} | {ok} |")
    return "\n".join(out)


def main(argv):
    write = "--write" in argv
    paths = [Path(p) for p in argv if p != "--write"]
    failed = False
    for path in paths:
        text = path.read_text(encoding="utf-8")
        rows = list(fields(text))
        if not rows:
            continue
        over = [r for r in rows if r[2] > r[3]]
        failed |= bool(over)
        rendered = table(rows)
        if write and START in text and END in text:
            head, rest = text.split(START, 1)
            _, tail = rest.split(END, 1)
            path.write_text(f"{head}{START}\n{rendered}\n{END}{tail}", encoding="utf-8")
        print(f"{path}: {len(rows)} alan, {len(over)} sınır aşımı")
        for locale, label, size, limit, _, _ in over:
            print(f"  ❌ {locale} {label}: {size} > {limit}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
