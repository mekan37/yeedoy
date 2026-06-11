# Profile Page Redesign — Design Spec

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement the plan derived from this spec.

**Goal:** Redesign the top of the mobile Profile page (`_ProfileTab` in `lib/features/profile/ui/profile_page.dart`) to match the `profil.png` mockup — greeting header, hero identity card with real stats, quick-actions grid, grouped account list, and a badge-progress teaser — while preserving all existing functionality (daily task, reputation/level, moat signals, achievements grid, social links, alerts/feed tabs).

**Architecture:** Pure UI/composition change inside the existing `feature-first` `profile` feature. No new Supabase access; reuses existing providers (`myProfileStatsProvider`, `myProfileProgressProvider`, `userLocationProvider`, `creatorProfileProvider`, `publicProfileProvider`) plus one new lightweight provider for the favorite-collections count (local `SharedPreferences`, mirrors the pattern already used in `favorites_page.dart`).

**Tech Stack:** Flutter, Riverpod, go_router, existing design system (`AppColors`/`AppTokens`/`AppTypography`), ARB l10n (TR+EN).

---

## 1. Scope

### In scope
- New `_ProfileHeader` widget (greeting + "Profilin" title + `NotificationsBell`), mirroring `_FavoritesHeader` from the Favorites redesign.
- Restyled hero identity card: pink/`primarySoft` container wrapping avatar/name/social links (existing `ProfileIdentityCard` content) + a real-data location row + a real-data 3-stat row (Favori / Yorum / Liste).
- New "Hızlı işlemler" 2x2 quick-actions grid with 4 real destinations.
- New grouped "Hesap" list card replacing the two separate `Hesap Bilgileri` / `Hesap Güvenliği` cards.
- New badge-progress teaser banner using real `unlockedCount`, scrolling to the existing achievements section on tap.
- New ARB keys (TR+EN) for all new copy; l10n-ify the currently-hardcoded `'Hesap Güvenliği'` / `'Şifre ve e-posta değiştir'` strings.
- New lightweight provider: `myFavoriteCollectionsCountProvider` (wraps `FavoriteCollectionsPrefs.load().length`).

### Out of scope (per user decisions)
- No "Yorumlarım" (my-reviews list), "Adreslerim" (addresses), "Bildirim Tercihleri", or "Yardım ve Destek" screens — these have no backing feature today and are omitted from the quick-actions/account grids.
- No changes to `_AlertsTab`, `_FeedTab`, daily task card, reputation/level card, moat signals card, social link section, creator switch, achievements grid/visuals, or login-required `_InfoCard` — these remain in place below the redesigned header section, unchanged in behavior.
- No changes to `AppBottomNav`/`AppShell`/router.

---

## 2. New Widget Tree for `_ProfileTab`

Order of `ListView` children (top to bottom):

1. `const _ProfileHomeHeader()` — greeting + "Profilin" + `NotificationsBell`
2. `_ProfileHeroCard()` — pink container:
   - `ProfileIdentityCard` content (avatar, name, social links) — restyled, no longer self-carded
   - `_ProfileLocationRow()` — only if `userLocationProvider` has a city
   - `_ProfileStatsRow()` — Favori / Yorum / Liste (real counts)
3. `_ProfileQuickActionsGrid()` — 2x2 grid
4. `_ProfileAccountList()` — grouped "Hesap" card (Hesap Bilgileri, Hesap Güvenliği)
5. `_ProfileBadgesBanner()` — rozet teaser, scroll-to-achievements on tap
6. *(unchanged, existing order)* login `_InfoCard` (if `user == null`), creator switch card, daily task card, `_SocialLinkSection`, "İstatistiklerin" title + existing `_StatsGrid` (5 detailed stats — kept as-is, complements the 3-stat hero row), community trust card, `CommunityScoreGuideCard`, moat signals card, "Rozetlerim" title + `_LatestAchievementBanner` + `AchievementsGrid` — **wrapped in a `Column` with a `GlobalKey` (`_achievementsSectionKey`) for the scroll target**.

---

## 3. Component Details

### 3.1 `_ProfileHomeHeader` (ConsumerWidget)
Mirrors `_FavoritesHeader`:
- Greeting: `t.discoveryGreetingHello(displayName)` (from `publicProfileProvider`) or `t.discoveryGreetingHelloAnon`.
- Title: `t.profileHomeTitle` ("Profilin" / "Your Profile").
- Trailing: `IconButton(onPressed: () => context.go('/inbox'), icon: const NotificationsBell())`.

### 3.2 `_ProfileHeroCard`
- `Container` with `color: AppColors.primarySoft`, `borderRadius: BorderRadius.circular(tokens.radius16)`, padding `tokens.space16`.
- Contains restyled `ProfileIdentityCard` (see 3.3), then `_ProfileLocationRow`, then `SizedBox(height: tokens.space12)`, then `_ProfileStatsRow`.

### 3.3 `ProfileIdentityCard` changes (`lib/features/profile/ui/components/profile_identity_card.dart`)
- `_card({required Widget child})` no longer returns a `Card` — returns `child` directly (no extra background/elevation), since the new parent (`_ProfileHeroCard`) supplies the pink background. This is the **only** call site of `ProfileIdentityCard`, so no other screen is affected.
- Remove the `t.profileIdentitySupportMessage` subtitle line (replaced visually by the new location row sitting just below the card in `_ProfileHeroCard`).
- No other behavior changes (avatar upload, social links untouched).

### 3.4 `_ProfileLocationRow` (ConsumerWidget)
- `final loc = ref.watch(userLocationProvider);`
- If `!loc.hasLocation || loc.loading || loc.permissionDenied` → `SizedBox.shrink()`.
- Else → `Row(children: [Icon(Icons.location_on_outlined, size: 16, color: AppColors.muted), SizedBox(width: 4), Text(loc.city!, style: ...muted/bodySmall)])`.
- Real GPS-derived data only — never invented.

### 3.5 `_ProfileStatsRow` (ConsumerWidget)
- Watches `myProfileStatsProvider` and `myFavoriteCollectionsCountProvider`.
- 3 equal-width stat cells (`Expanded` in a `Row`), each: bold count + small label below.
  - Favori: `stats.favoritesCount` / `t.profileStatFavoritesShort`
  - Yorum: `stats.reviewsCount` / `t.profileStatReviewsShort`
  - Liste: `collectionsCount` / `t.profileStatListsShort`
- While `myProfileStatsProvider` or the collections provider is loading, show `'—'` for that cell's count (no fake numbers).
- On error, show `'—'` (existing `_ErrorText` pattern not needed for a compact stat cell).

### 3.6 New provider: `myFavoriteCollectionsCountProvider`
New file `lib/features/profile/domain/favorite_collections_count_provider.dart`:
```dart
final myFavoriteCollectionsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final collections = await FavoriteCollectionsPrefs.load();
  return collections.length;
});
```
Imports `FavoriteCollectionsPrefs` from `../../../core/storage/favorite_collections_prefs.dart`.

### 3.7 `_ProfileQuickActionsGrid`
- Section heading `t.profileQuickActionsTitle` ("Hızlı işlemler") above the grid, styled like the existing `t.profileStatsTitle` heading.
- `GridView.count` or `Wrap`/`Row`+`Row` 2x2 (use `LayoutBuilder`/`GridView.count(crossAxisCount: 2, ...)` per existing design-system conventions — check `packages/shared_ui_components` for an existing quick-action tile component before creating a new one; if none exists, build a small private `_QuickActionTile` (icon in circle + label, `AppColors.card` bg, `radius12`, min tap target 44px, `InkWell` for tap)).
- 4 tiles:
  1. **Favorilerim** (`Icons.favorite_border`, `t.profileQuickActionFavorites`) → `context.go('/favorites')`
  2. **Fiyat Alarmları** (`Icons.notifications_active_outlined`, `t.profileQuickActionPriceAlerts`) → `DefaultTabController.of(context).animateTo(1)`
  3. **Akışım** (`Icons.dynamic_feed_outlined`, `t.profileQuickActionFeed`) → `DefaultTabController.of(context).animateTo(2)`
  4. **Ayarlar** (`Icons.settings_outlined`, `t.profileSettings` — reuse existing key) → `Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileSettingsPage()))`

### 3.8 `_ProfileAccountList`
- Single `Container`/`Card` (`AppColors.card`, `radius16`, border `AppColors.border`) with section title `t.profileAccountSectionTitle` ("Hesap") above it.
- Two `ListTile`s separated by a 1px `Divider` (`AppColors.border`):
  1. Leading `Icon(Icons.person_outline)`, title `t.profileSettings`, subtitle `t.privacySocialSubtitle`, trailing chevron, `onTap` → push `ProfileSettingsPage` (same as today).
  2. Leading `Icon(Icons.shield_outlined)`, title `t.profileAccountSecurityTitle` (new key, "Hesap Güvenliği"), subtitle `t.profileAccountSecuritySubtitle` (new key, "Şifre ve e-posta değiştir"), trailing chevron, `onTap` → `context.push('/account-security')` (same as today).
- Removes the two standalone `Card`/`ListTile` blocks currently at lines ~92–116 of `profile_page.dart`.

### 3.9 `_ProfileBadgesBanner`
- Watches `myProfileProgressProvider`.
- `loading`/`error`/`null` → `SizedBox.shrink()` (no invented numbers).
- On data: `Container` (`AppColors.primarySoft`, `radius16`, padding `space16`), `Row`:
  - Leading badge/star icon (`Icons.emoji_events_outlined`).
  - `Expanded(Column)`: `t.profileBadgesBannerTitle` (bold) + `t.profileBadgesBannerCount(progress.unlockedCount)` + `t.profileBadgesBannerSubtitle` (muted, smaller).
  - Trailing arrow `IconButton(Icons.arrow_forward, onPressed: _scrollToAchievements)`.
- `_scrollToAchievements`: `Scrollable.ensureVisible(_achievementsSectionKey.currentContext!, duration: ..., curve: ...)`. The achievements section (title + `_LatestAchievementBanner` + `AchievementsGrid`) is wrapped in `Column(key: _achievementsSectionKey, children: [...])` in its existing position.
- `_achievementsSectionKey` is a `GlobalKey` field on `_ProfileTabState` — **note**: `_ProfileTab` is currently a stateless `ConsumerWidget`; convert it to `ConsumerStatefulWidget` to hold this key (minimal change, all existing `ref.watch` calls move into the `State.build`).

---

## 4. New ARB Keys (TR / EN)

| Key | TR | EN |
|---|---|---|
| `profileHomeTitle` | "Profilin" | "Your Profile" |
| `profileStatFavoritesShort` | "Favori" | "Favorites" |
| `profileStatReviewsShort` | "Yorum" | "Reviews" |
| `profileStatListsShort` | "Liste" | "Lists" |
| `profileQuickActionsTitle` | "Hızlı işlemler" | "Quick actions" |
| `profileQuickActionFavorites` | "Favorilerim" | "My Favorites" |
| `profileQuickActionPriceAlerts` | "Fiyat Alarmları" | "Price Alerts" |
| `profileQuickActionFeed` | "Akışım" | "My Feed" |
| `profileAccountSectionTitle` | "Hesap" | "Account" |
| `profileAccountSecurityTitle` | "Hesap Güvenliği" | "Account Security" |
| `profileAccountSecuritySubtitle` | "Şifre ve e-posta değiştir" | "Change password and email" |
| `profileBadgesBannerTitle` | "Rozet Koleksiyonun" | "Your Badge Collection" |
| `profileBadgesBannerCount` | "{count} rozetin var!" | "You have {count} badges!" |
| `profileBadgesBannerSubtitle` | "Keşfetmeye devam et, yeni rozetler kazan! 🚀" | "Keep exploring to earn new badges! 🚀" |

`profileQuickActionsTitle` is used as the section heading above the grid (style matches existing `t.profileStatsTitle` heading style).

Existing keys reused as-is: `profile`, `profileSettings`, `privacySocialSubtitle`, `discoveryGreetingHello`, `discoveryGreetingHelloAnon`, `profileStatsTitle`.

`profileIdentitySupportMessage` becomes unused after this change — confirm no other references before removing from ARB (likely safe to leave as a dangling-but-unused key, or remove if `tools/ceviri-denetimi.mjs` flags unused keys as an error; check audit behavior during implementation).

---

## 5. Files Touched

- `lib/features/profile/ui/profile_page.dart` — main restructure (new widgets, `_ProfileTab` → `ConsumerStatefulWidget`, remove old settings/security cards, remove old `_StatsGrid` heading duplication concerns — keep `_StatsGrid` but retitle if needed, wrap achievements section with `GlobalKey`).
- `lib/features/profile/ui/components/profile_identity_card.dart` — `_card()` no longer wraps in `Card`; remove support-message subtitle.
- `lib/features/profile/domain/favorite_collections_count_provider.dart` — new file.
- `lib/l10n/app_tr.arb`, `lib/l10n/app_en.arb` — new keys (table above); regenerate via `flutter gen-l10n` (no CLI args, per repo convention) → updates `app_localizations*.dart`.
- `packages/l10n_assets/` sync if these keys belong in the shared ARB (check existing convention: are profile keys mobile-only or shared? Follow existing pattern for `profileStatsTitle` etc. — likely mobile-only `lib/l10n/`, no shared sync needed, but verify).

---

## 6. Validation

Per `CLAUDE.md` minimum validation for Flutter code:
- `flutter analyze` → must report "No issues found!"
- `flutter test` → full suite must pass (baseline: 318 passed / 4 skipped)
- `node tools/ceviri-denetimi.mjs` (run from repo root) → l10n audit must pass (no missing/unused key errors)
- Manual check: confirm `_ProfileTab` still renders correctly for both logged-in and guest (`user == null`) states — guest state should hide/zero personal stats gracefully (providers already return zeroed `ProfileStats` for `user == null`; `_ProfileBadgesBanner` and `_ProfileLocationRow` should degrade gracefully too — `myProfileProgressProvider` for a null user should be checked and handled the same way other `*Async` providers in this file already handle guests).

---

## 7. Open Implementation Notes (for the plan)

- Verify `myProfileProgressProvider` behavior for `user == null` (does it throw, return null, or return a zeroed progress?) and ensure `_ProfileBadgesBanner` hides cleanly for guests.
- Confirm whether a reusable "quick action tile" or "grouped list card" primitive already exists in `packages/shared_ui_components` or `lib/features/shared/ui/` before writing new private widgets (per CLAUDE.md "no fourth copy of a primitive" rule).
- Confirm `AppColors.primarySoft`, `AppColors.cardAlt`, `radius16`, `radius12`, `space12`/`space16` token availability (already confirmed to exist from prior Favorites work).
- `dart format` the touched files after edits (matches the workflow used for the Favorites fix).
