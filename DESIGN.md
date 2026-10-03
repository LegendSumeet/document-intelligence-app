---
name: Cognitive Minimal
colors:
  surface: '#121316'
  surface-dim: '#121316'
  surface-bright: '#38393c'
  surface-container-lowest: '#0d0e11'
  surface-container-low: '#1b1b1f'
  surface-container: '#1f1f23'
  surface-container-high: '#292a2d'
  surface-container-highest: '#343538'
  on-surface: '#e3e2e6'
  on-surface-variant: '#c7c4d7'
  inverse-surface: '#e3e2e6'
  inverse-on-surface: '#2f3034'
  outline: '#908fa0'
  outline-variant: '#464554'
  surface-tint: '#c0c1ff'
  primary: '#c0c1ff'
  on-primary: '#1000a9'
  primary-container: '#8083ff'
  on-primary-container: '#0d0096'
  inverse-primary: '#494bd6'
  secondary: '#4cd7f6'
  on-secondary: '#003640'
  secondary-container: '#03b5d3'
  on-secondary-container: '#00424e'
  tertiary: '#ddb7ff'
  on-tertiary: '#490080'
  tertiary-container: '#b76dff'
  on-tertiary-container: '#400071'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e1e0ff'
  primary-fixed-dim: '#c0c1ff'
  on-primary-fixed: '#07006c'
  on-primary-fixed-variant: '#2f2ebe'
  secondary-fixed: '#acedff'
  secondary-fixed-dim: '#4cd7f6'
  on-secondary-fixed: '#001f26'
  on-secondary-fixed-variant: '#004e5c'
  tertiary-fixed: '#f0dbff'
  tertiary-fixed-dim: '#ddb7ff'
  on-tertiary-fixed: '#2c0051'
  on-tertiary-fixed-variant: '#6900b3'
  background: '#121316'
  on-background: '#e3e2e6'
  surface-variant: '#343538'
typography:
  display-lg:
    fontFamily: Geist
    fontSize: 34px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: Geist
    fontSize: 26px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.025em
  headline-md:
    fontFamily: Geist
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: -0.02em
  headline-sm:
    fontFamily: Geist
    fontSize: 17px
    fontWeight: '600'
    lineHeight: 22px
    letterSpacing: -0.015em
  body-lg:
    fontFamily: Geist
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-md:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 21px
    letterSpacing: -0.005em
  body-sm:
    fontFamily: Geist
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0em
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-tablet: 1.5rem
  margin: 1rem
  margin-tablet: 2rem
  margin-desktop: 3rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1.25rem
  space-xl: 2rem
---

## Brand & Style

This design system embodies high-velocity document intelligence, synthesis, and deep research. It fuses the pragmatic rigor of Linear and Raycast with the calm, editorial legibility of Notion and Arc, engineered primarily for mobile interaction with desktop-grade density.

### Aesthetic Movement & Tenets
- **Precision Utility:** Every UI surface earns its place. Interfaces avoid gratuitous ornamentation in favor of micro-borders, controlled depth, and exact baseline alignment.
- **Atmospheric Clarity:** Fluid interactions and subtle optical blurs give contextual grounding while citations, extracts, and synthesized thoughts take center stage.
- **Electric Focus:** Neutral warm-gray backdrops act as quiet stages, allowing high-intensity indigo-violet accents to direct cognitive focus toward citations, semantic anchors, and AI generation flows.
- **Tactile Density:** Snappy transitions, micro-pill indicators, and distinct touch targets ensure that deep analytical work feels native, responsive, and tactile on handheld screens.

## Colors

The system is architected around a default dark-mode foundation with deliberate surface-to-ink pairings across modes:

### Surface Architecture
- **Canvas Base:**
  - Dark: `#121316` (Deep Obsidian Charcoal)
  - Light: `#FBFBFA` (Warm Alabaster)
- **Layer 01 Surface (Cards, Rows, Modals):**
  - Dark: `#1C1D22` (Subtle Smoked Charcoal)
  - Light: `#F4F4F3` (Soft Natural Gray)
- **Layer 02 Surface (Elevated Menus, Floats, Pills):**
  - Dark: `#24262D`
  - Light: `#EAEAE8`
- **Structural Outlines (1px crisp borders):**
  - Dark: `#282A30`
  - Light: `#E9E9E7`

### Accent & Semantic Expression
- **Primary Accent (`#6366F1`):** Electric Indigo. Used exclusively for generative AI states, key citations, primary actions, and focused input indicators.
- **Secondary Accent (`#06B6D4`):** Luminous Cyan. Reserved for cross-document entity linking, extraction highlights, and confidence metrics.
- **Tertiary Accent (`#A855F7`):** Refined Violet. Denotes complex multi-step syntheses, vector graph relationships, and metadata classification.
- **Text & Foreground:**
  - Dark Mode: Primary `#F3F4F6`, Muted `#9CA3AF`, Subtle/Ghost `#4B5563`
  - Light Mode: Primary `#111827`, Muted `#4B5563`, Subtle/Ghost `#9CA3AF`

## Typography

Typography prioritizes information density and analytical readability. We pair `Geist` for balanced, neutral, and razor-sharp structural hierarchy with `JetBrains Mono` for metadata tags, file extensions, citations, execution times, and document indexing metrics.

- **Numerics & Citations:** Always use tabular figures (`font-variant-numeric: tabular-nums`) inside tables, citation labels, and token counts.
- **Editorial Proportions:** Document reading interfaces default to `body-lg` with a maximum reading measure of 65 characters per line to reduce cognitive strain during prolonged analysis.
- **Monospace Labels:** Use uppercase transforms with widened letter spacing (`label-sm`) for status indicators, context pills, and schema tags.

## Layout & Spacing

The layout is built on a strict 4px sub-grid, with primary structural rhythm anchored at 8px multiples.

### Grid & Form Factors
- **Mobile (<640px):** Single-column layout framed by 16px (`1rem`) screen margins. Bottom navigation bar floats 16px above the home indicator safe area with inset lateral padding.
- **Tablet (640px–1024px):** 6-column fluid grid with 24px (`1.5rem`) gutters and 32px (`2rem`) outer margins. Supports side-by-side document comparison and an inspection drawer.
- **Desktop (>1024px):** 12-column fixed/fluid hybrid centered up to a max width of 1280px, enabling persistent tri-pane navigation (Sources / Workspace / Intelligence Hub).

### Vertical Rhythm & Density Rules
- Content cards and document feeds maintain consistent gap spacing via `space-md` (12px).
- Internal component padding uses `space-sm` (8px) for condensed data badges and `space-lg` (20px) for analytical summary blocks.

## Elevation & Depth

Visual depth avoids muddy drop-shadows, using instead layered structural luminance, frosted glass blurs, and crisp 1px borders.

### Depth Hierarchy
1. **Level 0 (Base Canvas):** Solid non-reflective neutral `#121316` (Dark) / `#FBFBFA` (Light).
2. **Level 1 (Structural Containers):** Raised surface `#1C1D22` outlined with a hairline 1px border `#282A30` (`#E9E9E7` in light mode). No shadow.
3. **Level 2 (Interactive Floating Modules & Modals):** Surface `#24262D` with a subtle diffuse ambient drop:
   `box-shadow: 0 12px 32px -8px rgba(0, 0, 0, 0.45), 0 0 0 1px #282A30`.
4. **Header & Navigation Frost:** Translucent surface with `backdrop-filter: blur(20px) saturate(180%)` backed by 80% surface opacity (`rgba(18, 19, 22, 0.8)`).
5. **AI Focus Halo:** Active synthesis queries and highlighted citations apply an inner/outer chromatic glow:
   `box-shadow: 0 0 0 1px #6366F1, 0 0 16px -2px rgba(99, 102, 241, 0.25)`.

## Shapes

The interface balances sharp technological precision with tactile human ergonomics using Level 2 roundedness tokens.

- **Primary Cards & Modals:** Standardized corner radius of `rounded-lg` (16px / 1rem) creates clear container boundaries while remaining compact on mobile viewports.
- **Interactive Inputs & Nested Items:** Form inputs, row items, and list selectors use base roundedness (8px / 0.5rem).
- **Pills, Badges & Micro-Citations:** Fully circular caps (`border-radius: 9999px`) provide contrast against rectangular cards, making sources and tags instantly recognizable as distinct tactile units.

## Components

### Buttons
- **Primary CTA:** Background `#6366F1`, text `#FFFFFF`, rounded 8px, 1px top border `rgba(255, 255, 255, 0.2)`. Active state applies a scale transform (`transform: scale(0.98)`).
- **Secondary / Ghost Button:** Neutral surface (`#1C1D22`), crisp 1px border (`#282A30`), text `#F3F4F6`. Hover introduces subtle surface illumination (`#24262D`).
- **Icon Actions:** 36x36px bounding boxes with centered 18px icons, rounded 8px, subtle 1px border.

### Citation & Extraction Badges (Pills)
- Compact pill height (24px) utilizing `JetBrains Mono` at `label-sm`.
- Styled with surface background (`rgba(99, 102, 241, 0.1)` in Dark Mode), 1px border (`rgba(99, 102, 241, 0.3)`), and electric indigo text (`#818CF8`).
- Clicking opens a source attribution sheet with exact page, paragraph, and confidence percentage.

### Input Fields & Search Bars (Raycast Style)
- Prominent omni-search input bar with 48px height, 12px rounded corners, and a 1px border (`#282A30`).
- Prefix search icon with contextual keyboard shortcut indicator (`⌘K` rendered in mono badge).
- Focused state applies an electric indigo boundary with subtle 12px blur halo.

### Cards & Synthesis Tiles
- Bounded by 1px border `#282A30` over `#1C1D22`.
- Content padding set to 16px (`1rem`).
- Header displays document icon, file type tag, and timestamp, divided from body with a hairline separator rule.

### Bottom Navigation
- Suspended island style floating 16px above the device base with 80% opacity blur backing.
- Height: 56px; rounded 28px (pill shape).
- Contains primary tabs: `Synthesize`, `Sources`, `Extracts`, `Profile`.
- Active tab features an indigo dot indicator beneath the icon and an energized icon tint.

### Document Highlight Marks
- Contextually highlighted text inside parsed documents utilizes semi-transparent linear-gradient underlays (`rgba(99, 102, 241, 0.18)` for AI citations; `rgba(6, 182, 212, 0.18)` for key entities).