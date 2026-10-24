"""Build the concise submission PDF from DOCUMENTATION.md using ReportLab."""
from pathlib import Path
import re
from xml.sax.saxutils import escape

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import HRFlowable, PageBreak, Paragraph, SimpleDocTemplate, Spacer


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "DOCUMENTATION.md"
OUTPUT = ROOT / "DOCUMENTATION.pdf"
INK = colors.HexColor("#17211d")
LIME = colors.HexColor("#d6ff57")
MUTED = colors.HexColor("#647066")


def draw_page(canvas, doc):
    canvas.saveState()
    width, height = letter
    canvas.setFillColor(INK)
    canvas.rect(0, height - 0.18 * inch, width, 0.18 * inch, fill=1, stroke=0)
    canvas.setFillColor(LIME)
    canvas.rect(0, height - 0.18 * inch, 1.6 * inch, 0.18 * inch, fill=1, stroke=0)
    canvas.setFillColor(MUTED)
    canvas.setFont("Helvetica", 8)
    canvas.drawString(doc.leftMargin, 0.42 * inch, "GOOD MEASURE  /  PHASE 1 MVP")
    canvas.drawRightString(width - doc.rightMargin, 0.42 * inch, f"{doc.page}")
    canvas.restoreState()


def inline_markup(value: str) -> str:
    parts = re.split(r"(`[^`]+`)", value)
    return "".join(
        f'<font name="Courier">{escape(part[1:-1])}</font>' if part.startswith("`") else escape(part)
        for part in parts
    )


styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name="DocTitle", parent=styles["Title"], fontName="Helvetica-Bold", fontSize=22, leading=25, textColor=INK, alignment=TA_LEFT, spaceAfter=6))
styles.add(ParagraphStyle(name="DocH1", parent=styles["Heading1"], fontName="Helvetica-Bold", fontSize=14, leading=17, textColor=INK, spaceBefore=9, spaceAfter=4, keepWithNext=True))
styles.add(ParagraphStyle(name="DocBody", parent=styles["BodyText"], fontName="Helvetica", fontSize=8.8, leading=12.2, textColor=INK, spaceAfter=4))
styles.add(ParagraphStyle(name="DocBullet", parent=styles["BodyText"], fontName="Helvetica", fontSize=8.7, leading=11.5, leftIndent=13, firstLineIndent=-8, bulletIndent=0, textColor=INK, spaceAfter=3))


def main():
    doc = SimpleDocTemplate(str(OUTPUT), pagesize=letter, rightMargin=0.72 * inch, leftMargin=0.72 * inch, topMargin=0.58 * inch, bottomMargin=0.60 * inch, title="Nutritionist Booking MVP - Project Notes", author="Good Measure")
    story = [Spacer(1, 0.12 * inch), Paragraph("Nutritionist Booking MVP", styles["DocTitle"]), Paragraph("Phase 1 implementation notes - 24 October 2026", styles["DocBody"]), HRFlowable(width="100%", thickness=1.2, color=INK, spaceBefore=2, spaceAfter=8)]
    text = SOURCE.read_text(encoding="utf-8")
    sections = []
    current_title = None
    current_lines = []
    for line in text.splitlines():
        if line.startswith("# "):
            if current_title is not None:
                sections.append((current_title, current_lines))
            current_title, current_lines = line[2:].strip(), []
        elif current_title is not None:
            current_lines.append(line)
    if current_title is not None:
        sections.append((current_title, current_lines))
    for title, lines in sections:
        story.append(Paragraph(escape(title), styles["DocH1"]))
        paragraph = []
        for line in [*lines, ""]:
            stripped = line.strip()
            if stripped.startswith("- "):
                if paragraph:
                    story.append(Paragraph(inline_markup(" ".join(paragraph)), styles["DocBody"]))
                    paragraph = []
                story.append(Paragraph("- " + escape(stripped[2:]), styles["DocBullet"]))
            elif stripped:
                paragraph.append(stripped)
            elif paragraph:
                story.append(Paragraph(inline_markup(" ".join(paragraph)), styles["DocBody"]))
                paragraph = []
    doc.build(story, onFirstPage=draw_page, onLaterPages=draw_page)
    print(OUTPUT)


if __name__ == "__main__":
    main()
