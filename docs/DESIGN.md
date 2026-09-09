# Tibasasa Style Reference

The design system established on the public landing page (`lib/medcamp_web/live/home_live.ex`).
This is the reference for **public / marketing surfaces** and the shared discipline
(type, spacing, radius, elevation, motion, copy) that **every** screen follows,
including screens ported from `medic`.

> Scope split
> - **Shared everywhere** (public + authenticated, medic ports included): typography,
>   spacing scale, radius vocabulary, zero-shadow elevation, motion, the Don't list,
>   copy discipline.
> - **Public surfaces only** — the landing page, every pre-authentication page
>   (`/users/log_in`, `/users/log_in/otp`, `/users/reset_password`,
>   `/users/reset_password/:token`, `/organisations/register`), and the
>   `/8018/:gsrn` camp pages: the fixed navy/cyan palette below. Shared chrome for
>   the auth pages lives in `MedcampWeb.AuthComponents`: `auth_split/1` is a
>   two-column layout on plain white (a bounded `rounded-2xl` hairline photo,
>   `lg:w-[44%]` / `h-[80vh]`, with whitespace around it inside a
>   `w-[90%] max-w-6xl` centred row; the form beside it — no card, no
>   slate-50 gutter); `auth_shell/1` wraps it with a title/subtitle/footer;
>   `auth_submit/1` is the navy pill.
> - **Authenticated operational screens**: keep the tenant `brand-*` CSS variables
>   (`assets/tailwind.config.js`, `Medcamp.Organisations.css_variables/1`) so each
>   organisation is themed — but map colour *roles* the same way this doc does.
>   See `.agents/repo/ui-system.md` for how to port a medic pattern.

Personality: **plain and trustworthy.** A logged-out door to an operational clinical
tool. Meets the category's blue/teal "trust" expectation on purpose. Distinctive
through restraint — fewer choices, each deliberate and consistently applied.

---

## Colour

Public palette — recite-able, every entry has one job.

| Token | Value | Job |
|---|---|---|
| Navy | `#0C2765` | Headings, primary button fill, dark section / footer background, icon-tile glyph |
| Navy hover | `#16418f` | Primary button `:hover` only |
| Accent cyan | `#52B2D8` | The one accent — a single keyword in the H1, link `:hover`, outline-button `:hover` border. **Never a fill or background.** At most one or two per screen. |
| Brand tint | `#e9f6fb` | Icon-tile backgrounds, the "Live data" chip. The only tinted surface. |
| Section A | `white` | Alternating section band; all cards |
| Section B | `slate-50` | Alternating section band |
| Border | `slate-200` | Every hairline border and divider |
| Outline border | `slate-300` | Secondary/outline button borders |
| Body text | `slate-600` | Paragraphs, card text |
| Meta text | `slate-500` | Labels, captions, the wordmark sub-label |
| Faint text | `slate-400` | Chart axis labels only |
| Semantic (success) | `emerald-50 / 200 / 500 / 700 / 900` | The **only** semantic colour. Used once — the reporting mock's "all stations reporting" note. |

**On dark** (footer, and any future dark block): `text-white`, `text-white/70`
(secondary), `text-white/55` (tertiary), `text-white/50` (copyright),
`border-white/10`–`/15` (dividers), `border-white/30` + `hover:bg-white/10`
(outline pills), primary button becomes `bg-white text-[#0C2765]`.

**Role mapping for authenticated screens:** `#0C2765` → `brand-primary`,
`#16418f` → `brand-accent-dark`, `#52B2D8` → `brand-accent`, `#e9f6fb` →
`brand-50`. Use the `brand-*` classes there, not the hex values.

---

## Typography

- **Family:** Plus Jakarta Sans (Google Fonts, weights **400 / 600 / 700**),
  fallback `ui-sans-serif, system-ui, -apple-system, 'Segoe UI', sans-serif`.
  Loaded per-page via `head_html` + an inline `style` on the page root, so the
  rest of the app keeps its system stack. Do not add it to `tailwind.config.js`.
- **Weights, one job each:** 400 body · 600 everything semibold (nav, buttons,
  card titles, labels, stat labels, wordmark sub-label) · 700 headings, stat
  values, wordmark. **No 500, no 800, no italic, no second family.**
- **Scale + tuned tracking/leading** (tighten tracking as size grows):

| Role | Classes |
|---|---|
| H1 | `text-4xl sm:text-5xl font-bold leading-[1.1] tracking-[-0.02em]` |
| H2 (section) | `text-3xl sm:text-4xl font-bold tracking-[-0.01em]` |
| H3 (card title) | `text-lg` or `text-xl`, `font-semibold`, default leading |
| Lead paragraph | `text-lg leading-relaxed text-slate-600` |
| Body / card text | base, `leading-relaxed text-slate-600` |
| Meta / caption | `text-sm text-slate-500` (`text-xs` for chips / axis) |
| Stat value | `text-3xl font-bold` |
| Wordmark | `text-base font-bold` |
| Wordmark sub-label | uppercase, `text-slate-500`, size + tracking scaled to length: `text-xs tracking-[0.14em]` for a short label, `text-[10px] tracking-[0.08em]` for a long one (the landing header's "Medical Camp Management System") |

The uppercase-tracked treatment is **reserved for the single wordmark
sub-label** — it is not a section-eyebrow device (see Don'ts).

---

## Spacing & layout

- **Base unit 4px** (Tailwind default scale). Every gap/pad/margin is on it.
- **Page shell:** `max-w-6xl` (1152px), `px-5 lg:px-8`. One width, everywhere.
- **Section rhythm:** `py-16` for compact sections (hero, closing CTA),
  `py-20` for content sections, `lg:py-24` on the hero.
- **Within a section:** heading → lead `mt-5`; heading/lead → grid `mt-10`/`mt-12`;
  card grids `gap-4`; two-column layouts `gap-12`.
- **Controls (micro tier):** primary/secondary buttons `px-6 py-3`; nav buttons
  `px-4 py-1.5`; icon tiles `h-11 w-11` / `h-12 w-12`.
- **Section shape:** full-bleed `<section>` with bg + border → inner
  `<div class="mx-auto max-w-6xl px-5 py-20 lg:px-8">` → `<h2>` → optional one
  lead `<p>` → card grid or 2-col. `scroll-mt-20` on any `id`'d section.

### Section background rhythm

Strict A/B alternation, used as the **only** section separator:

```
white → slate-50 → white → slate-50 → …  → footer (navy)
```

- Each `slate-50` section carries `border-y border-slate-200`; `white` sections
  carry no border (the colour shift separates them).
- **Exactly one dark block, and it is the finale (the footer).** Never a
  mid-page dark "island" — a dark band that isn't the ending reads as a break.

---

## Radius — role-based, 4 values

| Value | Class | Used for |
|---|---|---|
| Pill | `rounded-full` | All buttons, chips, circular badges |
| Card | `rounded-2xl` (16px) | Cards, panels, the dashboard mock |
| Hero image | `rounded-[2rem]` (32px) | Hero / feature **imagery only** — the one "large surface" value |
| Control | `rounded-xl` (12px) | Icon tiles, metric tiles, chart container |

`rounded-t` on chart bars is the only other use. **Never** mixed per-corner radii
(`rounded-tl-* rounded-br-*` …), `rounded-3xl`, or an arbitrary radius other than
`[2rem]` on hero images.

---

## Elevation

**Zero drop shadows.** No `shadow-*`, no `ring-*` decoration, no `backdrop-blur`.

Elevation is communicated only by:
- a 1px hairline `border-slate-200` (or `border-white/10`–`/30` on dark), and/or
- the alternating white / slate-50 section bands.

A white card on a `slate-50` section lifts through its border + the value shift.

---

## Motion

- **One transition:** `transition-colors duration-150` on every interactive
  element (links, buttons). Colour only.
- **No transforms** (`hover:-translate-*`, `hover:scale-*`), no entrance / scroll
  animations, no parallax.
- Sticky header is plain `sticky top-0 z-30` — always visible, no auto-hide.
- `prefers-reduced-motion`: nothing to disable — there is no motion beyond colour
  fades. Keep it that way.

---

## Buttons

| Variant | Light background | Dark background |
|---|---|---|
| Primary | `rounded-full bg-[#0C2765] px-6 py-3 text-base font-semibold text-white transition-colors duration-150 hover:bg-[#16418f]` | `bg-white text-[#0C2765] hover:bg-white/90` |
| Secondary | `rounded-full border border-slate-300 px-6 py-3 text-base font-semibold text-[#0C2765] transition-colors duration-150 hover:border-[#52B2D8]` | `border border-white/30 hover:bg-white/10` |
| Nav | same as above at `px-4 py-1.5 text-sm` | — |

- Icon + label: trailing `<.feather name="arrow-right" class="h-4 w-4" />`, `gap-2`.
- **Never:** gradient fill, glow, drop shadow, uppercase text, hover scale/translate.

---

## Icons

Feather-style inline SVG:
`viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
stroke-linecap="round" stroke-linejoin="round"`, `aria-hidden="true"`,
sized `h-4/5/6`. In an icon tile:
`grid place-items-center rounded-xl bg-[#e9f6fb] text-[#0C2765]`.

Authored as `feather/1` + `feather_body/1` clauses in `home_live.ex`. No icon
font, no external icon library on public pages.

---

## Imagery

- **Real photography only** — African healthcare settings. Never stock
  "people around a laptop", never 3D blobs / gradient art / AI illustration.
- `rounded-[2rem] border border-slate-200 object-cover`; `loading="lazy"` below
  the fold; a meaningful `alt`.
- No decorative background SVGs, blobs, blur, gradients, clip-paths.

---

## Copy

- **Name the specific thing, not the category.** A claim specific enough to be
  wrong for a different product is doing its job.
- **Button labels name the action** (`Open staff workspace`, `Scan a patient QR
  code`). **One deliberate exception:** the landing page's *primary* adopter CTA
  is **"Get started"** in both the hero and the closing band (→
  `/organisations/register`) — chosen for immediate recognisability. Every other
  button still names its action; secondary CTAs never use it. The footer carries
  no CTA *buttons* — it is a three-column grid (`1.6fr / 1fr / 1fr`): brand
  block (wordmark, slogan, one-line description) · an "Explore" column of
  section anchor links · a "Get started" column of plain text links (Create
  your organisation, Staff sign in). Full-width divider + copyright below.
  Links are `text-white/70 hover:text-white`, never pills. The sticky header's
  "Sign in" and the closing band carry the actual button CTAs.
- **No hedging** ("aims to", "designed to help", "without adding complexity").
- **No 4–6 item comma-list descriptions.** One crisp sentence on what a thing
  does beats a checklist of verbs.
- **No fabricated numbers.** Only stats that are literally true (6 stations,
  5 staff roles, 1 patient record, 0 cost to the patient).
- **No eyebrow / kicker labels** above headings — the heading + one lead line
  carry the section. The landing-page **hero** is the one place a label sits
  above the H1, and it is a **tinted chip, not an uppercase eyebrow**: the
  slogan *"Care that moves with the camp"* in
  `rounded-full border border-slate-200 bg-white px-4 py-2 text-sm font-semibold
  text-slate-600` with a leading `h-2 w-2` `#52B2D8` dot — no shadow. No other
  section gets a label above its heading, and no section uses an uppercase
  eyebrow.

---

## The Don't list

1. No drop shadows, `ring` decoration, or `backdrop-blur` — hairline borders and
   background-band shifts only.
2. No gradients — not on buttons, chart bars, backgrounds, or section chrome.
3. No decorative blobs, blur, clip-path, or background SVGs.
4. Accent cyan `#52B2D8` is never a fill or background — glyph / keyword / hover
   only, ≤ one or two per screen.
5. No eyebrow labels above headings, no uppercase-tracked kicker anywhere except
   the wordmark sub-label. The hero's slogan label is a tinted `rounded-full`
   chip (`bg-[#e9f6fb]`), not an eyebrow, and it is the only label above any
   heading on the site.
6. No font weight below 600 for emphasis, none above 700, no italics, no second
   family.
7. One radius per role; never mixed per-corner radii; `rounded-[2rem]` only on
   hero imagery.
8. No `hover:` transforms; the only transition is `transition-colors duration-150`.
9. No mid-page dark section — the one dark block is the footer.
10. No fabricated stats or metrics.
11. Copy: no hedges, no 4–6 item comma-list descriptions; button labels name
    the action — the landing page's primary adopter CTA ("Get started", hero +
    closing band) is the one sanctioned exception.
12. No stock-laptop-people or 3D-illustration imagery.

---

## Porting a `medic` pattern into a Tibasasa surface

1. Take the medic pattern's **structure and interaction model** (list-page shape,
   modal flow, table anatomy, form layout).
2. Drop its hard-coded medic purples (`#373896`, `#6667ab`, `#e7e7ff`, `#1D3557`).
3. Retoken colour to **`brand-*`** for authenticated screens, or the **Tibasasa
   palette** above for public screens — mapping roles, not values.
4. Conform to this doc's **radius vocabulary, zero-shadow elevation,
   `transition-colors` motion, typography scale, and the Don't list.**
5. Record any new durable primitive in `.agents/repo/ui-system.md`.
