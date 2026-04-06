import re
from datetime import datetime, timezone
from pathlib import Path

from docx import Document
from docx.shared import Inches, Pt
from docx.enum.text import WD_ALIGN_PARAGRAPH


ROOT = Path(__file__).resolve().parent
MARKDOWN_PATH = ROOT / "report_text.md"
OUTPUT_PATH = ROOT / "ECON3350_Research_Report.docx"


def clean_inline(text: str) -> str:
    text = text.replace("**", "")
    text = text.replace("`", "")
    return text.strip()


def set_default_style(document: Document) -> None:
    style = document.styles["Normal"]
    style.font.name = "Times New Roman"
    style.font.size = Pt(12)


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
    data = []
    for row in rows:
        cells = [clean_inline(cell) for cell in row.strip().strip("|").split("|")]
        data.append(cells)
    if len(data) < 2:
        return
    header = data[0]
    body = data[2:]
    table = document.add_table(rows=1, cols=len(header))
    table.style = "Table Grid"
    for i, value in enumerate(header):
        table.rows[0].cells[i].text = value
    for row in body:
        cells = table.add_row().cells
        for i, value in enumerate(row):
            if i < len(cells):
                cells[i].text = value
    document.add_paragraph("")


def add_figure_block(document: Document, line: str) -> None:
    clean = clean_inline(line)
    image_names = re.findall(r"([A-Za-z0-9_]+\.png)", clean)
    if image_names:
        for image_name in image_names:
            image_path = ROOT.parent / image_name
            if image_path.exists():
                paragraph = document.add_paragraph()
                paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
                run = paragraph.add_run()
                run.add_picture(str(image_path), width=Inches(6.4))
        caption = re.sub(r"`[^`]+`", "", clean).strip()
        if caption:
            p = document.add_paragraph(caption)
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    else:
        document.add_paragraph(clean)


def build_docx() -> None:
    document = Document()
    set_default_style(document)
    add_title_page(document)

    lines = MARKDOWN_PATH.read_text(encoding="utf-8").splitlines()
    i = 0
    while i < len(lines):
        line = lines[i].rstrip()

        if not line:
            i += 1
            continue

        if line == "---":
            document.add_page_break()
            i += 1
            continue

        if line.startswith("### "):
            document.add_heading(clean_inline(line[4:]), level=3)
            i += 1
            continue

        if line.startswith("## "):
            document.add_heading(clean_inline(line[3:]), level=2)
            i += 1
            continue

        if line.startswith("# "):
            i += 1
            continue

        if line.startswith("|"):
            block = [line]
            j = i + 1
            while j < len(lines) and lines[j].startswith("|"):
                block.append(lines[j].rstrip())
                j += 1
            add_markdown_table(document, block)
            i = j
            continue

        if line.startswith("**Figure"):
            add_figure_block(document, line)
            i += 1
            continue

        if re.match(r"^\d+\.", line):
            document.add_paragraph(clean_inline(line))
            i += 1
            continue

        document.add_paragraph(clean_inline(line))
        i += 1

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
