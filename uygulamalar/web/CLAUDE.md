## Design System Rules — Web

- Use semantic token classes: `bg-card`, `text-textStrong`, `border-border`, `shadow-yd*`
- No raw Tailwind hex. No inline user strings — use `src/lib/i18n.ts`
- Web tokens mirror Flutter theme; `packages/ui_tokens` is the bridge (read-only for web)
