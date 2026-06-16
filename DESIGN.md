# No Tomorrow — Design System

> Living reference for the app's visual language. Keep new screens on-brand by
> reaching for the tokens below instead of raw values. Generated in the spirit
> of `impeccable /document`; update it whenever the system genuinely changes.

## Brand & tone

A gamified self-improvement RPG. The feel is **tactile, energetic and game-like**:
bold type, vivid per-section accent colors, spring-loaded micro-interactions and
haptics. Surfaces are either deep near-black (app shell) or warm "paper" (content
cards), creating a console-meets-journal personality.

- **Audience:** people building daily discipline (tasks, habits, workouts, reading, budgeting, food, abstinence).
- **Differentiator:** the radial "pizza-wheel" navigation and the deformable/jelly press physics.

## Color

Source of truth: `lib/theme/app_colors.dart`. Do **not** hard-code hex in screens.

### Surfaces & text
| Token | Light | Dark |
|-------|-------|------|
| `bg` | `#F5F7FF` | `#0A0A0F` |
| `surface` | `#FFFFFF` | `#13131A` |
| `card` | `#FFFFFF` | `#1C1C27` |
| `border` | `#E8EAFF` | `#2A2A3D` |
| `text` | `#0A0A0F` | `#F5F7FF` |
| `textSub` | `#6B7280` | `#8892B0` |

### Global accents
| Token | Hex | Use |
|-------|-----|-----|
| `action` / `primary` | `#E8693A` | warm orange — CTAs, active UI |
| `gold` / `secondary` | `#CA8A04` | XP, levels, rewards, streaks |
| `danger` | `#DC2626` | destructive / errors |
| `success` | `#22C55E` | completion, positive deltas |
| `warning` | `#F59E0B` | caution |

### Section accents
Each section owns a vivid hue: tasks `#2979FF`, habits `#AA00FF`, workouts
`#FF5722`, abstinences `#FF1744`, reading `#00E676`, budget `#FFD600`, food
`#FF4081`, collection `#00E5FF`, profile `#7C4DFF`.

### Paper / parchment palette
Warm surfaces for cards, sheets and reading-style content (`AppColors.paper*`):
`paperBg #F5F1E8`, `paperCard #F5F2EB`, `paperRow #EFEBE0`, `paperBorder #DDD8CB`,
`paperText #2A2318`, `paperTextDeep #594536`, `paperTextSub #8A8070`.

## Spacing

Source: `lib/theme/app_spacing.dart`. One 4/8-based grid. Use `AppSpacing.*`
(`xxs 2, xs 4, sm 8, md 12, lg 16, xl 24, xxl 32, xxxl 48`) and the ready-made
`vGap*` / `hGap*` / `gap*` `SizedBox`es instead of raw numbers.

## Corner radius

Source: `lib/theme/app_radius.dart`. Ladder: `sm 8` (chips/inputs), `md 12`
(default card/button), `lg 16` (large cards), `xl 24` (hero/sheets),
`pill 999` (pills/avatars). Use the `BorderRadius` helpers (`AppRadius.md`, …)
and the `topLg`/`topXl` helpers for bottom sheets.

## Typography

Source: `lib/theme/app_type.dart`. App font is **Outfit** (via theme `TextTheme`).
Supporting families: **Bebas Neue** (display), **Inter** (UI body),
**JetBrains Mono** (numerals/stats), **Playfair Display** (reading section).

Semantic scale — `display 32/900`, `h1 24/800`, `h2 20/800`, `h3 16/700`,
`bodyLg 16/500`, `body 14/500`, `bodySm 13/500`, `label 12/600`,
`caption 11/600`, `overline 11/800` (all-caps, tracked).

**Hard rule:** no human-readable text below **`AppType.minReadable` = 11px**.
(Decorative brand marks like the wheel's `NO/TMR` logo are exempt.)

## Motion

The signature is spring-physics tactility — keep it consistent.

- **Jelly press** (`widgets/jelly_button.dart`): scale to `0.93` on press
  (`90ms` ease-out), release with spring `cubic-bezier(0.34, 1.56, 0.64, 1)`
  over `400ms`. Light haptic on press.
- **Wheel snap** (`home_screen.dart`): `480ms` `easeOutCubic`, momentum-projected;
  `selectionClick` haptic on index change.
- **Page transitions:** `400ms` in / `300ms` out, `easeOutCubic`, fade + slide.
- **Haptics:** `lightImpact` for taps, `mediumImpact` for commits (e.g. logging
  pages), `selectionClick` for navigation.

## Components

- **JellyButton** — wrap any tappable surface for the standard press feel.
- **RadialWheel** — primary navigation; section sectors + center logo on a `CustomPainter`.
- **Cards** — paper surface, `AppRadius.xl`, soft shadow `black @ ~10% / blur 12 / y+5`.
- **Pill FAB** — blurred glass (`BackdropFilter`), `AppRadius.pill`, accent circle + label.
- **Bottom sheets** — `AppRadius.topXl`, accent-tinted header row.

## Reference implementation

`lib/screens/reading_screen.dart` is the canonical example of token usage
(`AppColors.paper*`, `AppRadius.*`, `AppSpacing.*`). Mirror its patterns when
building or refactoring other screens.

## Known debt (next passes)

- ~190 legacy sub-11px font sizes were floored to 11px automatically; the dense
  screens (`tasks_screen.dart`, `habits_screen.dart`) still need a visual QA pass.
- Sepia palette is consolidated in `AppColors`, but most screens still declare
  local `const` hex — migrate them to `AppColors.paper*` screen by screen.
- Radius/spacing tokens are adopted in `reading_screen` only; roll out gradually.
- `tasks_screen.dart` (5.7k LOC) and `habits_screen.dart` (3.3k LOC) should be
  decomposed so component styling stays consistent.
