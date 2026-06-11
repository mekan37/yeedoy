# Profile Page Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the top of `_ProfileTab` (mobile Profile page, `lib/features/profile/ui/profile_page.dart`) to match the approved `profil.png` mockup — greeting header, pink hero identity card with real stats, quick-actions grid, grouped account list, and a real-data badge-progress banner — while preserving all existing functionality below it (creator switch, daily task, social links, detailed stats grid, reputation/level, moat signals, achievements grid, alerts/feed tabs).

**Architecture:** Pure UI/composition change inside the existing `profile` feature. One new lightweight provider (`myFavoriteCollectionsCountProvider`) wraps the existing `FavoriteCollectionsPrefs.load()`. All other data comes from existing providers (`myProfileStatsProvider`, `myProfileProgressProvider`, `userLocationProvider`, `publicProfileProvider`). New private widgets are added to `profile_page.dart`; `ProfileIdentityCard` is restyled (its only call site).

**Tech Stack:** Flutter, Riverpod, go_router, design system (`AppColors`/`AppTokens`), ARB l10n (TR+EN).

**Spec:** `docs/superpowers/specs/2026-06-11-profile-redesign-design.md`

---

## File Structure

- `lib/features/profile/domain/favorite_collections_count_provider.dart` — **new file**. `myFavoriteCollectionsCountProvider`, wraps `FavoriteCollectionsPrefs.load().length`.
- `test/features/profile/domain/favorite_collections_count_provider_test.dart` — **new file**. Unit tests for the provider above.
- `lib/l10n/app_tr.arb`, `lib/l10n/app_en.arb` — add 14 new keys; regenerate `app_localizations*.dart` via `flutter gen-l10n`.
- `lib/features/profile/ui/components/profile_identity_card.dart` — `_card()` no longer wraps in `Card`; remove the `profileIdentitySupportMessage` subtitle.
- `lib/features/profile/ui/profile_page.dart` — main restructure:
  - new imports (`NotificationsBell`, `publicProfileProvider`, `userLocationProvider`, `myFavoriteCollectionsCountProvider`, design-system `AppTokens`)
  - new private widgets: `_ProfileHomeHeader`, `_ProfileLocationRow`, `_StatCell`, `_ProfileStatsRow`, `_ProfileHeroCard`, `_QuickActionTile`, `_ProfileQuickActionsGrid`, `_ProfileAccountList`, `_ProfileBadgesBanner`
  - `_ProfileTab` converted from `ConsumerWidget` to `ConsumerStatefulWidget`/`ConsumerState` to hold the `_achievementsSectionKey` `GlobalKey`
  - removal of the two old hardcoded settings/security `Card`s
- `test/features/profile/ui/profile_page_test.dart` — **new file**. Widget tests for the redesigned `ProfilePage` (guest state).

---

## Task 1: New provider `myFavoriteCollectionsCountProvider`

**Files:**
- Create: `uygulamalar/mobil/lib/features/profile/domain/favorite_collections_count_provider.dart`
- Test: `uygulamalar/mobil/test/features/profile/domain/favorite_collections_count_provider_test.dart`

- [ ] **Step 1: Write the failing test**

Create `uygulamalar/mobil/test/features/profile/domain/favorite_collections_count_provider_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yeedoy/features/profile/domain/favorite_collections_count_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns 0 when no collections are saved', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final count = await container.read(
      myFavoriteCollectionsCountProvider.future,
    );

    expect(count, 0);
  });

  test('returns the number of saved favorite collections', () async {
    SharedPreferences.setMockInitialValues({
      'favorite_collections_v1': jsonEncode([
        {
          'id': 'col-1',
          'name': 'Kahvaltı Mekanları',
          'business_ids': ['biz-1', 'biz-2'],
          'created_at': '2026-01-01T00:00:00.000Z',
        },
        {
          'id': 'col-2',
          'name': 'Akşam Yemeği',
          'business_ids': ['biz-3'],
          'created_at': '2026-01-02T00:00:00.000Z',
        },
      ]),
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final count = await container.read(
      myFavoriteCollectionsCountProvider.future,
    );

    expect(count, 2);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run (from `uygulamalar/mobil/`): `flutter test test/features/profile/domain/favorite_collections_count_provider_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'yeedoy/features/profile/domain/favorite_collections_count_provider.dart'` (file does not exist).

- [ ] **Step 3: Write the implementation**

Create `uygulamalar/mobil/lib/features/profile/domain/favorite_collections_count_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/favorite_collections_prefs.dart';

final myFavoriteCollectionsCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final collections = await FavoriteCollectionsPrefs.load();
  return collections.length;
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/profile/domain/favorite_collections_count_provider_test.dart`
Expected: `00:0X +2: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/mobil/lib/features/profile/domain/favorite_collections_count_provider.dart uygulamalar/mobil/test/features/profile/domain/favorite_collections_count_provider_test.dart
git commit -m "feat(profile): add favorite collections count provider"
```

---

## Task 2: Add new ARB keys (TR + EN) and regenerate l10n

**Files:**
- Modify: `uygulamalar/mobil/lib/l10n/app_tr.arb` (around line 2011)
- Modify: `uygulamalar/mobil/lib/l10n/app_en.arb` (around line 3918-3921)

- [ ] **Step 1: Add the new keys to `app_tr.arb`**

Find this line (around line 2011):

```json
  "profileGuestUser": "Misafir",
  "profileIdentitySupportMessage": "Topluluğa katkılı yaparak profilini güçlendirebilirsin.",
```

Replace with:

```json
  "profileGuestUser": "Misafir",
  "profileHomeTitle": "Profilin",
  "profileStatFavoritesShort": "Favori",
  "profileStatReviewsShort": "Yorum",
  "profileStatListsShort": "Liste",
  "profileQuickActionsTitle": "Hızlı işlemler",
  "profileQuickActionFavorites": "Favorilerim",
  "profileQuickActionPriceAlerts": "Fiyat Alarmları",
  "profileQuickActionFeed": "Akışım",
  "profileAccountSectionTitle": "Hesap",
  "profileAccountSecurityTitle": "Hesap Güvenliği",
  "profileAccountSecuritySubtitle": "Şifre ve e-posta değiştir",
  "profileBadgesBannerTitle": "Rozet Koleksiyonun",
  "profileBadgesBannerCount": "{count} rozetin var!",
  "@profileBadgesBannerCount": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  },
  "profileBadgesBannerSubtitle": "Keşfetmeye devam et, yeni rozetler kazan! 🚀",
  "profileIdentitySupportMessage": "Topluluğa katkılı yaparak profilini güçlendirebilirsin.",
```

- [ ] **Step 2: Add the new keys to `app_en.arb`**

Find this block (around line 3918-3921):

```json
  "profileGuestUser": "Guest",
  "@profileGuestUser": {
    "description": "Auto metadata for profileGuestUser"
  },
  "profileIdentitySupportMessage": "You can strengthen your profile by contributing to the community.",
```

Replace with:

```json
  "profileGuestUser": "Guest",
  "@profileGuestUser": {
    "description": "Auto metadata for profileGuestUser"
  },
  "profileHomeTitle": "Your Profile",
  "@profileHomeTitle": {
    "description": "Auto metadata for profileHomeTitle"
  },
  "profileStatFavoritesShort": "Favorites",
  "@profileStatFavoritesShort": {
    "description": "Auto metadata for profileStatFavoritesShort"
  },
  "profileStatReviewsShort": "Reviews",
  "@profileStatReviewsShort": {
    "description": "Auto metadata for profileStatReviewsShort"
  },
  "profileStatListsShort": "Lists",
  "@profileStatListsShort": {
    "description": "Auto metadata for profileStatListsShort"
  },
  "profileQuickActionsTitle": "Quick actions",
  "@profileQuickActionsTitle": {
    "description": "Auto metadata for profileQuickActionsTitle"
  },
  "profileQuickActionFavorites": "My Favorites",
  "@profileQuickActionFavorites": {
    "description": "Auto metadata for profileQuickActionFavorites"
  },
  "profileQuickActionPriceAlerts": "Price Alerts",
  "@profileQuickActionPriceAlerts": {
    "description": "Auto metadata for profileQuickActionPriceAlerts"
  },
  "profileQuickActionFeed": "My Feed",
  "@profileQuickActionFeed": {
    "description": "Auto metadata for profileQuickActionFeed"
  },
  "profileAccountSectionTitle": "Account",
  "@profileAccountSectionTitle": {
    "description": "Auto metadata for profileAccountSectionTitle"
  },
  "profileAccountSecurityTitle": "Account Security",
  "@profileAccountSecurityTitle": {
    "description": "Auto metadata for profileAccountSecurityTitle"
  },
  "profileAccountSecuritySubtitle": "Change password and email",
  "@profileAccountSecuritySubtitle": {
    "description": "Auto metadata for profileAccountSecuritySubtitle"
  },
  "profileBadgesBannerTitle": "Your Badge Collection",
  "@profileBadgesBannerTitle": {
    "description": "Auto metadata for profileBadgesBannerTitle"
  },
  "profileBadgesBannerCount": "You have {count} badges!",
  "@profileBadgesBannerCount": {
    "description": "Auto metadata for profileBadgesBannerCount",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  },
  "profileBadgesBannerSubtitle": "Keep exploring to earn new badges! 🚀",
  "@profileBadgesBannerSubtitle": {
    "description": "Auto metadata for profileBadgesBannerSubtitle"
  },
  "profileIdentitySupportMessage": "You can strengthen your profile by contributing to the community.",
```

- [ ] **Step 3: Regenerate localization code**

Run (from `uygulamalar/mobil/`): `flutter gen-l10n`
Expected: command exits with no output (or a short success message), and `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_tr.dart` are rewritten.

- [ ] **Step 4: Verify the new getters were generated**

Run: `grep -n "profileHomeTitle\|profileBadgesBannerCount" lib/l10n/app_localizations_tr.dart`
Expected: both `profileHomeTitle` (a `String get`) and `profileBadgesBannerCount` (a `String ... (int count)` method) appear.

- [ ] **Step 5: Run the l10n audit**

Run (from repo root): `node tools/ceviri-denetimi.mjs`
Expected: passes with no `TODO_EN:`/mojibake errors.

- [ ] **Step 6: Commit**

```bash
git add uygulamalar/mobil/lib/l10n/app_tr.arb uygulamalar/mobil/lib/l10n/app_en.arb uygulamalar/mobil/lib/l10n/app_localizations.dart uygulamalar/mobil/lib/l10n/app_localizations_en.dart uygulamalar/mobil/lib/l10n/app_localizations_tr.dart
git commit -m "feat(profile): add l10n keys for redesigned profile page"
```

---

## Task 3: Restyle `ProfileIdentityCard`

**Files:**
- Modify: `uygulamalar/mobil/lib/features/profile/ui/components/profile_identity_card.dart`

- [ ] **Step 1: Remove the support-message subtitle**

In `_buildContent`, find:

```dart
                const SizedBox(height: 2),
                Text(
                  t.profileIdentitySupportMessage,
                  style: TextStyle(color: AppColors.muted),
                ),
                if (socialLinks.isNotEmpty) ...[
```

Replace with:

```dart
                if (socialLinks.isNotEmpty) ...[
```

- [ ] **Step 2: Make `_card()` return its child directly (no `Card` wrapper)**

Find:

```dart
  Widget _card({required Widget child}) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
```

Replace with:

```dart
  Widget _card({required Widget child}) => child;
```

- [ ] **Step 3: Run analyzer**

Run (from `uygulamalar/mobil/`): `flutter analyze`
Expected: `No issues found!`

Note: `t.profileIdentitySupportMessage` is now unused in this file but remains a valid ARB key/getter (per spec section 4) — `flutter analyze` does not flag unused l10n getters, and `tools/ceviri-denetimi.mjs` does not flag unused ARB keys.

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/mobil/lib/features/profile/ui/components/profile_identity_card.dart
git commit -m "refactor(profile): drop card chrome and support message from ProfileIdentityCard"
```

---

## Task 4: Add `_ProfileHomeHeader`

**Files:**
- Modify: `uygulamalar/mobil/lib/features/profile/ui/profile_page.dart`

- [ ] **Step 1: Add the new imports**

Find:

```dart
import '../../auth/domain/auth_providers.dart';
import '../../price_alerts/domain/price_alert_models.dart';
```

Replace with:

```dart
import '../../auth/domain/auth_providers.dart';
import '../../notifications/ui/components/notifications_bell.dart';
import '../../price_alerts/domain/price_alert_models.dart';
```

Find:

```dart
import '../domain/user_moat_signals.dart';
import 'profile_settings_page.dart';
```

Replace with:

```dart
import '../../taste_twin/domain/taste_twin_controllers.dart';
import '../domain/user_moat_signals.dart';
import 'profile_settings_page.dart';
```

- [ ] **Step 2: Add the `_ProfileHomeHeader` widget**

Find:

```dart
class _AlertsTab extends ConsumerWidget {
```

Replace with:

```dart
class _ProfileHomeHeader extends ConsumerWidget {
  const _ProfileHomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final user = ref.watch(userProvider);
    String? displayName;
    if (user != null) {
      final profileAsync = ref.watch(publicProfileProvider(user.id));
      final name = profileAsync.asData?.value.displayName.trim() ?? '';
      if (name.isNotEmpty) displayName = name;
    }
    final greeting = displayName != null
        ? t.discoveryGreetingHello(displayName)
        : t.discoveryGreetingHelloAnon;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  t.profileHomeTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Bildirim Kutusu',
            onPressed: () => context.go('/inbox'),
            icon: const NotificationsBell(),
          ),
        ],
      ),
    );
  }
}

class _AlertsTab extends ConsumerWidget {
```

- [ ] **Step 3: Insert the header as the first `ListView` child**

Find:

```dart
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ProfileIdentityCard(userEmail: user?.email),
```

Replace with:

```dart
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _ProfileHomeHeader(),
          const SizedBox(height: 12),
          ProfileIdentityCard(userEmail: user?.email),
```

- [ ] **Step 4: Run analyzer**

Run (from `uygulamalar/mobil/`): `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/mobil/lib/features/profile/ui/profile_page.dart
git commit -m "feat(profile): add greeting header to profile page"
```

---

## Task 5: Add `_ProfileHeroCard` (location row + stats row)

**Files:**
- Modify: `uygulamalar/mobil/lib/features/profile/ui/profile_page.dart`

- [ ] **Step 1: Add the new imports**

Find:

```dart
import '../../../app/theme/colors.dart';
import '../../../core/i18n/app_localizations.dart';
```

Replace with:

```dart
import '../../../app/theme/colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/location/user_location_controller.dart';
```

Find:

```dart
import '../domain/daily_micro_task.dart';
import '../domain/daily_micro_task_provider.dart';
```

Replace with:

```dart
import '../domain/daily_micro_task.dart';
import '../domain/daily_micro_task_provider.dart';
import '../domain/favorite_collections_count_provider.dart';
```

Find:

```dart
import '../../../features/shared/ui/achievements/achievement_visuals.dart';
```

Replace with:

```dart
import '../../../features/shared/ui/achievements/achievement_visuals.dart';
import '../../../features/shared/ui/design_system.dart';
```

- [ ] **Step 2: Add `_ProfileLocationRow`, `_StatCell`, `_ProfileStatsRow`, `_ProfileHeroCard`**

Find:

```dart
class _ProfileHomeHeader extends ConsumerWidget {
```

Replace with:

```dart
class _ProfileLocationRow extends ConsumerWidget {
  const _ProfileLocationRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(userLocationProvider);
    if (loc.loading || loc.permissionDenied || !loc.hasLocation) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 16,
            color: AppColors.muted,
          ),
          const SizedBox(width: 4),
          Text(
            loc.city!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final int? value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value?.toString() ?? '—',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

class _ProfileStatsRow extends ConsumerWidget {
  const _ProfileStatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final statsAsync = ref.watch(myProfileStatsProvider);
    final collectionsAsync = ref.watch(myFavoriteCollectionsCountProvider);

    return Row(
      children: [
        Expanded(
          child: _StatCell(
            value: statsAsync.asData?.value.favoritesCount,
            label: t.profileStatFavoritesShort,
          ),
        ),
        Expanded(
          child: _StatCell(
            value: statsAsync.asData?.value.reviewsCount,
            label: t.profileStatReviewsShort,
          ),
        ),
        Expanded(
          child: _StatCell(
            value: collectionsAsync.asData?.value,
            label: t.profileStatListsShort,
          ),
        ),
      ],
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({this.userEmail});

  final String? userEmail;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Container(
      padding: EdgeInsets.all(tokens.space16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(tokens.radius16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileIdentityCard(userEmail: userEmail),
          const _ProfileLocationRow(),
          SizedBox(height: tokens.space12),
          const _ProfileStatsRow(),
        ],
      ),
    );
  }
}

class _ProfileHomeHeader extends ConsumerWidget {
```

- [ ] **Step 3: Replace the `ProfileIdentityCard` ListView entry with `_ProfileHeroCard`**

Find:

```dart
          const _ProfileHomeHeader(),
          const SizedBox(height: 12),
          ProfileIdentityCard(userEmail: user?.email),
          const SizedBox(height: 12),
```

Replace with:

```dart
          const _ProfileHomeHeader(),
          const SizedBox(height: 12),
          _ProfileHeroCard(userEmail: user?.email),
          const SizedBox(height: 12),
```

- [ ] **Step 4: Run analyzer**

Run (from `uygulamalar/mobil/`): `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/mobil/lib/features/profile/ui/profile_page.dart
git commit -m "feat(profile): add hero card with location and stats row"
```

---

## Task 6: Add `_ProfileQuickActionsGrid` and `_ProfileAccountList`, remove old settings/security cards

**Files:**
- Modify: `uygulamalar/mobil/lib/features/profile/ui/profile_page.dart`

- [ ] **Step 1: Add `_QuickActionTile`, `_ProfileQuickActionsGrid`, `_ProfileAccountList`**

Find:

```dart
class _ProfileLocationRow extends ConsumerWidget {
```

Replace with:

```dart
class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(tokens.radius12),
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: tokens.minHitTarget * 1.4),
        padding: EdgeInsets.all(tokens.space12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(tokens.radius12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary),
            SizedBox(height: tokens.space8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileQuickActionsGrid extends StatelessWidget {
  const _ProfileQuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.profileQuickActionsTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textStrong,
          ),
        ),
        SizedBox(height: tokens.space8),
        Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                icon: Icons.favorite_border,
                label: t.profileQuickActionFavorites,
                onTap: () => context.go('/favorites'),
              ),
            ),
            SizedBox(width: tokens.space8),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.notifications_active_outlined,
                label: t.profileQuickActionPriceAlerts,
                onTap: () => DefaultTabController.of(context).animateTo(1),
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.space8),
        Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                icon: Icons.dynamic_feed_outlined,
                label: t.profileQuickActionFeed,
                onTap: () => DefaultTabController.of(context).animateTo(2),
              ),
            ),
            SizedBox(width: tokens.space8),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.settings_outlined,
                label: t.profileSettings,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileSettingsPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileAccountList extends StatelessWidget {
  const _ProfileAccountList();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.profileAccountSectionTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textStrong,
          ),
        ),
        SizedBox(height: tokens.space8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(tokens.radius16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(t.profileSettings),
                subtitle: Text(t.privacySocialSubtitle),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileSettingsPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: AppColors.border),
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: Text(t.profileAccountSecurityTitle),
                subtitle: Text(t.profileAccountSecuritySubtitle),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/account-security'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileLocationRow extends ConsumerWidget {
```

- [ ] **Step 2: Replace the old settings/security cards in the `ListView` with the new widgets**

Find:

```dart
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: Text(t.profileSettings),
              subtitle: Text(t.privacySocialSubtitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfileSettingsPage(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Hesap Güvenliği'),
              subtitle: const Text('Şifre ve e-posta değiştir'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/account-security'),
            ),
          ),
          const SizedBox(height: 12),
```

Replace with:

```dart
          const _ProfileQuickActionsGrid(),
          const SizedBox(height: 12),
          const _ProfileAccountList(),
          const SizedBox(height: 12),
```

- [ ] **Step 3: Run analyzer**

Run (from `uygulamalar/mobil/`): `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/mobil/lib/features/profile/ui/profile_page.dart
git commit -m "feat(profile): add quick actions grid and grouped account list"
```

---

## Task 7: Add `_ProfileBadgesBanner`, convert `_ProfileTab` to hold a scroll-to-achievements key

**Files:**
- Modify: `uygulamalar/mobil/lib/features/profile/ui/profile_page.dart`

- [ ] **Step 1: Add `_ProfileBadgesBanner`**

Find:

```dart
class _QuickActionTile extends StatelessWidget {
```

Replace with:

```dart
class _ProfileBadgesBanner extends ConsumerWidget {
  const _ProfileBadgesBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    final progress = ref.watch(myProfileProgressProvider).asData?.value;
    if (progress == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(tokens.space16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(tokens.radius16),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_outlined, color: AppColors.primary),
          SizedBox(width: tokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.profileBadgesBannerTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 2),
                Text(t.profileBadgesBannerCount(progress.unlockedCount)),
                const SizedBox(height: 2),
                Text(
                  t.profileBadgesBannerSubtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          IconButton(onPressed: onTap, icon: const Icon(Icons.arrow_forward)),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
```

- [ ] **Step 2: Convert `_ProfileTab` to `ConsumerStatefulWidget`**

Find:

```dart
class _ProfileTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
```

Replace with:

```dart
class _ProfileTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  final _achievementsSectionKey = GlobalKey();

  void _scrollToAchievements() {
    final ctx = _achievementsSectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
```

- [ ] **Step 3: Insert the badges banner into the `ListView`**

Find:

```dart
          const _ProfileAccountList(),
          const SizedBox(height: 12),
```

Replace with:

```dart
          const _ProfileAccountList(),
          const SizedBox(height: 12),
          _ProfileBadgesBanner(onTap: _scrollToAchievements),
          const SizedBox(height: 12),
```

- [ ] **Step 4: Wrap the achievements section with `_achievementsSectionKey`**

Find:

```dart
          Text(
            t.profileMyAchievementsTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          achievementsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (err, _) => _ErrorText(text: '$err'),
            data: (items) {
              if (items.isEmpty) {
                return _EmptyText(text: t.profileNoAchievementYet);
              }
              final latestUnlocked = items
                  .where((e) => e.unlocked && e.unlockedAt != null)
                  .fold<Achievement?>(
                    null,
                    (prev, curr) =>
                        prev == null ||
                            curr.unlockedAt!.isAfter(prev.unlockedAt!)
                        ? curr
                        : prev,
                  );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (latestUnlocked != null)
                    _LatestAchievementBanner(item: latestUnlocked),
                  const SizedBox(height: 8),
                  AchievementsGrid(items: items),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
```

Replace with:

```dart
          Column(
            key: _achievementsSectionKey,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.profileMyAchievementsTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 8),
              achievementsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => _ErrorText(text: '$err'),
                data: (items) {
                  if (items.isEmpty) {
                    return _EmptyText(text: t.profileNoAchievementYet);
                  }
                  final latestUnlocked = items
                      .where((e) => e.unlocked && e.unlockedAt != null)
                      .fold<Achievement?>(
                        null,
                        (prev, curr) =>
                            prev == null ||
                                curr.unlockedAt!.isAfter(prev.unlockedAt!)
                            ? curr
                            : prev,
                      );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (latestUnlocked != null)
                        _LatestAchievementBanner(item: latestUnlocked),
                      const SizedBox(height: 8),
                      AchievementsGrid(items: items),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run analyzer**

Run (from `uygulamalar/mobil/`): `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add uygulamalar/mobil/lib/features/profile/ui/profile_page.dart
git commit -m "feat(profile): add badge progress banner with scroll-to-achievements"
```

---

## Task 8: Widget tests for the redesigned `ProfilePage`

**Files:**
- Create: `uygulamalar/mobil/test/features/profile/ui/profile_page_test.dart`

- [ ] **Step 1: Write the test**

Create `uygulamalar/mobil/test/features/profile/ui/profile_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yeedoy/app/theme/app_tokens.dart';
import 'package:yeedoy/core/location/user_location_controller.dart';
import 'package:yeedoy/features/auth/domain/auth_providers.dart';
import 'package:yeedoy/features/profile/domain/favorite_collections_count_provider.dart';
import 'package:yeedoy/features/profile/ui/components/profile_identity_card.dart';
import 'package:yeedoy/features/profile/ui/profile_page.dart';
import 'package:yeedoy/l10n/app_localizations.dart';
import 'package:yeedoy/l10n/app_localizations_tr.dart';

ThemeData _theme() => ThemeData(
  extensions: const <ThemeExtension<dynamic>>[
    AppTokens(
      space4: 4,
      space8: 8,
      space12: 12,
      space16: 16,
      space20: 20,
      space24: 24,
      radius12: 12,
      radius16: 16,
      radius20: 20,
      radius24: 24,
      elevation1: 1,
      elevation2: 6,
      elevation3: 12,
      minHitTarget: 44,
      fast: Duration(milliseconds: 150),
      medium: Duration(milliseconds: 180),
      slow: Duration(milliseconds: 220),
    ),
  ],
);

class _FakeLocationController extends UserLocationController {
  @override
  UserLocationState build() => const UserLocationState(
    city: null,
    district: null,
    neighborhood: null,
    mode: 'auto',
    loading: false,
    permissionDenied: true,
    error: null,
  );
}

Future<void> _pumpProfilePage(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});

  final router = GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),
      GoRoute(
        path: '/favorites',
        builder: (_, _) => const Scaffold(body: Text('Favorites Page')),
      ),
      GoRoute(
        path: '/inbox',
        builder: (_, _) => const Scaffold(body: Text('Inbox Page')),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('Login Page')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userProvider.overrideWith((ref) => null),
        myProfileProvider.overrideWith((ref) async => null),
        myFavoriteCollectionsCountProvider.overrideWith((ref) async => 3),
        userLocationProvider.overrideWith(_FakeLocationController.new),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: _theme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final t = AppLocalizationsTr();

  group('ProfilePage redesign (guest)', () {
    testWidgets('renders home header, hero card, quick actions and account list', (
      tester,
    ) async {
      await _pumpProfilePage(tester);

      expect(find.text(t.profileHomeTitle), findsOneWidget);
      expect(find.text(t.discoveryGreetingHelloAnon), findsOneWidget);

      expect(find.text(t.profileQuickActionsTitle), findsOneWidget);
      expect(find.text(t.profileQuickActionFavorites), findsOneWidget);
      expect(find.text(t.profileQuickActionPriceAlerts), findsOneWidget);
      expect(find.text(t.profileQuickActionFeed), findsOneWidget);
      expect(find.text(t.profileSettings), findsNWidgets(2));

      expect(find.text(t.profileAccountSectionTitle), findsOneWidget);
      expect(find.text(t.profileAccountSecurityTitle), findsOneWidget);
      expect(find.text(t.profileAccountSecuritySubtitle), findsOneWidget);

      // Badges banner is hidden for guests (myProfileProgressProvider is null).
      expect(find.text(t.profileBadgesBannerTitle), findsNothing);

      // Location row is hidden when there is no device location.
      expect(find.byIcon(Icons.location_on_outlined), findsNothing);
    });

    testWidgets('Favorilerim quick action navigates to /favorites', (
      tester,
    ) async {
      await _pumpProfilePage(tester);

      await tester.tap(find.text(t.profileQuickActionFavorites));
      await tester.pumpAndSettle();

      expect(find.text('Favorites Page'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run the test**

Run (from `uygulamalar/mobil/`): `flutter test test/features/profile/ui/profile_page_test.dart`
Expected: `00:0X +2: All tests passed!`

If a test fails because a provider not overridden above throws synchronously (rather than surfacing as `AsyncError`), add the minimal override needed (e.g. `myAchievementsProvider.overrideWith((ref) async => const [])`) and re-run — do not change `profile_page.dart` to make the test pass.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/mobil/test/features/profile/ui/profile_page_test.dart
git commit -m "test(profile): cover redesigned profile page for guests"
```

---

## Task 9: Final validation

**Files:** none (validation only)

- [ ] **Step 1: Format touched files**

Run (from `uygulamalar/mobil/`):

```bash
dart format lib/features/profile lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_tr.dart test/features/profile
```

- [ ] **Step 2: Analyze**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: Full test suite**

Run: `flutter test`
Expected: all tests pass (baseline 318 passed / 4 skipped, plus the 2 new provider tests and 2 new widget tests from Tasks 1 and 8 → 322 passed / 4 skipped).

- [ ] **Step 4: l10n audit**

Run (from repo root): `node tools/ceviri-denetimi.mjs`
Expected: passes with no errors.

- [ ] **Step 5: Manual smoke check**

Run `flutter run` (or hot-reload an existing session) and open the Profile tab:
- Logged out: greeting "Hi 👋" / "Merhaba 👋", "Profilin" title, hero card with avatar/name (no location row, stats show "—"/0), quick-actions grid, account list, no badges banner, login prompt card, rest of page unchanged.
- Logged in: hero card shows real Favori/Yorum/Liste counts and (if device location is available) a location row; badges banner shows the real unlocked-achievement count and tapping its arrow scrolls to the achievements section.

- [ ] **Step 6: Commit (if formatting changed files)**

```bash
git add -A
git commit -m "chore(profile): format redesigned profile page files"
```

---

## Self-Review Notes

- **Spec coverage:** All of spec sections 2 (widget tree order), 3.1-3.9 (component details), 4 (ARB keys), 5 (files touched) are covered by Tasks 1-7. Section 6 (validation) is Task 9. Section 7's open questions were resolved during planning: `myProfileProgressProvider` returns `null` for guests (handled by `_ProfileBadgesBanner`'s early return), no existing quick-action/grouped-list primitive was found so new private widgets were added, and `AppColors`/`AppTokens` token availability was confirmed.
- **Placeholder scan:** No TBD/TODO markers; every step has complete code.
- **Type consistency:** `_ProfileHeroCard(userEmail: String?)`, `_ProfileBadgesBanner(onTap: VoidCallback)`, `_StatCell(value: int?, label: String)` are defined once (Tasks 5-7) and used with matching signatures in the `ListView` (Tasks 5-7). `_achievementsSectionKey` is defined and consumed within the same `_ProfileTabState` (Task 7). `myFavoriteCollectionsCountProvider` (Task 1) is consumed in `_ProfileStatsRow` (Task 5) and overridden in the test (Task 8) with matching `FutureProvider.autoDispose<int>` type.
