"""Trích phần dành cho người tham gia trong User Guide sang Markdown.

Bỏ phần staff portal và phần dành cho người duyệt: chỉ những gì người tham
gia cần mới được đưa lên kệ.
"""
import sys

import docx
from docx.table import Table
from docx.text.paragraph import Paragraph

KEEP = (
    "Participant app:",
    "Privacy and data",
    "Troubleshooting",
)

src, out = sys.argv[1], sys.argv[2]
doc = docx.Document(src)


def blocks(document):
    body = document.element.body
    for child in body.iterchildren():
        if child.tag.endswith("}p"):
            yield Paragraph(child, document)
        elif child.tag.endswith("}tbl"):
            yield Table(child, document)


lines, keep = [], False
for block in blocks(doc):
    if isinstance(block, Paragraph):
        style, text = block.style.name, block.text.strip()
        if style == "Heading 2":
            keep = text.startswith(KEEP)
            if keep:
                lines += ["", f"## {text}", ""]
            continue
        if not keep or not text:
            continue
        if style.startswith("Heading"):
            lines += ["", f"### {text}", ""]
        elif "List" in style:
            lines.append(f"- {text}")
        else:
            lines += [text, ""]
    elif keep:
        rows = [[c.text.strip().replace("\n", " ") for c in r.cells] for r in block.rows]
        header, body_rows = rows[0], rows[1:]
        for row in body_rows:
            pairs = [f"{h}: {v}" for h, v in zip(header, row) if v]
            lines.append("- " + "; ".join(pairs))
        lines.append("")

text = "\n".join(lines).strip() + "\n"
while "\n\n\n" in text:
    text = text.replace("\n\n\n", "\n\n")
with open(out, "w", encoding="utf-8") as f:
    f.write(text)
print(f"{len(text.split())} words -> {out}")
