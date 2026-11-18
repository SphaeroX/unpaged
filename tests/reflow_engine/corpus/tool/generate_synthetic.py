"""Generates the synthetic corpus PDFs (CC0, written for paperflow).

Run from the project root with fpdf2 installed in a throwaway venv:
    python3 -m venv /tmp/venv && /tmp/venv/bin/pip install fpdf2
    /tmp/venv/bin/python tests/reflow_engine/corpus/tool/generate_synthetic.py
"""
from fpdf import FPDF

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


if __name__ == "__main__":
    single_column()
