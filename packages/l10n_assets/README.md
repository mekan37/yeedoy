# l10n_assets

Uygulamalar arası çeviri anahtar tutarlılığı için ortak klasör.

## Kapsam
- Aşağıdaki dosyalar arasında key karşılaştırması:
  - `apps/mobile_flutter/lib/l10n/*.arb`
  - `apps/panel_flutter_web/lib/l10n/*.arb`

## Rapor
- Çıktı dosyası:
  - `packages/l10n_assets/reports/missing_keys_report.md`

---

## Shared Common ARB Files

`common_en.arb` and `common_tr.arb` are the canonical source of truth for keys
that are identical across both apps.

### What they contain

**62 shared keys** that have the same name AND the same English value in both
`apps/mobile_flutter/lib/l10n/app_en.arb` and
`apps/panel_flutter_web/lib/l10n/app_en.arb`.

Complete list:

```
appName, map, save, cancel, logout, uploadPhoto, saving, preview, embed, share,
invalidLinkMessage, browserOpened, embedFailed, back, reviewsCount, openNow,
verified, businessLabel, menu, apply, unknown, title, approved, tumu, pending,
rejected, duzenle, sla, yenile, start, campaign, go, menuShareNotFoundTitle,
menuShareNotFoundDescription, menuContentNotFound, openAppForBetterExperience,
openApp, nearbyPeopleViewed, verifiedPrices, selectRatingFirst, thankYou,
noProductsFound, preparedWithApp, tableLabel, tableServiceQuestion,
shortNoteOptional, submit, submitted, submitting, retry, register, login, cover,
note, menuItemName, price, priceStability, loginActionFailedTitle,
loginActionFailedDescription, legalCopyrightSectionTitle,
legalOwnershipAppealSectionTitle, legalProductPrinciplesSectionTitle
```

### Conflict keys (same name, different EN values — NOT in common_*.arb)

These 2 keys exist in both apps but have diverged. They must be resolved manually
before they can be added to `common_en.arb`:

| Key | mobile value | panel value |
|-----|-------------|-------------|
| `legalCopyrightIntro` | "Menu and venue photos may be subject to copyright. If you see a **violation**, submit it via Report > Copyright." | "Menu and venue photos may be subject to copyright. If you see an **infringement**, you can report it via Report > Copyright." |
| `legalOwnershipAppealIntro` | "If your ownership **request** was rejected, you can appeal. Your documents are reviewed again." | "If your ownership **claim** was rejected, you can appeal. Your documents **will be** reviewed again." |

Additionally, 4 Turkish keys have diverging translations between apps (their EN
values are identical, so they are still included in `common_tr.arb` using the
mobile app value as the source of truth):

| Key | mobile (tr) | panel (tr) |
|-----|-------------|------------|
| `title` | `"title"` | `"Başlık"` |
| `nearbyPeopleViewed` | `"Yakındaki {count} kişi görüntüledi"` | `"{count} kişi yakında görüntüledi"` |
| `tableServiceQuestion` | `"Masa {tableNo} - servis var mı?"` | `"Masa {tableNo} servisi nasıldı?"` |
| `loginActionFailedDescription` | `"{error}\nBağlantıyı kontrol edip tekrar dene."` | `"{error}\nBağlantını kontrol edip tekrar dene."` |

Review these TR conflicts and align the app ARB files manually; then update
`common_tr.arb` accordingly.

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
