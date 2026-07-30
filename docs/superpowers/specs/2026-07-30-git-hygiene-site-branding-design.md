# git-hygiene Site Branding — Design Spec

**Date:** 2026-07-30
**Repo:** `JordanNewell/git-hygiene` (v1.0.0)
**Surfaces:** Landing page hero, favicon set, Open Graph card
**Brand system:** NEWELL (Pure — no product sub-brand)

## Context

git-hygiene ships two zero-dependency git hooks: `commit-msg` (strips AI-attribution trailers) and `pre-commit` (catches secrets via regex + optional gitleaks + optional OPSEC content scan). The repo's voice — "Tools don't get co-author credit" — is already NEWELL-native: brutalist, engineering-first, anti-slop.

The existing branding is a retro 8-bit circular badge (`~/Downloads/git.hygene..png`): pixelated font, hand-with-broom icon, yellow stars, symmetric circular layout. Multiple NEWELL anti-patterns (yellow, pixel font, decorative icon, centered-symmetric). The repo's README references `assets/hero.png` (out of scope to touch).

This spec defines the branding for a dedicated landing page (e.g. `jordannewell.github.io/git-hygiene`, matching the pat-scanner pattern), a favicon set, and an OG card for link unfurls.

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Scope | Landing page + favicon + OG | README hero swap and full identity set explicitly out of scope |
| Brand approach | Pure NEWELL | No product sub-brand; matches fleet consistency |
| Hero layout | Engineering datasheet | Spec-table forward; Bloomberg-terminal coded; matches engineering voice |
| Wordmark face | Space Grotesk Bold | Pat-scanner precedent (commit 0698fbf on this very repo swapped Newell → Space Grotesk for non-NEWELL display text) |
| Wordmark case | lowercase "git hygiene" | Approachable, distinguishes from canonical uppercase NEWELL wordmark |
| Favicon concept | GH monogram | White G + neon-green H in JetBrains Mono Bold; mirrors canonical NEWELL wordmark's green-E pattern |

## Deliverables

### 1. Landing page hero

**Layout (datasheet pattern, left-weighted):**
- Receipt chip (top-left): `2026-07-30 / v1.0.0 / SKU: GH-100`
- Accent rule: 2px tall, 64px wide, `#00FF41`, 20px below chip
- Left column (1.6fr):
  - Wordmark: `git hygiene` in Space Grotesk Bold, ~72px desktop / ~44px mobile, `letter-spacing: -0.04em`, `line-height: 0.95`
  - Tagline: `**Tools don't get co-author credit.** Two git hooks, zero dependencies beyond bash/grep/awk/git. Strips AI-attribution trailers. Catches secrets before they land in your object store.` JetBrains Mono Medium, muted `#A0A0A0`, 13px, max-width 460px
- Right column (1fr): spec table
  - Surface `#0F0F0F` fill, 1px `#1F1F1F` border, 20px padding
  - 6 rows: PLATFORM / DEPENDENCIES / HOOKS / LAYERS / TELEMETRY / LICENSE
  - Keys: muted mono 11px; values: white mono 11px; positive states (zero, none) in `#00FF41`
- Brand footer: 1px `#1F1F1F` top border, 14px padding-top, 24px margin-top
  - Left: `NEWELL  /  BUILD. CONNECT. GROW.` in `#00FF41`, 10px, `letter-spacing: 0.06em`
  - Right: `v1.0.0 · 2026-07-30` in muted, 10px

**Frame:**
- Background: `#0A0A0A` (OLED black, not pure)
- Border: 1px `#1F1F1F` hairline on canvas edge
- Texture: 8px-pitch scanline overlay at `rgba(255,255,255,0.015)` — material depth, stays inside anti-pattern budget
- Outer gutter: 64px desktop / 32px mobile (8px grid)

### 2. OG card (1200×630)

**Pattern:** datasheet adapted to landscape. Same component vocabulary — receipt chip, accent rule, wordmark, tagline, brand footer.

**Layout:**
- Receipt chip top-left: `2026-07-30 / v1.0.0 / git-hygiene`
- Accent rule: 2px × 36px, primary green
- Wordmark: `git hygiene`, Space Grotesk Bold, ~64px
- Tagline: `**Tools don't get co-author credit.** Two git hooks, zero dependencies. Strips AI trailers, catches secrets.` JetBrains Mono Medium, muted, max-width 70% of canvas
- Footer: `NEWELL  /  BUILD. CONNECT. GROW.` (primary) + `MIT · BASH · ZERO-DEP` (muted)

**Render path:** Extend `e:/vaults/anything.xyz/50_Projects/brand-system/templates/og-template.py` with a `render_gh_og()` variant. Uses canonical token loader; no hardcoded hex. Output: `assets/og.png` at 1200×630 (note: template is currently 1280×640 — adjust CANVAS_W/CANVAS_H or pre-resize).

### 3. Favicon set

**Mark:** `GH` monogram, JetBrains Mono Bold
- `G` in `#FFFFFF`
- `H` in `#00FF41` (mirrors canonical NEWELL wordmark's green-E horizontals)
- Background: `#0A0A0A`
- Border: 1px `#1F1F1F`
- `letter-spacing: -0.04em` (tight pair to balance the G's visual weight against the H)

**Sizes:**
| File | Dimensions | Purpose |
|---|---|---|
| `favicon-16.png` | 16×16 | Browser tab |
| `favicon-32.png` | 32×32 | Browser tab (retina) |
| `favicon-64.png` | 64×64 | Desktop shortcut |
| `apple-touch-icon.png` | 180×180 | iOS home screen |
| `favicon.ico` | multi-res | Legacy (16+32+64 embedded) |

**192/512 PWA sizes:** skipped unless a manifest.webmanifest is added later (deferred).

**Render path:** PIL script, source `G` and `H` glyphs from JetBrains Mono Bold TTF (already on system per og-template.py:36-41). Output PNGs to `assets/favicons/`.

## Typography stack

| Role | Face | Weight | Where |
|---|---|---|---|
| Display (wordmark) | Space Grotesk | 700 | Hero wordmark, OG wordmark |
| Body mono | JetBrains Mono | 400 / 500 | Tagline, spec values, footer, receipt chip |
| Mark | JetBrains Mono | 700 | Favicon GH monogram |
| Newell face | — | — | NOT used in v0.1 (per `display_mark.use: brand mark only` in tokens.json) |

Web font loading: Google Fonts CDN (`Space Grotesk:wght@400;500;600;700` + `JetBrains+Mono:wght@400;500;700`). Self-host only if landing page needs offline reliability — not in v0.1 scope.

## Color tokens (canonical NEWELL — no deviation)

| Token | Hex | Where used |
|---|---|---|
| `background` | `#0A0A0A` | All canvas backgrounds (NOT pure `#000000`) |
| `surface` | `#0F0F0F` | Receipt chip, spec table fill, favicons border-inset |
| `border` | `#1F1F1F` | All hairlines (canvas edge, spec table, footer, favicon) |
| `text` | `#FFFFFF` | Wordmark, spec values, G in monogram |
| `muted` | `#A0A0A0` | Tagline, receipt chip text, spec keys, footer meta |
| `primary` | `#00FF41` | Accent rule, H in monogram, brand-line text, positive spec values |
| `accent` | `#1AFF72` | Reserved (not used in v0.1 — keep in pocket for hover/active states if site grows interactivity) |

## Spacing & radius

- 8px grid: `[4, 8, 12, 16, 24, 32, 48, 64, 96, 128]`
- Radius: `sm=4` (receipt chip), `md=8` (button if any), `lg=12` (cards if any), `xl=20` (unused in v0.1), `full=9999` (unused)

## Anti-patterns enforced (per SSOT § Anti-Patterns)

None of the following appear in any deliverable:

- Indigo / violet / any non-NEWELL hue
- Gradients, shadows, glow effects, glassmorphism
- Pixel-noise / Tron-grid / scanline-at-high-contrast backgrounds (current scanline is `rgba(255,255,255,0.015)` — barely visible, material hint only)
- Decorative emoji, icons, stars, dots
- Stock imagery
- Centered-symmetric layouts (datasheet is intentionally left-weighted; right column carries spec data, not symmetry)
- Inter or default sans-serif as display face

## Out of scope

- **README hero swap.** The existing `assets/hero.png` (retro circular badge) stays in the README. If/when Jordan wants to retire it, that's a separate change.
- **Full identity set / brand guide.** No logo lockup variations, no stacked/horizontal lockups, no InDesign-style guide PDF.
- **Newell face usage.** Deferred to NEWELL v0.2 (when `display_mark.use` broadens). All v0.1 display text uses Space Grotesk.
- **PWA manifest.** No 192/512 favicon sizes unless a manifest is added.
- **Favicon SVG.** PNG only for v0.1 (broader browser support; SVG can be added later).
- **Landing page implementation itself.** This spec covers branding assets only. Implementation (HTML/CSS/framework choice, deployment to Pages) follows in the writing-plans phase.

## Open questions (non-blocking, resolved at implementation)

1. **Landing page host.** Assumed `jordannewell.github.io/git-hygiene` (matches pat-scanner). Confirm at implementation.
2. **Landing page tech.** Static HTML (like curtis-compliance-pro splash) vs Jekyll vs Astro. Recommendation: static HTML — minimal, no build step, no Jekyll-on-Astro gotcha. Decide at implementation.
3. **Spec table content.** Values above (`bash · zsh`, `zero`, `commit-msg · pre-commit`, `regex · gitleaks · opsec`, `none`, `MIT`) reflect v1.0.0 reality. Update on minor version bumps.

## Validation

Before any asset ships:

1. **Pre-flight checklist** at `e:/vaults/anything.xyz/50_Projects/brand-system/pre-flight-checklist.md` against every rendered surface (hero, OG, each favicon size).
2. **Token audit** via `figma_audit_brand_drift` MCP tool if any Figma source is used (none planned for v0.1).
3. **Pixel-diff** the OG against the canonical NEWELL OG template (`sample-og.png` in brand-system/templates/) to confirm grid alignment matches.
4. **Favicon legibility test:** open `favicon-16.png` at 1:1 in a browser tab against 10+ other tabs; the GH must read at a glance.

## Acceptance

- [ ] `assets/og.png` renders the datasheet OG at 1200×630
- [ ] `assets/favicons/{16,32,64,180}.png` + `favicon.ico` generated
- [ ] Hero mockup translatable to landing-page HTML in implementation phase
- [ ] Pre-flight checklist passes on all four surfaces
- [ ] Commit message follows repo convention (e.g. `Add NEWELL site branding: datasheet OG + favicon set`) with **no AI-attribution trailer** (per repo policy and `~/.githooks/commit-msg`)
