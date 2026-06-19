# Yeedoy Design System — Conventions

## Design Tokens

All visual values come from CSS custom properties (`--yd-*`), never hardcoded hex:

```css
/* Colors */
--yd-color-primary-rgb: 127, 29, 29   /* Deep red #7F1D1D */
--yd-color-card-rgb: ...              /* Card background */
--yd-color-border-rgb: ...            /* Borders & dividers */
--yd-color-text-strong-rgb: ...       /* Primary text */
--yd-color-muted-rgb: ...             /* Secondary/muted text */

/* Shadows */
--yd-shadow-1 / --yd-shadow-2 / --yd-shadow-3

/* Typography */
--yd-font-family: 'Sora', sans-serif
```

Tailwind semantic classes: `bg-card`, `bg-primary`, `text-textStrong`, `text-muted`, `border-border`, `shadow-yd1/yd2/yd3`.

## Component Categories

- **General UI** — `AppButton`, `GradientButton`, `AppCard`, `PressableCard`, `AppChip`, `StatusChip`, `CategoryChip`, `MetricCard`, `AppSectionHeader`, `ThemeToggle`
- **Panel (Admin/Owner)** — `PanelActionButton`, `PanelSearchField`, `PanelToolbar`, `PanelToolbarGroup`, `PanelEmptyState`, `PanelDataTable`, `PanelDataTableHeader`, `PanelDataTableRow`, `PanelDataTableCell`
- **Loading States** — `Skeleton`, `SkeletonText`, `SkeletonCard`, `SkeletonRow`, `SkeletonMetricGrid`, `SkeletonTableRows`, `SkeletonBusinessCard`, `SkeletonHero`

## Usage Rules

1. Always import from `@yeedoy/web-ui`
2. Use `AppCard` / `PressableCard` for surface containers — don't create raw `<div>` cards
3. Table components compose: `PanelDataTable` > `thead/tbody` > `tr` > `PanelDataTableHeader` / `PanelDataTableCell`
4. Toolbar filters: wrap with `PanelToolbar`, group related controls in `PanelToolbarGroup`
5. Dark mode: add `class="dark"` on `<html>` — all tokens adapt via CSS custom properties
6. Min tap target: 44px (enforced via Tailwind `min-h-[44px]` on interactive elements)
