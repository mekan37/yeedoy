# l10n_assets

Uygulamalar arası çeviri anahtar tutarlılığı için ortak klasör.

## Kapsam
- Aşağıdaki dosya için key yönetimi:
  - `apps/mobile_flutter/lib/l10n/*.arb`

---

## Shared Common ARB Files

`common_en.arb` and `common_tr.arb` are the canonical source of truth for keys
shared in the mobile app.

Complete list:


---

## How to use sync-l10n.mjs

The script copies every key from `common_en.arb` / `common_tr.arb` into the
corresponding ARB file of each app. It does not remove or touch any app-specific
keys.

```bash
# From monorepo root:
node packages/l10n_assets/scripts/sync-l10n.mjs

# Or from this package directory:
npm run sync-l10n
```

The script reports:
- How many keys were synced per file
- Any key whose value in the app ARB differed from `common_*.arb` (i.e. was overwritten)

After running, execute `flutter gen-l10n` inside each app if you want to
regenerate the Dart `AppLocalizations` classes.

---

## Rule: never edit shared keys directly in app ARB files

Always edit `common_en.arb` or `common_tr.arb`, then run `sync-l10n.mjs` to
propagate the change to both apps. Editing app ARB files directly for a shared
key will be overwritten the next time the script runs.
