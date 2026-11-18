# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow>=10"]
# ///
"""Builds the Google Play graphics from the app screenshots.

Run from the project root:  uv run tool/store_assets.py

Inputs:  assets/branding/unpaged_icon_512.png, assets/fonts/,
         docs/screenshots/*.png (English) and docs/screenshots/de/*.png
         (German), both captured by tests/screenshots.
Outputs: android/fastlane/metadata/android/<locale>/images/
         icon.png (512x512), featureGraphic.png (1024x500) and
         phoneScreenshots/<n>_<name>.png (1080x1920, headline + screenshot).
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONTS = ROOT / "assets" / "fonts"
ICON = ROOT / "assets" / "branding" / "unpaged_icon_512.png"
OUT = ROOT / "android" / "fastlane" / "metadata" / "android"

NAVY = (31, 42, 92)
PAPER = (244, 241, 234)
ORANGE = (255, 138, 91)

LOCALES = {
    "en-US": {
        "shots": ROOT / "docs" / "screenshots",
        "tagline": "Read PDFs like an eBook.",
        "claims": "Offline · Open source · No tracking",
        "headlines": {
            "01_library": "Your PDF library,\nfully offline",
            "02_original": "Every PDF in its\noriginal layout",
            "03_ebook": "Two columns become\nan eBook",
            "04_ebook_figure": "Figures and tables\nstay sharp",
            "05_settings_sepia": "Your font, your size,\nyour theme",
            "06_ebook_dark": "Easy on the eyes,\nday and night",
        },
    },
    "de-DE": {
        "shots": ROOT / "docs" / "screenshots" / "de",
        "tagline": "PDFs lesen wie ein eBook.",
        "claims": "Offline · Open Source · Kein Tracking",
        "headlines": {
            "01_library": "Deine PDF-Bibliothek,\nkomplett offline",
            "02_original": "Jede PDF im\nOriginal-Layout",
            "03_ebook": "Aus zwei Spalten\nwird ein eBook",
            "04_ebook_figure": "Abbildungen und\nTabellen bleiben scharf",
            "05_settings_sepia": "Deine Schrift, deine\nGröße, deine Farben",
            "06_ebook_dark": "Angenehm zu lesen,\nam Tag und in der Nacht",
        },
    },
}


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONTS / name), size)


def bold(size: int) -> ImageFont.FreeTypeFont:
    return font("AtkinsonHyperlegible-Bold.ttf", size)


def regular(size: int) -> ImageFont.FreeTypeFont:
    return font("AtkinsonHyperlegible-Regular.ttf", size)


def serif(size: int) -> ImageFont.FreeTypeFont:
    f = font("Literata.ttf", size)
    try:  # variable font: pick the semibold instance if available
        f.set_variation_by_axes([600])
    except (OSError, ValueError):
        pass
    return f


def full_bleed_icon() -> Image.Image:
    """Play masks the icon itself, so it wants a full square without corners."""
    icon = Image.open(ICON).convert("RGBA")
    square = Image.new("RGBA", icon.size, NAVY + (255,))
    square.alpha_composite(icon)
    return square


def rounded(img: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, img.width - 1, img.height - 1), radius, fill=255
    )
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def paste_with_shadow(canvas: Image.Image, img: Image.Image, xy, blur=28, offset=14):
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    alpha = img.getchannel("A").point(lambda a: int(a * 0.45))
    black = Image.new("RGBA", img.size, (0, 0, 0, 255))
    black.putalpha(alpha)
    shadow.paste(black, (xy[0], xy[1] + offset), black)
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(blur)))
    canvas.alpha_composite(img, xy)


def phone(shot: Image.Image, width: int) -> Image.Image:
    """The screenshot in a simple dark device frame with rounded corners."""
    border = max(10, width // 40)
    scale = (width - 2 * border) / shot.width
    inner = shot.convert("RGB").resize(
        (width - 2 * border, round(shot.height * scale)), Image.LANCZOS
    )
    frame = Image.new("RGBA", (width, inner.height + 2 * border), (17, 20, 32, 255))
    frame = rounded(frame, border * 4)
    frame.alpha_composite(rounded(inner, border * 3), (border, border))
    return frame


def feature_graphic(cfg: dict, ebook_shot: Path) -> Image.Image:
    w, h = 1024, 500
    canvas = Image.new("RGBA", (w, h), NAVY + (255,))
    draw = ImageDraw.Draw(canvas)
    # Orange "reflowed lines" motif from the icon, bottom left.
    for i, length in enumerate((360, 300, 340)):
        y = 400 + i * 26
        draw.rounded_rectangle((64, y, 64 + length, y + 12), 6, fill=ORANGE)

    icon = full_bleed_icon().resize((112, 112), Image.LANCZOS)
    canvas.alpha_composite(rounded(icon, 26), (64, 70))
    draw.text((64, 206), "Unpaged", font=bold(76), fill=PAPER)
    draw.text((66, 300), cfg["tagline"], font=serif(36), fill=PAPER)
    draw.text((66, 352), cfg["claims"], font=regular(24), fill=(200, 205, 225))

    # Phone with the eBook screenshot, cut off at the bottom edge.
    device = phone(Image.open(ebook_shot), 300)
    paste_with_shadow(canvas, device, (w - 300 - 70, 48), blur=18, offset=8)
    return canvas.convert("RGB")


def store_screenshot(headline: str, shot: Path, index: int) -> Image.Image:
    w, h = 1080, 1920
    canvas = Image.new("RGBA", (w, h), NAVY + (255,))
    draw = ImageDraw.Draw(canvas)
    head = bold(74)
    lines = headline.split("\n")
    y = 110
    for line in lines:
        tw = draw.textlength(line, font=head)
        draw.text(((w - tw) / 2, y), line, font=head, fill=PAPER)
        y += 92
    accent_w = 120
    draw.rounded_rectangle(
        ((w - accent_w) / 2, y + 22, (w + accent_w) / 2, y + 34), 6, fill=ORANGE
    )
    device = phone(Image.open(shot), 760)
    top = y + 90
    paste_with_shadow(canvas, device, ((w - device.width) // 2, top))
    return canvas.convert("RGB")


def main() -> None:
    for locale, cfg in LOCALES.items():
        images = OUT / locale / "images"
        shots_dir = images / "phoneScreenshots"
        shots_dir.mkdir(parents=True, exist_ok=True)
        for old in shots_dir.glob("*.png"):
            old.unlink()

        full_bleed_icon().convert("RGB").save(images / "icon.png")
        feature_graphic(cfg, cfg["shots"] / "03_ebook.png").save(
            images / "featureGraphic.png"
        )
        for i, (name, headline) in enumerate(cfg["headlines"].items(), start=1):
            src = cfg["shots"] / f"{name}.png"
            if not src.exists():
                raise SystemExit(f"Missing screenshot {src}; run tests/screenshots")
            store_screenshot(headline, src, i).save(shots_dir / f"{i}_{name}.png")
        print(f"{locale}: icon, feature graphic, {i} screenshots -> {images}")


if __name__ == "__main__":
    main()
