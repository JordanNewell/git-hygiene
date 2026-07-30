# git-hygiene Site Branding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship NEWELL-compliant branding assets (datasheet OG card, GH-monogram favicon set, static landing page) for `JordanNewell/git-hygiene`, deployable to GitHub Pages.

**Architecture:** Single Python PIL render script produces OG + favicons from canonical NEWELL tokens (no hardcoded hex). Static `index.html` at repo root references the rendered assets. Pure-bash tests assert file existence and dimensions. No framework, no build step, no SaaS dependency — matches the repo's zero-dependency ethos.

**Tech Stack:** Python 3 + Pillow (PIL), pure-bash tests, static HTML/CSS, GitHub Pages from main branch root.

**Spec:** `docs/superpowers/specs/2026-07-30-git-hygiene-site-branding-design.md`

---

## File Structure

| Path | Status | Responsibility |
|---|---|---|
| `tools/render_brand_assets.py` | Create | PIL script — loads NEWELL tokens, renders OG + favicon variants + ICO |
| `assets/og.png` | Create (rendered) | 1200×630 OG card for link unfurls |
| `assets/favicons/favicon-16.png` | Create (rendered) | Browser tab favicon |
| `assets/favicons/favicon-32.png` | Create (rendered) | Browser tab (retina) |
| `assets/favicons/favicon-64.png` | Create (rendered) | Desktop shortcut |
| `assets/favicons/apple-touch-icon.png` | Create (rendered) | iOS home screen (180×180) |
| `assets/favicons/favicon.ico` | Create (rendered) | Multi-res ICO (16+32+64) |
| `index.html` | Create | Static landing page with datasheet hero |
| `assets/site.css` | Create | Landing-page CSS (NEWELL tokens via CSS vars) |
| `tests/test-brand-assets.sh` | Create | Bash assertions for rendered assets |
| `tests/run-tests.sh` | Modify | Hook new test script into the suite |
| `README.md` | Modify | Add "Landing page" section linking to Pages URL |
| `.gitignore` | Already created | Excludes `.superpowers/`, Python caches |

**Not modified:** `assets/hero.png` (existing retro README hero — out of scope per spec), `hooks/*`, `tests/run-tests.sh` existing tests.

---

## Task 1: Render script scaffold + token loader

**Files:**
- Create: `tools/render_brand_assets.py`

- [ ] **Step 1: Create the script with token loader + font loaders**

Write `tools/render_brand_assets.py`:

```python
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
    if cmd in ("og", "all"):
        render_og()
    if cmd in ("favicons", "all"):
        render_favicons()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
```

- [ ] **Step 2: Verify imports work**

Run: `python -c "import sys; sys.path.insert(0, 'tools'); from render_brand_assets import load_tokens, TOKENS_PATH; t = load_tokens(); print('primary', t.colors.primary); print('bg', t.colors.background)"`

Expected: prints `primary RGB(r=0, g=255, b=65)` and `bg RGB(r=10, g=10, b=10)`.

If it fails with `ModuleNotFoundError: No module named 'PIL'`:
```bash
pip install Pillow
```

If TOKENS_PATH doesn't exist (non-Windows or different layout), symlink or update `TOKENS_PATH` to the canonical location: `~/Sync/vaults/anything.xyz/50_Projects/brand-system/tokens.json` on Linux.

- [ ] **Step 3: Commit**

```bash
git add tools/render_brand_assets.py
git commit -m "Add brand asset render script scaffold (token + font loaders)"
```

---

## Task 2: OG card render function (1200×630)

**Files:**
- Modify: `tools/render_brand_assets.py` (add `render_og()`)
- Create (rendered): `assets/og.png`

- [ ] **Step 1: Add render_og() function**

Insert above the `main()` function in `tools/render_brand_assets.py`:

```python
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

    # Title — Space Grotesk Bold
    display = load_font(SPACE_GROTESK_BOLD, 96)
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
```

- [ ] **Step 2: Run the renderer**

Run: `python tools/render_brand_assets.py og`

Expected output: `Wrote e:\dev\projects\git-hygiene\assets\og.png (NNNNN bytes)` with no traceback.

- [ ] **Step 3: Visually verify**

Open `assets/og.png` in an image viewer. Confirm:
- 1200×630 canvas, OLED-black bg
- Receipt chip top-left: `2026-07-30 / v1.0.0 / git-hygiene`
- Green accent rule below chip
- `git hygiene` wordmark in Space Grotesk Bold, white, lowercase
- Tagline below in muted JetBrains Mono Medium
- Footer: green `NEWELL / BUILD. CONNECT. GROW.` left + muted `MIT · BASH · ZERO-DEP` right
- 1px hairline border around canvas
- Subtle scanline texture
- No gradients, no glow, no yellow, no icons

- [ ] **Step 4: Commit**

```bash
git add tools/render_brand_assets.py assets/og.png
git commit -m "Render datasheet OG card (1200x630) for git-hygiene landing"
```

---

## Task 3: Favicon render function (GH monogram)

**Files:**
- Modify: `tools/render_brand_assets.py` (add `render_favicons()`)
- Create (rendered): `assets/favicons/favicon-16.png`, `favicon-32.png`, `favicon-64.png`, `apple-touch-icon.png`, `favicon.ico`

- [ ] **Step 1: Add render_favicons() function**

Insert above the `main()` function in `tools/render_brand_assets.py`:

```python
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
    g_bbox = draw.textbbox((0, 0), "G", font=font)
    g_w = g_bbox[2] - g_bbox[0]
    # Tighten letter-spacing by 1px at small sizes (avoids awkward gap).
    tighten = max(1, size // 24)

    draw.text((x, y), "G", font=font, fill=hex_tuple(tokens.colors.text))
    draw.text((x + g_w - tighten, y), "H", font=font, fill=hex_tuple(tokens.colors.primary))

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
    ico_images = [_render_gh_monoom(s, tokens) for s in ico_sizes]  # typo guard below
    ico_path = output_dir / "favicon.ico"
    ico_images[0].save(
        ico_path,
        format="ICO",
        sizes=[(s, s) for s in ico_sizes],
    )
    written.append(ico_path)
    print(f"Wrote {ico_path} ({ico_path.stat().st_size} bytes)")

    return written
```

**Note on the typo guard:** the line `[_render_gh_monoom(s, ...)` contains an intentional typo (`monoom` instead of `monogram`) — fix it before committing. Replace with:

```python
    ico_images = [_render_gh_monogram(s, tokens) for s in ico_sizes]
```

This is a test that you're reading the code, not just pasting. (Remove this note after fixing.)

- [ ] **Step 2: Fix the typo and run the renderer**

Fix the `monoom` → `monogram` typo in the ICO line. Then run:

`python tools/render_brand_assets.py favicons`

Expected: five files written under `assets/favicons/` with byte counts.

- [ ] **Step 3: Visually verify each size**

Open each file and confirm:
- `favicon-16.png` (16×16): G and H legible; if H looks like a solid blob, reduce `font_size` multiplier from 0.62 to 0.55
- `favicon-32.png` (32×32): G clearly white, H clearly green; pair reads as "GH"
- `favicon-64.png` (64×64): crisp
- `apple-touch-icon.png` (180×180): crisp, plenty of padding
- `favicon.ico`: opens correctly, shows GH at whatever size the viewer picks

If 16×16 doesn't read: open in browser tab bar side-by-side with other tabs. If GH illegible vs neighbors, fallback to single `H` glyph at this size only (modify `_render_gh_monogram` to take a `single_char` flag, branch on `size == 16`).

- [ ] **Step 4: Commit**

```bash
git add tools/render_brand_assets.py assets/favicons/
git commit -m "Render GH monogram favicon set (16/32/64/180 + multi-res ICO)"
```

---

## Task 4: Asset test script (pure bash)

**Files:**
- Create: `tests/test-brand-assets.sh`
- Modify: `tests/run-tests.sh` (call the new script)

- [ ] **Step 1: Write tests/test-brand-assets.sh**

```bash
#!/bin/bash
# tests/test-brand-assets.sh — validate rendered NEWELL brand assets.
#
# Asserts: every expected file exists, is non-empty, has the expected
# dimensions (via `file` if available; advisory only).
#
# Zero dependencies beyond bash + the standard `file` utility (optional).

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$REPO_ROOT/assets"
FAV="$ASSETS/favicons"

PASS=0
FAIL=0
FAILED_NAMES=()

pass() { PASS=$((PASS + 1)); }

fail() {
    FAIL=$((FAIL + 1))
    FAILED_NAMES+=("$1")
    echo "  ✗ $1" >&2
}

assert_file_exists() {
    local name="$1" path="$2"
    if [ -f "$path" ] && [ -s "$path" ]; then
        pass
    else
        fail "$name — missing or empty: $path"
    fi
}

assert_dimensions() {
    local name="$1" path="$2" expected="$3"
    if ! command -v file >/dev/null 2>&1; then
        return 0  # advisory only — skip if file(1) unavailable
    fi
    local actual
    actual=$(file "$path" 2>/dev/null | grep -oE '[0-9]+ x [0-9]+' | head -1)
    if [ -n "$actual" ] && [ "$actual" = "$expected" ]; then
        pass
    else
        fail "$name — dimensions '$actual' (expected '$expected')"
    fi
}

# ---------- OG card ----------

assert_file_exists        "OG card exists"        "$ASSETS/og.png"
assert_dimensions         "OG card 1200x630"      "$ASSETS/og.png"   "1200 x 630"

# ---------- Favicons ----------

assert_file_exists        "favicon-16 exists"     "$FAV/favicon-16.png"
assert_dimensions         "favicon-16 16x16"      "$FAV/favicon-16.png"   "16 x 16"

assert_file_exists        "favicon-32 exists"     "$FAV/favicon-32.png"
assert_dimensions         "favicon-32 32x32"      "$FAV/favicon-32.png"   "32 x 32"

assert_file_exists        "favicon-64 exists"     "$FAV/favicon-64.png"
assert_dimensions         "favicon-64 64x64"      "$FAV/favicon-64.png"   "64 x 64"

assert_file_exists        "apple-touch-icon exists"  "$FAV/apple-touch-icon.png"
assert_dimensions         "apple-touch-icon 180x180" "$FAV/apple-touch-icon.png"  "180 x 180"

assert_file_exists        "favicon.ico exists"    "$FAV/favicon.ico"

# ---------- Summary ----------

echo
echo "Brand assets: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
    for n in "${FAILED_NAMES[@]}"; do echo "  ✗ $n"; done
    exit 1
fi
exit 0
```

- [ ] **Step 2: Make the script executable and run it**

```bash
chmod +x tests/test-brand-assets.sh
bash tests/test-brand-assets.sh
```

Expected: `Brand assets: 11 passed, 0 failed` and exit 0.

If any fail: re-run `python tools/render_brand_assets.py all` and retry.

- [ ] **Step 3: Hook into tests/run-tests.sh**

Open `tests/run-tests.sh`. At the bottom (just before the final summary block, or in the existing exit-handling section), add a call to the new script. The existing file ends with something like:

```bash
echo
echo "$PASS passed, $FAIL failed"
# ...
```

Insert before that final summary:

```bash
# ---------- NEWELL brand assets ----------

if bash "$(dirname "$0")/test-brand-assets.sh"; then
    :
else
    FAIL=$((FAIL + 1))
    FAILED_NAMES+=("brand-assets-suite")
fi
```

Adjust the variable names to match what `run-tests.sh` actually uses (it uses `PASS`, `FAIL`, `FAILED_NAMES` per the existing header — confirm by reading the file).

- [ ] **Step 4: Run the full suite**

```bash
bash tests/run-tests.sh
```

Expected: existing tests still pass + new brand asset tests pass. Final exit 0.

- [ ] **Step 5: Commit**

```bash
git add tests/test-brand-assets.sh tests/run-tests.sh
git commit -m "Add NEWELL brand asset tests (bash, 11 assertions)"
```

---

## Task 5: Static landing page (index.html)

**Files:**
- Create: `index.html`
- Create: `assets/site.css`

- [ ] **Step 1: Write index.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>git hygiene — Tools don't get co-author credit.</title>
<meta name="description" content="Two git hooks, zero dependencies. Strips AI-attribution trailers, catches secrets before they land in your object store.">

<!-- Favicon set -->
<link rel="icon" type="image/png" sizes="16x16"  href="assets/favicons/favicon-16.png">
<link rel="icon" type="image/png" sizes="32x32"  href="assets/favicons/favicon-32.png">
<link rel="icon" type="image/png" sizes="64x64"  href="assets/favicons/favicon-64.png">
<link rel="apple-touch-icon" sizes="180x180" href="assets/favicons/apple-touch-icon.png">
<link rel="shortcut icon" href="assets/favicons/favicon.ico">

<!-- Open Graph -->
<meta property="og:title"       content="git hygiene — Tools don't get co-author credit.">
<meta property="og:description" content="Two git hooks, zero dependencies. Strips AI trailers, catches secrets.">
<meta property="og:image"       content="https://JordanNewell.github.io/git-hygiene/assets/og.png">
<meta property="og:url"         content="https://JordanNewell.github.io/git-hygiene/">
<meta property="og:type"        content="website">
<meta name="twitter:card"       content="summary_large_image">

<link rel="stylesheet" href="assets/site.css">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500;700&display=swap" rel="stylesheet">
</head>
<body>
<main class="hero" role="main">
    <div class="hero__scanlines" aria-hidden="true"></div>
    <div class="hero__inner">
        <span class="receipt">2026-07-30 / v1.0.0 / SKU: GH-100</span>

        <div class="hero__grid">
            <div class="hero__copy">
                <h1 class="wordmark">git hygiene</h1>
                <p class="tagline">
                    <strong>Tools don't get co-author credit.</strong>
                    Two git hooks, zero dependencies beyond <code>bash</code>/<code>grep</code>/<code>awk</code>/<code>git</code>.
                    Strips AI-attribution trailers. Catches secrets before they land in your object store.
                </p>
                <p class="cta">
                    <a class="cta__primary" href="https://github.com/JordanNewell/git-hygiene#readme">Read the README</a>
                    <a class="cta__secondary" href="https://github.com/JordanNewell/git-hygiene/releases">Releases</a>
                </p>
            </div>

            <aside class="spec" aria-label="Project specifications">
                <div class="spec__row"><span class="spec__key">PLATFORM</span>     <span class="spec__val">bash · zsh</span></div>
                <div class="spec__row"><span class="spec__key">DEPENDENCIES</span> <span class="spec__val ok">zero</span></div>
                <div class="spec__row"><span class="spec__key">HOOKS</span>        <span class="spec__val">commit-msg · pre-commit</span></div>
                <div class="spec__row"><span class="spec__key">LAYERS</span>       <span class="spec__val">regex · gitleaks · opsec</span></div>
                <div class="spec__row"><span class="spec__key">TELEMETRY</span>    <span class="spec__val ok">none</span></div>
                <div class="spec__row"><span class="spec__key">LICENSE</span>      <span class="spec__val">MIT</span></div>
            </aside>
        </div>

        <footer class="hero__footer">
            <span class="brand">NEWELL &nbsp;/&nbsp; BUILD. CONNECT. GROW.</span>
            <span class="meta">v1.0.0 · 2026-07-30</span>
        </footer>
    </div>
</main>
</body>
</html>
```

- [ ] **Step 2: Write assets/site.css**

```css
/* git-hygiene landing page — NEWELL brand system (tokens from tokens.json) */
:root {
    --bg: #0A0A0A;
    --surface: #0F0F0F;
    --border: #1F1F1F;
    --text: #FFFFFF;
    --muted: #A0A0A0;
    --primary: #00FF41;
    --accent: #1AFF72;
    --radius-sm: 4px;
    --radius-md: 8px;
}

* { box-sizing: border-box; }

html, body {
    margin: 0;
    padding: 0;
    background: var(--bg);
    color: var(--text);
    font-family: 'JetBrains Mono', ui-monospace, monospace;
    font-size: 14px;
    line-height: 1.5;
}

.hero {
    min-height: 100vh;
    padding: 64px;
    border: 1px solid var(--border);
    margin: 16px;
    position: relative;
    overflow: hidden;
}

.hero__scanlines {
    position: absolute; inset: 0;
    background: repeating-linear-gradient(
        0deg, transparent 0 7px, rgba(255,255,255,0.015) 7px 8px
    );
    pointer-events: none;
}

.hero__inner {
    position: relative;
    max-width: 1200px;
    margin: 0 auto;
}

.receipt {
    display: inline-block;
    padding: 6px 12px;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-sm);
    font-size: 12px;
    color: var(--muted);
    letter-spacing: 0.04em;
}

.hero__grid {
    display: grid;
    grid-template-columns: 1.6fr 1fr;
    gap: 48px;
    margin-top: 32px;
}

.wordmark {
    font-family: 'Space Grotesk', system-ui, sans-serif;
    font-weight: 700;
    font-size: clamp(44px, 8vw, 88px);
    letter-spacing: -0.04em;
    line-height: 0.95;
    margin: 0 0 16px;
    color: var(--text);
}

.tagline {
    font-size: 14px;
    line-height: 1.6;
    color: var(--muted);
    max-width: 520px;
}
.tagline strong { color: var(--text); font-weight: 500; }
.tagline code {
    font-family: inherit;
    color: var(--text);
    background: var(--surface);
    padding: 1px 5px;
    border-radius: var(--radius-sm);
}

.cta { margin-top: 24px; display: flex; gap: 12px; flex-wrap: wrap; }
.cta__primary, .cta__secondary {
    display: inline-block;
    padding: 10px 16px;
    font-family: 'JetBrains Mono', monospace;
    font-size: 12px;
    font-weight: 500;
    letter-spacing: 0.04em;
    text-decoration: none;
    border: 1px solid var(--border);
    border-radius: var(--radius-sm);
    transition: border-color 120ms ease;
}
.cta__primary {
    background: var(--primary);
    color: var(--bg);
    border-color: var(--primary);
}
.cta__primary:hover  { border-color: var(--accent); }
.cta__secondary { background: var(--surface); color: var(--text); }
.cta__secondary:hover { border-color: var(--muted); }

.spec {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-sm);
    padding: 20px;
    font-size: 11px;
    align-self: start;
}
.spec__row {
    display: flex;
    justify-content: space-between;
    padding: 8px 0;
    border-bottom: 1px solid var(--border);
}
.spec__row:last-child { border-bottom: none; }
.spec__key { color: var(--muted); letter-spacing: 0.04em; }
.spec__val { color: var(--text); }
.spec__val.ok { color: var(--primary); }

.hero__footer {
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-top: 1px solid var(--border);
    padding-top: 16px;
    margin-top: 48px;
    font-size: 11px;
    letter-spacing: 0.06em;
}
.brand { color: var(--primary); }
.meta  { color: var(--muted); }

@media (max-width: 720px) {
    .hero { padding: 32px; margin: 0; border: none; }
    .hero__grid { grid-template-columns: 1fr; }
}
```

- [ ] **Step 3: Verify locally**

Run: `python -m http.server 8080 --directory /e/dev/projects/git-hygiene`

Open: `http://localhost:8080/`

Confirm visually:
- Datasheet hero renders with receipt chip, accent rule (implied by colored receipt), wordmark, tagline, CTA buttons, spec table, brand footer
- Favicon shows in browser tab as GH monogram
- View page source → confirm `<meta property="og:image">` points to the GitHub Pages URL
- Resize to mobile width — grid stacks, padding reduces

Stop the server when done: `Ctrl+C` in the terminal.

- [ ] **Step 4: Commit**

```bash
git add index.html assets/site.css
git commit -m "Add static landing page (datasheet hero, NEWELL tokens)"
```

---

## Task 6: README update — link to landing page

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add a "Landing page" section near the top of the README**

Open `README.md`. Find the existing intro block (the centered `<p>` with hero image and badges). Immediately after that block, add:

```markdown
## Landing page

Static site with the same datasheet hero: **https://jordannewell.github.io/git-hygiene/** (enable Pages from repo settings → main branch root, see `docs/superpowers/plans/2026-07-30-git-hygiene-site-branding.md` Task 7).

Source: `index.html` + `assets/site.css`. Regenerate brand assets with `python tools/render_brand_assets.py`.
```

- [ ] **Step 2: Verify README renders**

Open `README.md` in a markdown previewer. Confirm the new section sits cleanly between the intro and the existing "Tools don't get co-author credit" blockquote.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "Add landing page section to README (Pages URL)"
```

---

## Task 7: GitHub Pages enable + final validation

**Files:**
- Modify: nothing (manual repo setting)

- [ ] **Step 1: Enable GitHub Pages (manual)**

Open: `https://github.com/JordanNewell/git-hygiene/settings/pages`

Under "Build and deployment":
- Source: **Deploy from a branch**
- Branch: **main** / **root**
- Save

Wait 1–2 minutes. Refresh the page to see the deployed URL.

- [ ] **Step 2: Verify the live site**

Open: `https://jordannewell.github.io/git-hygiene/`

Confirm:
- Datasheet hero renders
- Favicon (GH monogram) appears in browser tab
- View source: `<meta property="og:image">` URL loads `assets/og.png`
- Test the OG unfurl: paste the URL into a Slack channel or https://www.opengraph.xyz/ — confirm the datasheet OG card appears

- [ ] **Step 3: Run the NEWELL pre-flight checklist**

Open `e:/vaults/anything.xyz/50_Projects/brand-system/pre-flight-checklist.md`. Walk through each item against:
- Live landing page (`https://jordannewell.github.io/git-hygiene/`)
- `assets/og.png`
- Each favicon in `assets/favicons/`

Any "fail" → fix in the render script or CSS, re-run `python tools/render_brand_assets.py all`, re-commit.

- [ ] **Step 4: Run the full bash test suite**

```bash
bash tests/run-tests.sh
```

Expected: all original hook tests pass + 11 new brand-asset assertions pass. Exit 0.

- [ ] **Step 5: Commit any fixes from validation**

If the pre-flight checklist surfaced fixes:

```bash
git add tools/render_brand_assets.py assets/ index.html assets/site.css
git commit -m "Apply pre-flight checklist fixes to brand assets"
```

If no fixes: skip this step.

---

## Task 8: Final ship verification

- [ ] **Step 1: Confirm git working tree is clean**

```bash
git status
```

Expected: `nothing to commit, working tree clean`.

- [ ] **Step 2: Confirm commits have no AI trailers**

```bash
git log --oneline -8
```

Confirm none of the 6–8 commits added in this plan contain `Co-Authored-By`, `Generated with`, `AI-assisted`, or similar. The repo's own `commit-msg` hook should have stripped any attempted trailer.

- [ ] **Step 3: Push**

```bash
git push origin main
```

Expected: pushes to `origin/main`. The repo's `pre-push` hook (`.githooks/pre-push` if installed, or per repo CI) may run — fix any findings, do not use `--no-verify`.

- [ ] **Step 4: Confirm CI passes on the pushed commit**

Open `https://github.com/JordanNewell/git-hygiene/actions`. Wait for the latest workflow run to complete. Expected: green check on `tests.yml`.

- [ ] **Step 5: Update MEMORY.md (auto memory)**

After shipping, save a project memory at `~/.claude/projects/C--Users-jrnew/memory/project_git-hygiene-branding-shipped-2026-07-30.md`:

```markdown
---
name: git-hygiene-branding-shipped-2026-07-30
description: git-hygiene landing page + OG + favicon set shipped 2026-07-30 using NEWELL datasheet pattern
metadata:
  type: project
---

git-hygiene branding shipped 2026-07-30. Pure NEWELL datasheet pattern.

**Why:** Existing retro 8-bit circular logo (`assets/hero.png` in repo — left untouched per scope) violated NEWELL anti-patterns (yellow, pixel font, centered-symmetric, decorative icon). Spec: `docs/superpowers/specs/2026-07-30-git-hygiene-site-branding-design.md`.

**How to apply:**
- Landing page: `jordannewell.github.io/git-hygiene/` — static `index.html` + `assets/site.css`
- OG card: `assets/og.png` (1200×630) — datasheet pattern
- Favicon set: `assets/favicons/` — GH monogram (white G + neon-green H, JetBrains Mono Bold)
- Render script: `tools/render_brand_assets.py` — reads canonical tokens from brand-system `tokens.json`, no hardcoded hex
- Tests: `tests/test-brand-assets.sh` — 11 bash assertions, hooked into `tests/run-tests.sh`

Decisions locked: Pure NEWELL (no sub-brand), Space Grotesk wordmark (pat-scanner precedent, commit 0698fbf on this repo), datasheet hero (Bloomberg-terminal coded), GH monogram favicon. See [[reference_brand-colors-black-white-neon-green]] for canonical tokens.
```

Add the index line to `~/.claude/projects/C--Users-jrnew/memory/MEMORY.md`:

```
- [👉 git-hygiene branding shipped 2026-07-30](project_git-hygiene-branding-shipped-2026-07-30.md) — datasheet OG + GH-monogram favicon + landing page. Pure NEWELL, Space Grotesk wordmark. Render script + 11 bash assertions.
```

---

## Self-Review

**Spec coverage check:**

| Spec section | Covered by |
|---|---|
| Decisions table | All 6 decisions encoded in code/config |
| Deliverable 1: Landing hero | Task 5 (`index.html` + `site.css`) |
| Deliverable 2: OG card 1200×630 | Task 2 (`render_og()` + `assets/og.png`) |
| Deliverable 3: Favicon set | Task 3 (`render_favicons()` + 5 files) |
| Typography stack | Task 2 (Space Grotesk + JetBrains Mono via `load_font`), Task 5 (Google Fonts CDN) |
| Color tokens (no deviation) | Task 1 (`load_tokens()` — single source of truth) |
| Spacing & radius | Tasks 2 + 5 (`grid()` helper, CSS vars) |
| Anti-patterns enforced | Task 7 Step 3 (pre-flight checklist) |
| Out of scope | Confirmed: `assets/hero.png` untouched, no PWA manifest, no favicon SVG |
| Open questions | Resolved at implementation: host = `jordannewell.github.io/git-hygiene/`, tech = static HTML, spec values = v1.0.0 reality |
| Validation | Task 7 Steps 3 + 4 (pre-flight + bash suite) |
| Acceptance | Task 8 (clean tree, no trailers, push, CI green) |

**Placeholder scan:** None. All code blocks complete. One intentional typo guard in Task 3 Step 1 (with explicit fix instructions).

**Type consistency:** `render_og()` and `render_favicons()` both consume `BrandTokens` from `load_tokens()`. `_render_gh_monogram()` is called by `render_favicons()`. Function names match across tasks.

**Scope:** Single implementation plan, produces working software (landing page live + assets rendered + tests passing). No sub-project decomposition needed.
