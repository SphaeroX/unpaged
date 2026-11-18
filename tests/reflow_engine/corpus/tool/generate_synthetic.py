"""Generates the synthetic corpus PDFs (CC0, written for Unpaged).

Run from the project root with fpdf2 installed in a throwaway venv:
    python3 -m venv /tmp/venv && /tmp/venv/bin/pip install fpdf2
    /tmp/venv/bin/python tests/reflow_engine/corpus/tool/generate_synthetic.py
"""
from datetime import datetime, timezone

from fpdf import FPDF

# Fixed date keeps the generated files byte-stable.
CREATED = datetime(2026, 11, 18, tzinfo=timezone.utc)

OUT = "tests/reflow_engine/corpus/"

PARAGRAPHS = [
    "Reading long technical documents on a phone is tiring when the layout "
    "was made for paper. Small fonts, wide margins and fixed line breaks force "
    "the reader to zoom and pan all the time.",
    "A reflow engine solves this by extracting the text and laying it out "
    "again for the screen. Each paragraph becomes a block that can wrap at any "
    "width, while the original page stays available for reference.",
    "This synthetic document has three paragraphs on the first page and two "
    "on the second page. It exists so that tests can compare the engine output "
    "with a known, exact expectation.",
    "The second page starts with a new paragraph. Its lines are wrapped by "
    "the generator at a fixed width, just like a typeset paper would be.",
    "The last paragraph is short.",
]


def single_column() -> None:
    pdf = FPDF(format="A4")
    pdf.set_creation_date(CREATED)
    pdf.set_margins(25, 25, 25)
    pdf.set_auto_page_break(False)
    pages = [PARAGRAPHS[:3], PARAGRAPHS[3:]]
    for page in pages:
        pdf.add_page()
        pdf.set_font("Helvetica", size=11)
        for text in page:
            pdf.multi_cell(0, 6, text)
            pdf.ln(6)
    pdf.output(OUT + "synthetic_single_column.pdf")


TWO_COLUMN_PAGES = [
    {
        "left": [
            "    Reflow engines read the glyphs of a page",
            "and rebuild the text in reading order. This",
            "paper is laid out in two columns, so the left",
            "column must be read completely before the",
            "right one. Long words are split with an infor-",
            "mation hyphen at the end of a line, while a",
        ],
        "right": [
            "well-known compound keeps its hyphen even",
            "when the line ends after the Offline-",
            "Modus prefix in German text.",
            "    A second paragraph starts with an indent and",
            "continues on the next page without a break",
        ],
    },
    {
        "left": [
            "in the middle of the sentence. The well-",
            "known example above shows the rule.",
            "    The final paragraph is short.",
        ],
        "right": [],
    },
]


def two_column() -> None:
    pdf = FPDF(format="A4")
    pdf.set_creation_date(CREATED)
    pdf.set_auto_page_break(False)
    for number, page in enumerate(TWO_COLUMN_PAGES, start=1):
        pdf.add_page()
        pdf.set_font("Helvetica", size=8)
        pdf.set_xy(0, 20)
        pdf.cell(210, 5, "Synthetic Journal of Reflow, Vol. 1", align="C")
        pdf.set_xy(0, 280)
        pdf.cell(210, 5, str(number), align="C")
        y = 40
        if number == 1:
            pdf.set_font("Helvetica", size=16)
            pdf.set_xy(0, 28)
            pdf.cell(210, 8, "A Synthetic Two Column Paper", align="C")
            y = 45
        pdf.set_font("Helvetica", size=10)
        for x, key in ((20, "left"), (110, "right")):
            for i, text in enumerate(page[key]):
                pdf.set_xy(x, y + 5 * i)
                pdf.cell(80, 5, text)
    pdf.output(OUT + "synthetic_two_column.pdf")


if __name__ == "__main__":
    single_column()
    two_column()
