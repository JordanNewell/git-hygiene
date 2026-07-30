#!/usr/bin/env python3
"""git-hygiene NEWELL brand asset renderer.

Produces OG card (1200x630) and favicon set (16/32/64/180 PNG + multi-res ICO)
from canonical NEWELL tokens. No hardcoded hex — all colors flow from
the source-of-truth tokens.json.

Usage:
    python tools/render_brand_assets.py og         # render only OG
    python tools/render_brand_assets.py favicons   # render only favicons
    python tools/render_brand_assets.py all        # render everything (default)
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import NamedTuple

from PIL import Image, ImageDraw, ImageFont

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parent.parent
TOKENS_PATH = Path("e:/vaults/anything.xyz/50_Projects/brand-system/tokens.json")
ASSETS_DIR = REPO_ROOT / "docs" / "assets"
FAVICON_DIR = ASSETS_DIR / "favicons"

# ---------------------------------------------------------------------------
# Font paths (Windows; on Linux/CI install via apt/dnf and adjust)
# ---------------------------------------------------------------------------

FONT_DIR = Path.home() / "AppData/Local/Microsoft/Windows/Fonts"
SPACE_GROTESK_BOLD = FONT_DIR / "SpaceGrotesk-Bold.ttf"
JETBRAINS_REGULAR = FONT_DIR / "JetBrainsMono-Regular.ttf"
JETBRAINS_MEDIUM = FONT_DIR / "JetBrainsMono-Medium.ttf"
JETBRAINS_BOLD = FONT_DIR / "JetBrainsMono-Bold.ttf"

# ---------------------------------------------------------------------------
# Token model
# ---------------------------------------------------------------------------

class RGB(NamedTuple):
    r: int
    g: int
    b: int


@dataclass(frozen=True)
class ColorTokens:
    primary: RGB
    accent: RGB
    background: RGB
    surface: RGB
    text: RGB
    muted: RGB
    border: RGB


@dataclass(frozen=True)
class RadiusTokens:
    sm: int
    md: int
    lg: int
    xl: int
    full: int


@dataclass(frozen=True)
class BrandTokens:
    colors: ColorTokens
    spacing: tuple[int, ...]
    radius: RadiusTokens


def grid(n: float) -> int:
    """8px spacing grid: grid(1)=8, grid(0.5)=4, grid(8)=64."""
    return int(n * 8)


def parse_hex(hex_str: str) -> RGB:
    s = hex_str.strip().lstrip("#")
    if len(s) != 6 or not all(c in "0123456789abcdefABCDEF" for c in s):
        raise ValueError(f"Invalid hex color (expected #RRGGBB): {hex_str!r}")
    return RGB(int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16))


def load_tokens(path: Path = TOKENS_PATH) -> BrandTokens:
    if not path.exists():
        raise FileNotFoundError(
            f"tokens.json not found at {path}. Brand tokens are required."
        )
    raw = json.loads(path.read_text(encoding="utf-8"))
    colors = ColorTokens(**{name: parse_hex(value) for name, value in raw["colors"].items()})
    radius = RadiusTokens(**raw["radius"])
    spacing = tuple(raw["spacing"])
    return BrandTokens(colors=colors, spacing=spacing, radius=radius)


def hex_tuple(rgb: RGB) -> tuple[int, int, int]:
    return (rgb.r, rgb.g, rgb.b)


def load_font(path: Path, size: int) -> ImageFont.FreeTypeFont:
    try:
        return ImageFont.truetype(str(path), size)
    except (FileNotFoundError, OSError) as exc:
        raise SystemExit(
            f"Font not found at {path}: {exc}. Install the font or adjust the path."
        ) from exc


# ---------------------------------------------------------------------------
# OG card — datasheet pattern, 1200x630
# ---------------------------------------------------------------------------

OG_W = 1200
OG_H = 630


def _draw_scanlines(draw: ImageDraw.ImageDraw, w: int, h: int, surface: RGB) -> None:
    """Apply 8px-pitch scanline overlay for material depth (~1.5% white)."""
    overlay = (min(surface.r + 4, 255), min(surface.g + 4, 255), min(surface.b + 4, 255))
    for y in range(0, h, grid(1)):
        draw.line([(0, y), (w, y)], fill=overlay, width=1)


def _draw_border(draw: ImageDraw.ImageDraw, tokens: BrandTokens, w: int, h: int) -> None:
    inset = grid(2)  # 16px
    draw.rectangle(
        [inset, inset, w - inset, h - inset],
        outline=hex_tuple(tokens.colors.border),
        width=1,
    )


def _draw_receipt_chip(
    draw: ImageDraw.ImageDraw,
    tokens: BrandTokens,
    text: str,
    x: int,
    y: int,
    font: ImageFont.FreeTypeFont,
) -> int:
    pad_x = grid(2)  # 16px
    pad_y = grid(1)  # 8px
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    box_w = tw + pad_x * 2
    box_h = th + pad_y
    draw.rounded_rectangle(
        [x, y, x + box_w, y + box_h],
        radius=tokens.radius.sm,
        fill=hex_tuple(tokens.colors.surface),
        outline=hex_tuple(tokens.colors.border),
        width=1,
    )
    draw.text(
        (x + pad_x - bbox[0], y + pad_y - bbox[1]),
        text,
        font=font,
        fill=hex_tuple(tokens.colors.muted),
    )
    return x + box_w


def _draw_accent_rule(
    draw: ImageDraw.ImageDraw,
    tokens: BrandTokens,
    x: int,
    y: int,
    width: int,
) -> None:
    draw.rectangle([x, y, x + width, y + 2], fill=hex_tuple(tokens.colors.primary))


def render_og(
    title: str = "git hygiene",
    subtitle: str = (
        "Tools don't get co-author credit. "
        "Two git hooks, zero dependencies. "
        "Strips AI trailers, catches secrets."
    ),
    receipt: str = "2026-07-30 / v1.0.0 / git-hygiene",
    output_path: Path = ASSETS_DIR / "og.png",
) -> Path:
    tokens = load_tokens()
    canvas = Image.new("RGB", (OG_W, OG_H), hex_tuple(tokens.colors.background))
    draw = ImageDraw.Draw(canvas)

    _draw_scanlines(draw, OG_W, OG_H, tokens.colors.surface)
    _draw_border(draw, tokens, OG_W, OG_H)

    margin_x = grid(8)  # 64px

    # Receipt chip
    mono_sm = load_font(JETBRAINS_MEDIUM, 18)
    _draw_receipt_chip(draw, tokens, receipt, margin_x, grid(8), mono_sm)

    # Accent rule
    _draw_accent_rule(draw, tokens, margin_x, grid(14), grid(8))

    # Title — Space Grotesk Bold. The file at SPACE_GROTESK_BOLD is currently
    # the variable font (static Bold TTF was corrupt on this machine); use the
    # wght axis to force Bold. The OSError guard means a future static-Bold
    # install (no variation axes) won't crash the renderer.
    display = load_font(SPACE_GROTESK_BOLD, 96)
    try:
        display.set_variation_by_axes([700])
    except OSError:
        pass
    bbox = draw.textbbox((0, 0), title, font=display)
    draw.text(
        (margin_x - bbox[0], grid(18) - bbox[1]),
        title,
        font=display,
        fill=hex_tuple(tokens.colors.text),
    )
    title_h = bbox[3] - bbox[1]

    # Subtitle — JetBrains Mono Medium, muted
    mono_md = load_font(JETBRAINS_MEDIUM, 22)
    sub_bbox = draw.textbbox((0, 0), subtitle, font=mono_md)
    draw.text(
        (margin_x - sub_bbox[0], grid(18) + title_h + grid(3) - sub_bbox[1]),
        subtitle,
        font=mono_md,
        fill=hex_tuple(tokens.colors.muted),
    )

    # Footer — primary brand line + muted meta
    mono_xs = load_font(JETBRAINS_REGULAR, 14)
    footer = "NEWELL  /  BUILD. CONNECT. GROW."
    meta = "MIT · BASH · ZERO-DEP"
    f_bbox = draw.textbbox((0, 0), footer, font=mono_xs)
    m_bbox = draw.textbbox((0, 0), meta, font=mono_xs)
    f_h = f_bbox[3] - f_bbox[1]
    footer_y = OG_H - grid(8) - f_h
    draw.text(
        (margin_x - f_bbox[0], footer_y - f_bbox[1]),
        footer,
        font=mono_xs,
        fill=hex_tuple(tokens.colors.primary),
    )
    draw.text(
        (OG_W - margin_x - (m_bbox[2] - m_bbox[0]) - m_bbox[0],
         footer_y - m_bbox[1]),
        meta,
        font=mono_xs,
        fill=hex_tuple(tokens.colors.muted),
    )

    # Footer rule
    _draw_accent_rule(draw, tokens, margin_x, footer_y - grid(1), grid(24))

    output_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output_path, format="PNG", optimize=True)
    print(f"Wrote {output_path} ({output_path.stat().st_size} bytes)")
    return output_path


# ---------------------------------------------------------------------------
# Favicon set — GH monogram (white G + neon-green H)
# ---------------------------------------------------------------------------

FAVICON_SIZES = {
    "favicon-16.png": 16,
    "favicon-32.png": 32,
    "favicon-64.png": 64,
    "apple-touch-icon.png": 180,
}


def _render_gh_monogram(size: int, tokens: BrandTokens) -> Image.Image:
    """Render the GH monogram at the requested canvas size.

    G is white, H is neon-green — mirrors the canonical NEWELL wordmark's
    green-E horizontals. Tight letter-spacing so the pair balances.
    """
    img = Image.new("RGB", (size, size), hex_tuple(tokens.colors.background))
    draw = ImageDraw.Draw(img)

    # Font size: pair needs to fit comfortably with padding.
    # Empirically ~62% of canvas for two glyphs in JBM Bold.
    font_size = max(8, int(size * 0.62))
    font = load_font(JETBRAINS_BOLD, font_size)

    text = "GH"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    # Center the glyph bounding box on the canvas.
    x = (size - tw) // 2 - bbox[0]
    y = (size - th) // 2 - bbox[1]

    # Draw G (white) + H (green) as separate text calls with manual offset.
    # Use advance width (textlength) not ink width (textbbox) for the H offset —
    # robust against font swaps where right-side bearing differs.
    g_advance = draw.textlength("G", font=font)
    # Tighten letter-spacing proportionally (~size/24 px).
    tighten = max(1, size // 24)

    draw.text((x, y), "G", font=font, fill=hex_tuple(tokens.colors.text))
    draw.text((x + int(g_advance) - tighten, y), "H", font=font, fill=hex_tuple(tokens.colors.primary))

    # 1px border on canvas edge (skip at 16x16 — border eats too much real estate)
    if size >= 32:
        draw.rectangle(
            [0, 0, size - 1, size - 1],
            outline=hex_tuple(tokens.colors.border),
            width=1,
        )

    return img


def render_favicons(output_dir: Path = FAVICON_DIR) -> list[Path]:
    tokens = load_tokens()
    output_dir.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []

    for filename, size in FAVICON_SIZES.items():
        img = _render_gh_monogram(size, tokens)
        path = output_dir / filename
        img.save(path, format="PNG", optimize=True)
        written.append(path)
        print(f"Wrote {path} ({path.stat().st_size} bytes)")

    # Multi-res ICO (16+32+64)
    ico_sizes = [16, 32, 64]
    ico_images = [_render_gh_monogram(s, tokens) for s in ico_sizes]
    ico_path = output_dir / "favicon.ico"
    # Pillow's ICO encoder builds multi-res sub-images by downsampling a single
    # base image per entry in `sizes` — it will not upsample. Save the largest
    # rendered image (64x64) as the base so all three sizes emit. (Rendering each
    # size individually above keeps sharp per-size art available for PNGs.)
    ico_images[-1].save(
        ico_path,
        format="ICO",
        sizes=[(s, s) for s in ico_sizes],
    )
    written.append(ico_path)
    print(f"Wrote {ico_path} ({ico_path.stat().st_size} bytes)")

    return written


# ---------------------------------------------------------------------------
# Subcommand dispatch (functions added in later tasks)
# ---------------------------------------------------------------------------

def main(argv: list[str]) -> int:
    cmd = argv[1] if len(argv) > 1 else "all"
    if cmd not in ("og", "favicons", "all"):
        print(f"Unknown subcommand: {cmd!r}. Use one of: og, favicons, all.", file=sys.stderr)
        return 2
    if cmd in ("og", "all"):
        render_og()
    if cmd in ("favicons", "all"):
        render_favicons()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
