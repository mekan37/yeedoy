# Design Sync Notes — @yeedoy/web-ui

## Repo setup

- Components embedded in Next.js app at `uygulamalar/web/src/ui/components/` — NOT a standalone npm package.
- 12 pure-React files (no `next/link`) are copied to `.ds-build/src/` for the bundle.
- `business-tile.tsx` and `featured-card.tsx` are excluded — they import `next/link`.
- CSS = `tokens.css` (CSS custom props) + Tailwind-generated `tw.css` → concatenated into `.ds-build/combined.css`.
- Tailwind is at repo root `node_modules/.bin/tailwindcss.cmd` — use `.cmd` on Windows.
- A junction at `node_modules/@yeedoy/web-ui` → `.ds-build/` makes the converter find the virtual package.

## Synth-entry mode

The converter runs without `--entry` → PKG_DIR = `node_modules/@yeedoy/web-ui` (junction → `.ds-build/`).
No `module`/`main` in `package.json` → synth entry from `src/*.tsx`.
If junction breaks on fresh clone, recreate with: `New-Item -ItemType Junction -Path "node_modules\@yeedoy\web-ui" -Target ".ds-build"`.

## Re-sync steps

1. Copy updated component `.tsx` files to `.ds-build/src/` (exclude `business-tile`, `featured-card`).
2. Regenerate `combined.css`:
   ```powershell
   Get-Content uygulamalar/web/src/styles/tokens.css | Set-Content .ds-build/combined.css
   & "C:\yeedoy\node_modules\.bin\tailwindcss.cmd" -i uygulamalar/web/src/styles/globals.css -c uygulamalar/web/tailwind.config.js --content "uygulamalar/web/src/**/*.{ts,tsx}" -o .ds-build/tw.css --minify
   Get-Content .ds-build/tw.css | Add-Content .ds-build/combined.css
   ```
3. Ensure junction exists: `Test-Path node_modules/@yeedoy/web-ui`
4. Run converter: `node .ds-sync/package-build.mjs --config .design-sync/config.json --node-modules node_modules --out ./ds-bundle`
5. Validate: `node .ds-sync/package-validate.mjs ./ds-bundle`
6. Upload via `resync.mjs` or re-run `finalize_plan` + `write_files`.

## Known render warns

- `[FONT_DANGLING] "flexing"` — `@font-face` için `/fonts/flexing-black.ttf` bulunamadı. `runtimeFontPrefixes`'e kayıtlı olduğu için runtime-loaded; bundle'a dahil değil. Validator uyarısı non-blocking, ihmal edilebilir.

## Authored previews (6 components)

- `AppSectionHeader.tsx` — floor card blank without `title` prop
- `PanelDataTableCell.tsx` — `<td>` needs table context; shows full table
- `PanelDataTableHeader.tsx` — `<th>` needs table context; shows full table with data row
- `PanelEmptyState.tsx` — blank without `title`; 3 variants: icon, with action, no icon
- `PanelToolbar.tsx` — blank without children; 2 variants: simple, with groups
- `SkeletonText.tsx` — 3 variants: 1, 3, 5 lines

## Re-sync risks

- `combined.css` is rebuilt from Tailwind scan of the web app sources — adding new Tailwind classes in components requires re-running the Tailwind CLI step.
- The junction `node_modules/@yeedoy/web-ui` is not committed (node_modules is gitignored) — recreate per clone.
- `.ds-build/src/*.tsx` are copies, not symlinks — they will drift from originals unless re-copied on re-sync.
- `react@19.x` has no UMD bundle → inlined via esbuild; if React is updated, rebuild.
- Fonts (Sora, Playfair Display, Flexing) are runtime-loaded — set as `runtimeFontPrefixes` in config; they're never shipped in the bundle.
