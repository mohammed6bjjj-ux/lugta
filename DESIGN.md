---
name: "لكطة — Lugta"
description: "A bright, confident mobile commerce system for Iraqi resellers."
colors:
  royal-purple: "#37379B"
  royal-purple-light: "#BEB8FF"
  vivid-yellow: "#FCC803"
  yellow-ink: "#6A5600"
  light-canvas: "#F8F8FD"
  light-surface: "#FFFFFF"
  light-surface-alt: "#F0EFF9"
  light-ink: "#202035"
  light-muted: "#67667A"
  light-divider: "#E2E1EE"
  dark-canvas: "#11111A"
  dark-surface: "#191925"
  dark-surface-alt: "#242438"
  dark-ink: "#F6F5FC"
  success: "#167A52"
  warning: "#9A5A00"
  error: "#C53D4B"
  info: "#3566C2"
typography:
  display:
    fontFamily: "Zain"
    fontSize: "48dp"
    fontWeight: 700
    lineHeight: 1.25
  headline:
    fontFamily: "Zain"
    fontSize: "30dp"
    fontWeight: 700
    lineHeight: 1.34
  title:
    fontFamily: "Zain"
    fontSize: "20dp"
    fontWeight: 700
    lineHeight: 1.42
  body:
    fontFamily: "Zain"
    fontSize: "16dp"
    fontWeight: 400
    lineHeight: 1.65
  label:
    fontFamily: "Zain"
    fontSize: "14dp"
    fontWeight: 700
    lineHeight: 1.45
rounded:
  sm: "10dp"
  md: "14dp"
  lg: "16dp"
  xl: "22dp"
spacing:
  xs: "4dp"
  sm: "8dp"
  md: "16dp"
  lg: "24dp"
  xl: "32dp"
  xxl: "48dp"
components:
  button-primary:
    backgroundColor: "{colors.royal-purple}"
    textColor: "{colors.light-surface}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    padding: "0 24dp"
    height: "56dp"
  button-accent:
    backgroundColor: "{colors.vivid-yellow}"
    textColor: "{colors.light-ink}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    padding: "0 24dp"
    height: "56dp"
  card:
    backgroundColor: "{colors.light-surface}"
    textColor: "{colors.light-ink}"
    rounded: "{rounded.lg}"
    padding: "16dp"
  input:
    backgroundColor: "{colors.light-surface-alt}"
    textColor: "{colors.light-ink}"
    rounded: "{rounded.md}"
    padding: "15dp 16dp"
---

# Design System: لكطة — Lugta

## Overview

**Creative North Star: "The Bright Trade Counter"**

Lugta turns a dense reseller workflow into a bright, legible trade counter. Royal purple gives every primary action authority, while vivid yellow marks rewards, progress, and moments worth noticing. White and lavender working surfaces keep price, stock, profit, customer, and order information easy to scan without returning to the old green-and-cream visual world.

The system is compact but never cramped. It is designed first for one-handed mobile use in Arabic and Kurdish RTL, while the same geometry and hierarchy remain natural in English LTR. The smiling shopping-bag mark is the only decorative signature; operational screens stay task-led and quiet.

**Key Characteristics:**

- Royal purple actions and vivid yellow emphasis.
- Zain typography across Arabic, Kurdish, and English.
- Compact rounded geometry with restrained ambient depth.
- Semantic success, warning, error, and information colors independent of the brand pair.
- Complete light and dark modes, RTL/LTR parity, and motion that respects Reduce Motion.

## Official Logo Artwork

The source of truth is the designer-supplied export pack, not a traced or
reconstructed mark. The primary horizontal lockup uses the purple `LU`, yellow
bag-shaped `g`, and yellow `ta` shown in the identity guide. The matching
primary icon uses a yellow body with a purple handle and facial details.

- Use the full-colour lockup on white and very light neutral surfaces.
- Use the white lockup on purple and other dark brand surfaces.
- Use the single-purple lockup when a one-colour light-surface mark is needed.
- Use the black symbol only as an Android monochrome mask; Android supplies the
  user-selected system colour.
- Preserve the original aspect ratio, clear space, and orientation. Never
  mirror the mark in RTL and never recolour individual logo parts.

## Colors

The palette combines a confident royal-purple spine with a vivid-yellow signal color and cool, low-noise working surfaces.

### Primary

- **Royal Purple:** The identity color for primary buttons, active navigation, step progress, links, and decisive prices.
- **Soft Royal Purple:** The dark-mode primary foreground and a secondary highlight when full royal purple would be too low-contrast.

### Secondary

- **Vivid Yellow:** Used for rewards, selected accents, notification counts, progress indicators, and the final action in a journey.
- **Yellow Ink:** Used for text and icons on pale yellow surfaces. It preserves contrast without muting the yellow character.

### Tertiary

- **Semantic Green, Amber, Red, and Blue:** Status colors communicate success, warning, error, and information. They are not replaced with purple or yellow because status must remain unambiguous.

### Neutral

- **Cool Canvas:** The light-mode page field, slightly separated from pure-white cards.
- **White Surface:** The principal light-mode card, sheet, and navigation material.
- **Lavender Surface:** Filled inputs, secondary containers, loading placeholders, and tonal grouping.
- **Ink and Muted Ink:** Primary reading color and metadata color.
- **Dark Canvas and Violet-Black Surfaces:** Dark mode uses violet-black depth rather than pure black.

### Named Rules

**The Yellow Is a Signal Rule.** Yellow marks emphasis or reward; it never becomes the default page background or the default text color.

**The No White on Yellow Rule.** Text and icons over yellow always use dark ink. White over yellow is not an approved combination.

**The Semantic Status Rule.** Success, warning, error, and information keep their dedicated semantic hues in both themes.

## Typography

**Display Font:** Zain (local ExtraLight, Regular, and Bold assets)

**Body Font:** Zain

**Character:** Zain gives the product one voice across all three supported languages. Its rounded terminals suit the logo geometry, while generous Arabic line heights keep dense financial and order information readable.

### Hierarchy

- **Display** (700, 48dp, 1.25): Rare campaign or onboarding statements.
- **Headline** (700, 22–30dp, 1.34–1.40): Screen titles, money totals, and major empty states.
- **Title** (700, 14–20dp, 1.42–1.52): Card titles, section headings, and row names.
- **Body** (400, 12–16dp, 1.58–1.65): Instructions, descriptions, metadata, and policy text.
- **Label** (700, 11–14dp, 1.45): Buttons, chips, navigation, state labels, and compact figures.

### Named Rules

**The One Typeface Rule.** Zain is the application typeface in Arabic, Kurdish, and English; platform fonts are fallbacks only.

**The Numbers Stay Legible Rule.** Prices, phone numbers, stock, and order identifiers may use the surrounding locale direction, but they must never be compressed below the label scale or clipped.

## Layout

The base rhythm is 8dp, with 4dp used only for tight internal relationships. Screen gutters are normally 16dp; major groups separate by 24dp or 32dp. Primary actions sit within easy thumb reach, and persistent bottom navigation keeps the five highest-frequency destinations visible.

Every layout must remain usable at 320 logical pixels and at 200% text scale. Repeated content uses flexible rows, wrapping labels, and directional alignment rather than fixed-width text. RTL and LTR share the same information hierarchy; directional padding and alignment are mandatory. Touch targets are never smaller than 48dp.

## Elevation & Depth

Depth is ambient and functional. Cards use a soft low shadow plus a faint divider-colored edge, while sheets and fixed action bars use the stronger floating shadow. Yellow actions may use a restrained yellow glow. Dark mode relies more on tonal separation than shadow.

### Shadow Vocabulary

- **Card:** 20dp blur with a 7dp vertical offset and low-opacity violet-black shadow.
- **Floating:** 28dp blur with a 12dp vertical offset for sheets and persistent action surfaces.
- **Accent Glow:** 18dp yellow glow with a 7dp vertical offset, limited to emphasized yellow actions.

### Named Rules

**The Ambient Depth Rule.** Shadows separate working layers; they never become hard outlines or decorative offset blocks.

## Shapes

The form language is compact and rounded: 10dp for small chips and controls, 14dp for buttons and fields, 16dp for cards, and 22dp for large panels and sheets. Full pills are reserved for small status capsules and navigation selection. Product imagery is clipped to the card system, and thin borders use the theme divider rather than arbitrary gray.

## Components

### Buttons

- **Shape:** Compact rounded rectangle (14dp), 56dp high for application primary actions; Material actions may use 52dp.
- **Primary:** Royal purple with white or theme `onPrimary` text.
- **Accent:** Yellow gradient with dark `onAccent` text, reserved for a final action or a reward-related action.
- **Secondary:** Surface background, subtle divider border, primary or ink text, and ambient card shadow.
- **State:** Disabled buttons use the semantic disabled fill. Press feedback scales only when Reduce Motion is off.

### Chips

- **Style:** Neutral lavender surface and thin divider border at rest.
- **State:** Selected chips use the primary color with `onPrimary` text. Status chips use semantic soft backgrounds and matching semantic ink.

### Cards / Containers

- **Corner Style:** 16dp by default; 22dp for major panels.
- **Background:** Theme surface, with lavender or violet-black alternates for grouping.
- **Shadow Strategy:** Ambient card shadow, plus a faint divider edge.
- **Internal Padding:** 16dp standard; 8dp for compact media tiles; 24dp for major summaries.

### Inputs / Fields

- **Style:** Filled lavender or dark tonal surface, 14dp corners, 16dp horizontal padding.
- **Focus:** Two-pixel primary border with a primary floating label.
- **Error / Disabled:** Semantic error stroke and label; disabled content uses the theme disabled fill and muted ink.

### Navigation

Bottom navigation is a floating tonal dock with 48dp-or-larger targets. The active destination uses a royal-purple pill, white text, and a yellow icon accent. Badges use yellow with dark ink. Headers prioritise the screen task, with search and cart/favourite/notification actions grouped below or beside the wordmark according to available width.

### Product and Price Surfaces

Product cards use a square media field, compact status badges, one-line product naming, a strong purple wholesale price, and subdued comparison information. Price summaries lead with the seller's margin, preserve the visual distinction between merchandise, packaging, delivery, and discount, and use semantic green only for positive profit or a confirmed saving.

## Do's and Don'ts

### Do:

- **Do** use semantic palette roles from `AppColors`; every component must work in both palettes.
- **Do** use directional spacing and test every new surface in Arabic/Kurdish RTL and English LTR.
- **Do** keep all interactive targets at least 48dp and preserve usability at 200% text scale.
- **Do** use yellow sparingly for rewards, selected accents, and journey completion.
- **Do** stop or remove nonessential animation when Reduce Motion is enabled.

### Don't:

- **Don't** restore the former green, cream, or `gold*` visual vocabulary.
- **Don't** place white text or white icons on the yellow accent.
- **Don't** use pure black as the dark-mode application surface; use the violet-black tonal stack.
- **Don't** introduce hard offset shadows, glass blur, or ornamental gradients unrelated to the purple/yellow identity.
- **Don't** hard-code physical left/right layout when a directional equivalent exists.
- **Don't** ship mixed names such as Luqta, لقطة, لُگطة, or لُكطة; the product name is «لكطة — Lugta».
