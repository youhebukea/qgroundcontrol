#!/usr/bin/env python3
"""Build LINTOR (联涛智控) branding assets from the source logo photo.

Extracts the wordmark from custom/brand/lintor-logo-source.jpg, keys out the
light background, splits the two text lines, and regenerates every branded
asset under custom/res, custom/deploy and custom/android.

Usage: python custom/tools/generate_lintor_assets.py
"""

from __future__ import annotations

import base64
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageOps

ROOT = Path(__file__).resolve().parent.parent  # custom/
SRC_JPG = ROOT / "brand" / "lintor-logo-source.jpg"
WORK = ROOT / "brand"
ICONS = ROOT / "res" / "icons"
IMAGES = ROOT / "res" / "images"
DEPLOY_WIN = ROOT / "deploy" / "windows"

# Rough band containing the wordmark inside the 1280x1280 source photo.
CROP_BOX = (238, 442, 1082, 782)
ALPHA_FLOOR = 158  # luminance at/below which pixels are background (band is dimmer than the photo median)
INK_LUM = 55  # reference luminance for full opacity
INK_BLACK = (17, 17, 17)
LINTOR_BLUE = (30, 96, 208)  # brand blue for the signal arcs

ICO_SIZES = [(16, 16), (32, 32), (48, 48), (256, 256)]
ICNS_SIZES = [(16, 16), (32, 32), (128, 128), (256, 256)]
ANDROID_DPI = {
    "ldpi": 36,
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}


def _channels(rgb: Image.Image) -> tuple[Image.Image, Image.Image]:
    r, g, b = rgb.split()
    mx = ImageChops.lighter(ImageChops.lighter(r, g), b)
    mn = ImageChops.darker(ImageChops.darker(r, g), b)
    return mx, mn


def _ink_alpha(rgb: Image.Image) -> Image.Image:
    """Alpha mask where dark ink and saturated (blue) pixels are opaque."""
    lum = rgb.convert("L")
    mx, mn = _channels(rgb)
    chroma = ImageChops.subtract(mx, mn)
    dark = lum.point(lambda v: max(0, min(255, int((ALPHA_FLOOR - v) * 255 / (ALPHA_FLOOR - INK_LUM)))))
    sat = chroma.point(lambda v: max(0, min(255, (v - 35) * 255 // (120 - 35))))
    return ImageChops.lighter(dark, sat)


def _blue_mask(rgb: Image.Image) -> Image.Image:
    """Mask of saturated (blue arc) pixels."""
    mx, mn = _channels(rgb)
    chroma = ImageChops.subtract(mx, mn)
    return chroma.point(lambda v: 255 if v > 60 else 0)


def _flat_ink(size: tuple[int, int], blue_mask: Image.Image) -> Image.Image:
    """Flat-color ink layer: near-black text + brand blue arcs."""
    base = Image.new("RGB", size, INK_BLACK)
    blue = Image.new("RGB", size, LINTOR_BLUE)
    return Image.composite(blue, base, blue_mask)


def extract_wordmark() -> Image.Image:
    """Return the transparent full wordmark (LINTOR + 联涛智控 + blue arcs)."""
    img = Image.open(SRC_JPG).convert("RGB")
    band = img.crop(CROP_BOX)
    alpha = _ink_alpha(band)
    blue_mask = _blue_mask(band)
    bbox = alpha.point(lambda v: 255 if v > 40 else 0).getbbox()
    alpha = alpha.crop(bbox)
    rgb = _flat_ink(alpha.size, blue_mask.crop(bbox))
    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    out.save(WORK / "lintor-wordmark-full.png")
    return out


def split_lines(wordmark: Image.Image) -> tuple[Image.Image, Image.Image]:
    """Split the wordmark into (latin line, chinese line) at the largest gap."""
    alpha = wordmark.split()[3]
    w, h = alpha.size
    sample_w = len(range(0, w, 4))
    noise = 3 * sample_w  # row sums at/below this are background noise
    hist = [sum(alpha.getpixel((x, y)) for x in range(0, w, 4)) for y in range(h)]
    gap_center, gap_best, run = 0, 0, 0
    for y in range(int(h * 0.3), h):  # the line gap lies in the lower 70%
        if hist[y] <= noise:
            run += 1
            if run > gap_best:
                gap_best, gap_center = run, y - run // 2
        else:
            run = 0
    if gap_center == 0:  # fallback: quietest row between the two lines
        lo, hi = int(h * 0.45), int(h * 0.9)
        gap_center = lo + hist[lo:hi].index(min(hist[lo:hi]))
    latin = wordmark.crop((0, 0, w, gap_center))
    latin.save(WORK / "lintor-wordmark-latin.png")
    cn = wordmark.crop((0, gap_center, w, h))
    cn.save(WORK / "lintor-wordmark-cn.png")
    return latin, cn


def make_badge(latin: Image.Image, size: int = 1024) -> Image.Image:
    """White rounded-square app badge with the LINTOR line + blue arcs."""
    s = size * 4  # supersample
    badge = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(badge)
    draw.rounded_rectangle((0, 0, s - 1, s - 1), radius=s * 22 // 100, fill=(255, 255, 255, 255))
    target_w = int(s * 0.80)
    target_h = int(latin.size[1] * target_w / latin.size[0])
    logo = latin.resize((target_w, target_h), Image.LANCZOS)
    badge.alpha_composite(logo, ((s - target_w) // 2, (s - target_h) // 2))
    return badge.resize((size, size), Image.LANCZOS)


def make_white_line(latin: Image.Image) -> Image.Image:
    """Monochrome variant for dark backgrounds: white text, blue arcs kept."""
    rgb = latin.convert("RGB")
    alpha = latin.split()[3]
    dark_text = rgb.convert("L").point(lambda v: 255 if v < 60 else 0)
    white = Image.new("RGB", rgb.size, (255, 255, 255))
    out = Image.composite(white, rgb, dark_text).convert("RGBA")
    out.putalpha(alpha)
    return out


def save_svg_embedded(png: Path, svg: Path, width: int, height: int) -> None:
    data = base64.b64encode(png.read_bytes()).decode("ascii")
    svg.write_text(
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
        f'width="{width}" height="{height}" viewBox="0 0 {width} {height}">\n'
        f'  <image width="{width}" height="{height}" xlink:href="data:image/png;base64,{data}"/>\n'
        "</svg>\n",
        encoding="utf-8",
    )


def main() -> None:
    for d in (WORK, ICONS, IMAGES, DEPLOY_WIN):
        d.mkdir(parents=True, exist_ok=True)

    full = extract_wordmark()
    latin, _cn = split_lines(full)

    badge = make_badge(latin)

    # Application icons
    badge.save(ICONS / "lintor.ico", sizes=ICO_SIZES)
    badge.save(ICONS / "lintor.icns", sizes=ICNS_SIZES)
    badge.save(ICONS / "lintor-256.png")

    # AppImage scalable icon: SVG wrapping the 256px badge
    tmp = WORK / "_badge256.png"
    badge.resize((256, 256), Image.LANCZOS).save(tmp)
    save_svg_embedded(tmp, ICONS / "LintorAppIcon.svg", 256, 256)

    # QML logo resources (toolbar / menus / map GCS indicator + dark-bg variant)
    tmp = WORK / "_badge512.png"
    badge.resize((512, 512), Image.LANCZOS).save(tmp)
    save_svg_embedded(tmp, IMAGES / "LintorLogoFull.svg", 512, 512)
    white = make_white_line(latin)
    tmp = WORK / "_white.png"
    white.resize((512, 512 * white.size[1] // white.size[0]), Image.LANCZOS).save(tmp)
    save_svg_embedded(tmp, IMAGES / "LintorLogoWhite.svg", 512, 512 * white.size[1] // white.size[0])

    # NSIS installer header: full wordmark on white, 150x57
    header = Image.new("RGB", (150 * 4, 57 * 4), (255, 255, 255))
    target_w = 140 * 4
    target_h = int(full.size[1] * target_w / full.size[0])
    if target_h > 50 * 4:
        target_h = 50 * 4
        target_w = int(full.size[0] * target_h / full.size[1])
    logo = full.resize((target_w, target_h), Image.LANCZOS)
    header.paste(logo, ((150 * 4 - target_w) // 2, (57 * 4 - target_h) // 2), logo)
    header.convert("RGB").save(DEPLOY_WIN / "installheader.bmp")

    # Android launcher icons
    for dpi, size in ANDROID_DPI.items():
        badge.resize((size, size), Image.LANCZOS).save(
            ROOT / "android" / "res" / f"drawable-{dpi}" / "icon.png"
        )

    print(f"LINTOR brand assets written under {ROOT}")


if __name__ == "__main__":
    main()
