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
ASSETS_DIR = REPO_ROOT / "assets"
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
