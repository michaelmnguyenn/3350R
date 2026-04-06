import re
from datetime import datetime, timezone
from pathlib import Path

from docx import Document
from docx.oxml.ns import qn
from docx.shared import Inches, Pt
from docx.enum.text import WD_ALIGN_PARAGRAPH


ROOT = Path(__file__).resolve().parent
MARKDOWN_PATH = ROOT / "report_text.md"
OUTPUT_PATH = ROOT / "ECON3350_Research_Report.docx"


def set_default_style(document: Document) -> None:
    style = document.styles["Normal"]
    style.font.name = "Times New Roman"
    style.font.size = Pt(12)


def math_segments(text: str) -> list[tuple[str, bool, bool]]:
    """
    Parse a math expression into (segment_text, is_subscript, is_superscript).

    Handles LaTeX-style notation:
      x_t        → x normal, t subscript
      x_{T+1}    → x normal, T+1 subscript
      x^2        → x normal, 2 superscript
      x^{abc}    → x normal, abc superscript

    Unicode sub/superscript characters (₁ ² etc.) are left as-is in normal runs.
    """
    segments: list[tuple[str, bool, bool]] = []
    i = 0
    base = ""
    n = len(text)

    while i < n:
        c = text[i]

        if c == '_' and i + 1 < n:
            if base:
                segments.append((base, False, False))
                base = ""
            i += 1
            if i < n and text[i] == '{':
                try:
                    end = text.index('}', i + 1)
                    segments.append((text[i + 1:end], True, False))
                    i = end + 1
                except ValueError:
                    base += '_'
            else:
                # Single-character subscript
                segments.append((text[i], True, False))
                i += 1

        elif c == '^' and i + 1 < n:
            if base:
                segments.append((base, False, False))
                base = ""
            i += 1
            if i < n and text[i] == '{':
                try:
                    end = text.index('}', i + 1)
                    segments.append((text[i + 1:end], False, True))
                    i = end + 1
                except ValueError:
                    base += '^'
            else:
                segments.append((text[i], False, True))
                i += 1

        else:
            base += c
            i += 1

    if base:
        segments.append((base, False, False))
    return segments


def add_runs(paragraph, raw_text: str) -> None:
    """
    Parse raw_text and add appropriately formatted runs to paragraph.

    Recognised markers:
      **text**   → bold run
      `expr`     → italic run(s) with Word subscript/superscript where _x or _{} appear
      plain text → normal run (inherits document style)
    """
    # Split into: bold spans, math spans, plain text
    pattern = re.compile(r'(\*\*[^*]+\*\*|`[^`]+`)')
    parts = pattern.split(raw_text)

    for part in parts:
        if not part:
            continue

        if part.startswith('**') and part.endswith('**'):
            run = paragraph.add_run(part[2:-2])
            run.bold = True

        elif part.startswith('`') and part.endswith('`'):
            inner = part[1:-1]
            for seg_text, is_sub, is_sup in math_segments(inner):
                run = paragraph.add_run(seg_text)
                run.italic = True
                if is_sub:
                    run.font.subscript = True
                elif is_sup:
                    run.font.superscript = True

        else:
            paragraph.add_run(part)


def format_cell(cell, raw_text: str, bold_header: bool = False) -> None:
    """
    Replace the content of a table cell with math-aware formatted runs.
    Clears any existing runs before writing.
    """
    para = cell.paragraphs[0]
    # Remove all existing w:r (run) elements from the paragraph XML
    for elem in list(para._p.findall(qn('w:r'))):
        para._p.remove(elem)
    add_runs(para, raw_text)
    if bold_header:
        for run in para.runs:
            run.bold = True


def add_title_page(document: Document) -> None:
    p = document.add_heading("ECON3350 Research Report", level=1)
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER

    sub = document.add_paragraph("Applied Econometrics for Macroeconomics and Finance")
    sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    for run in sub.runs:
        run.font.size = Pt(14)

    date_p = document.add_paragraph("17 April 2026")
    date_p.alignment = WD_ALIGN_PARAGRAPH.CENTER

    document.add_page_break()


def add_markdown_table(document: Document, rows: list[str]) -> None:
    def split_row(row: str) -> list[str]:
        return [cell.strip() for cell in row.strip().strip("|").split("|")]

    data = [split_row(r) for r in rows]
    if len(data) < 2:
        return
    header = data[0]
    body = data[2:]  # row index 1 is the markdown separator (---|---:| etc.)

    table = document.add_table(rows=1, cols=len(header))
    table.style = "Table Grid"

    # Header row — bold and math-aware
    hdr_cells = table.rows[0].cells
    for i, value in enumerate(header):
        format_cell(hdr_cells[i], value, bold_header=True)

    # Body rows
    for row in body:
        cells = table.add_row().cells
        for i, value in enumerate(row):
            if i < len(cells):
                format_cell(cells[i], value)

    document.add_paragraph("")


def add_figure_block(document: Document, line: str) -> None:
    # Extract PNG filenames from backtick-wrapped refs or bare refs
    image_names = re.findall(r"`([A-Za-z0-9_]+\.png)`", line)
    if not image_names:
        image_names = re.findall(r"([A-Za-z0-9_]+\.png)", line)

    if image_names:
        for image_name in image_names:
            image_path = ROOT.parent / image_name
            if image_path.exists():
                paragraph = document.add_paragraph()
                paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
                run = paragraph.add_run()
                run.add_picture(str(image_path), width=Inches(6.4))
        # Build caption: strip PNG refs, markdown bold/code markers
        caption = re.sub(r"`[A-Za-z0-9_]+\.png`", "", line)
        caption = re.sub(r"[A-Za-z0-9_]+\.png", "", caption)
        caption = re.sub(r"\*\*", "", caption)
        caption = re.sub(r"`", "", caption)
        caption = caption.strip().strip(":").strip()
        if caption:
            cap_p = document.add_paragraph(caption)
            cap_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    else:
        p = document.add_paragraph()
        add_runs(p, line)


def is_displayed_formula(line: str) -> bool:
    """
    Returns True if the entire (stripped) line is a single backtick-delimited
    expression — i.e. a standalone displayed formula, not inline math.
    """
    s = line.strip()
    return (
        len(s) > 2
        and s.startswith('`')
        and s.endswith('`')
        and s.count('`') == 2
    )


def build_docx() -> None:
    document = Document()
    set_default_style(document)
    add_title_page(document)

    lines = MARKDOWN_PATH.read_text(encoding="utf-8").splitlines()
    i = 0
    while i < len(lines):
        line = lines[i].rstrip()

        # Blank line
        if not line:
            i += 1
            continue

        # Page break
        if line == "---":
            document.add_page_break()
            i += 1
            continue

        # Headings
        if line.startswith("### "):
            document.add_heading(line[4:].strip(), level=3)
            i += 1
            continue

        if line.startswith("## "):
            document.add_heading(line[3:].strip(), level=2)
            i += 1
            continue

        if line.startswith("# "):
            # Top-level title is on the title page; skip in body
            i += 1
            continue

        # Table block
        if line.startswith("|"):
            block = [line]
            j = i + 1
            while j < len(lines) and lines[j].startswith("|"):
                block.append(lines[j].rstrip())
                j += 1
            add_markdown_table(document, block)
            i = j
            continue

        # Figure block (line starts with **Figure)
        if line.startswith("**Figure"):
            add_figure_block(document, line)
            i += 1
            continue

        # Displayed formula: entire line is one backtick-wrapped expression
        if is_displayed_formula(line):
            inner = line.strip()[1:-1]
            p = document.add_paragraph()
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            for seg_text, is_sub, is_sup in math_segments(inner):
                run = p.add_run(seg_text)
                run.italic = True
                if is_sub:
                    run.font.subscript = True
                elif is_sup:
                    run.font.superscript = True
            i += 1
            continue

        # Numbered list item
        if re.match(r"^\d+\.", line):
            p = document.add_paragraph()
            add_runs(p, line)
            i += 1
            continue

        # Bullet list item
        if line.startswith("- "):
            p = document.add_paragraph(style="List Bullet")
            add_runs(p, line[2:])
            i += 1
            continue

        # Default: regular paragraph
        p = document.add_paragraph()
        add_runs(p, line)
        i += 1

    # Set document metadata
    now = datetime.now(timezone.utc)
    cp = document.core_properties
    cp.author = "Michael Nguyen"
    cp.last_modified_by = "Michael Nguyen"
    cp.created = now
    cp.modified = now

    document.save(str(OUTPUT_PATH))


if __name__ == "__main__":
    build_docx()
    print(f"Saved: {OUTPUT_PATH}")
