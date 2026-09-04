## Design System Rules — Web

- Use semantic token classes: `bg-card`, `text-textStrong`, `border-border`, `shadow-yd*`
- No raw Tailwind hex. No inline user strings — use `src/lib/ceviri.ts` (public-facing TR/EN `copy` dict) or `src/lib/i18n.ts` (`adminBusinessCopy`, admin-only Turkish forms)
- Web tokens mirror Flutter theme; `packages/ui_tokens` is the bridge (read-only for web)
