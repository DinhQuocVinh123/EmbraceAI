---
name: embrace-ui
description: Design-system rules for the EmbraceAI Flutter app (shadcn-style theme). Use whenever creating or restyling a screen or widget under lib/, or when test/design_system_test.dart or test/contrast_test.dart fails.
---

# EmbraceAI UI rules

The app follows a shadcn/ui look, implemented in Flutter through
`lib/core/theme.dart`. Screens take every colour, radius and text style from the
theme. Nothing is invented locally.

`@shadcn/lint` cannot run here (it targets React/Vue/Svelte with Tailwind). The
same rules are enforced by `test/design_system_test.dart`. Run it with
`flutter test test/design_system_test.dart test/contrast_test.dart`.

## Look

- Neutral zinc surfaces and one accent (teal, `scheme.primary`), used sparingly:
  the primary button, the selected state, and icons.
- Cards are flat: `scheme.surface` with a 1 px `scheme.outlineVariant` border and
  no elevation. `Card()` already does this through `cardTheme`.
- To show a selected state, use a border in `scheme.primary` plus a light tint
  (`primaryContainer` at an alpha of 0.35–0.4) and a check or bold label. Never
  rely on colour alone.
- Alerts and banners have a surface background and a thin border; only the icon
  carries colour.
- Titles use `textTheme.titleLarge` or `headlineSmall`, which are already w600
  with tightened letter spacing. Do not use a larger size for body text; the
  users are older adults.

## Tokens

| Need | Use |
|---|---|
| Colour | `Theme.of(context).colorScheme.*`. Do not write `Color(0x...)` outside `theme.dart`, `mood.dart` or `session_scene.dart`. |
| Radius | `AppRadius.sm` (6), `AppRadius.md` (8: buttons, inputs, chips, nav items), `AppRadius.lg` (12: cards, dialogs, tiles). |
| Spacing | `Gap.xs/s/m/l/xl` (4/8/16/24/32). |
| Muted text | `scheme.onSurfaceVariant` |
| Hairline or border | `scheme.outlineVariant`. An input or other component boundary that must reach 3:1 uses `scheme.outline`. |

## Accessibility (non-negotiable)

- Contrast: text needs 4.5:1 and UI parts need 3:1 (WCAG 2.2), in both light
  and dark mode. When you add a colour pair, add a line for it to
  `test/contrast_test.dart`.
- Tap targets are at least 48 px, which the button themes already set.
- Layouts must survive 200 % text scale. The `*_large_text` goldens and
  `study_forms_test.dart` check this.

## Scope

Restyle only. Do not change logic, data flow or navigation when doing UI work.
Files on the "legacy" list in `design_system_test.dart` have not been restyled
yet. Remove a file from that list when you restyle it.

After a visual change, regenerate the screenshots and look at them:
`flutter test test/screenshots_test.dart test/staff_dashboard_test.dart --update-goldens`
