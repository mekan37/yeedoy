# Sadakat v1 — Faz 4: Mobil UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mobil uygulamada müşterinin sadakat kartlarını ve kendi QR kodunu görebileceği ekranı, Faz 1'de tamamen değişen DB şemasına göre yeniden yazmak. `features/sadakat/` klasörü hâlâ eski (artık DB'de var olmayan) puan/tier şemasına göre yazılı; `/loyalty-cards` route'u hâlâ `/profile`'a redirect ediyor ve hiçbir nav girişi yok. Bu faz tamamlanınca Sadakat v1'in DB→owner-web→müşteri-web→mobil zinciri baştan sona kapanmış olacak.

**Architecture:** `features/sadakat/domain/sadakat_saglayicisi.dart`'taki model tamamen değişiyor (tier/puan kavramları kalkıyor, web'deki `SadakatKarti` şekliyle bire bir eşleşen basit bir `LoyaltyCard` modeli geliyor). UI dosyası aynı desende (AppScaffold/AppCard/AppEmptyState) kalıyor ama içerik web'in `/sadakat` sayfasıyla aynı bilgiyi gösteriyor: üstte `qr_flutter` ile üretilen kendi QR kodu (zaten mevcut bağımlılık, web'deki gibi `user.id`'yi düz metin kodluyor), altta kart listesi. Router'daki redirect kaldırılıyor, profil sayfasına gerçek bir nav girişi ekleniyor.

**Tech Stack:** Flutter/Dart, Riverpod (`FutureProvider.autoDispose`), `qr_flutter` (mevcut bağımlılık), go_router.

**Kapsam dışı:** Owner tarafı (QR okutma) mobilde YOK — CLAUDE.md kuralı: "No admin/owner CRUD in mobile app". Bu faz sadece müşteri (customer) tarafı.

---

### Task 1: Domain — yeni şemaya göre model + provider

**Files:**
- Modify: `uygulamalar/mobil/lib/features/sadakat/domain/sadakat_saglayicisi.dart` (tamamen değiştir)

- [ ] **Step 1: Dosyayı tamamen değiştir**

Replace the entire content of `uygulamalar/mobil/lib/features/sadakat/domain/sadakat_saglayicisi.dart` with:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_provider.dart';

class LoyaltyCard {
  LoyaltyCard({
    required this.programId,
    required this.mode,
    required this.businessName,
    this.logoUrl,
    required this.progress,
    required this.rewardThreshold,
    required this.rewardDesc,
  });

  final String programId;
  final String mode; // 'stamp' | 'points'
  final String businessName;
  final String? logoUrl;
  final int progress;
  final int rewardThreshold;
  final String rewardDesc;

  double get progressRatio =>
      rewardThreshold > 0 ? (progress / rewardThreshold).clamp(0.0, 1.0) : 0.0;

  factory LoyaltyCard.fromMap(Map<String, dynamic> m) => LoyaltyCard(
        programId: (m['program_id'] ?? '').toString(),
        mode: (m['mode'] as String?) ?? 'stamp',
        businessName: (m['business_name'] ?? '').toString(),
        logoUrl: m['logo_url'] as String?,
        progress: (m['progress'] as num?)?.toInt() ?? 0,
        rewardThreshold: (m['reward_threshold'] as num?)?.toInt() ?? 1,
        rewardDesc: (m['reward_desc'] as String?) ?? '',
      );
}

final myLoyaltyCardsProvider = FutureProvider.autoDispose<List<LoyaltyCard>>((ref) async {
  final client = ref.watch(supabaseProvider);
  if (client.auth.currentUser == null) return const [];

  final res = await client.rpc('get_my_loyalty_cards_v1');
  if (res == null) return const [];
  final list = res as List;
  return list.cast<Map<String, dynamic>>().map(LoyaltyCard.fromMap).toList();
});

/// Müşterinin owner'a gösterip taratacağı QR kodunun içeriği — düz metin
/// olarak kendi user id'si (web `/sadakat` sayfasıyla aynı format,
/// `scan_loyalty_qr_v1(business_id, user_id)` bunu doğrudan bekliyor).
final myLoyaltyQrDataProvider = Provider.autoDispose<String?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client.auth.currentUser?.id;
});
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/sadakat/domain/sadakat_saglayicisi.dart
git commit -m "feat(mobil): sadakat v1 — domain modeli yeni DB şemasına göre yeniden yazıldı (tier/puan kavramları kalktı)"
```

---

### Task 2: UI — QR kodu + kart listesi ekranı

**Files:**
- Modify: `uygulamalar/mobil/lib/features/sadakat/ui/sadakat_kartlarim_sayfasi.dart` (tamamen değiştir)

- [ ] **Step 1: Dosyayı tamamen değiştir**

Replace the entire content of `uygulamalar/mobil/lib/features/sadakat/ui/sadakat_kartlarim_sayfasi.dart` with:

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../features/shared/ui/components/app_appbar.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../../../features/shared/ui/design_system.dart';
import '../domain/sadakat_saglayicisi.dart';

class SadakatKartlarimSayfasi extends ConsumerWidget {
  const SadakatKartlarimSayfasi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(myLoyaltyCardsProvider);
    final qrData = ref.watch(myLoyaltyQrDataProvider);

    return AppScaffold(
      appBar: const AppAppBar(title: Text('Sadakat Kartlarım')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myLoyaltyCardsProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _QrKartim(qrData: qrData),
            const SizedBox(height: 20),
            cardsAsync.when(
              loading: () => const _LoyaltyCardsSkeleton(),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppErrorMapper.message(e),
                        style: const TextStyle(color: AppColors.danger),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => ref.invalidate(myLoyaltyCardsProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (cards) {
                if (cards.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.loyalty_rounded,
                    title: 'Henüz sadakat kartın yok',
                    description:
                        'Katıldığın işletmelerin sadakat programları burada görünecek.',
                  );
                }
                return Column(
                  children: [
                    for (final card in cards) ...[
                      RepaintBoundary(child: _LoyaltyCardItem(card: card)),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QrKartim extends StatelessWidget {
  const _QrKartim({required this.qrData});

  final String? qrData;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Text(
            'Damga/puan kazanmak için işletmede bu kodu gösterin.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          if (qrData != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: QrImageView(
                data: qrData!,
                version: QrVersions.auto,
                size: 200,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.textStrong,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.textStrong,
                ),
              ),
            )
          else
            const Text(
              'Kodunuzu görmek için giriş yapın.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          const SizedBox(height: 10),
          const Text(
            'Bu kod size özeldir, paylaşmayın.',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _LoyaltyCardItem extends StatelessWidget {
  const _LoyaltyCardItem({required this.card});

  final LoyaltyCard card;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BusinessAvatar(logoUrl: card.logoUrl, businessName: card.businessName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.businessName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.textStrong,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card.rewardDesc,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '${card.progress} / ${card.rewardThreshold}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textStrong,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: card.progressRatio,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessAvatar extends StatelessWidget {
  const _BusinessAvatar({required this.logoUrl, required this.businessName});

  final String? logoUrl;
  final String businessName;

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CachedNetworkImage(
          imageUrl: logoUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          memCacheWidth: 80,
          memCacheHeight: 80,
          placeholder: (ctx, url) => const SizedBox(width: 40, height: 40),
          errorWidget: (ctx, url, err) => _Initials(name: businessName),
        ),
      );
    }
    return _Initials(name: businessName);
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 16,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _LoyaltyCardsSkeleton extends StatelessWidget {
  const _LoyaltyCardsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++) ...[
          const AppSkeletonCard(lines: 3),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
```

Not: Kart artık tıklanamaz (eski dosyada işletme detayına gidiyordu, `card.businessId` kullanarak). Yeni RPC (`get_my_loyalty_cards_v1`) `business_id` döndürmüyor, sadece `business_name`/`logo_url` (bkz. Faz 1 şeması) — işletme detayına gitmenin doğru bir yolu şu an yok, bu yüzden bilerek eklenmedi. `go_router` importu da bu yüzden dosyada yok.

- [ ] **Step 2: `flutter analyze`**

Run (uygulamalar/mobil içinden): `flutter analyze`
Expected: Hata yok.

- [ ] **Step 3: Commit**

```bash
git add lib/features/sadakat/ui/sadakat_kartlarim_sayfasi.dart
git commit -m "feat(mobil): sadakat v1 — QR kodu + basitleştirilmiş kart listesi ekranı"
```

---

### Task 3: Router — redirect'i kaldır

**Files:**
- Modify: `uygulamalar/mobil/lib/app/router.dart`

- [ ] **Step 1: `/loyalty-cards` GoRoute bloğundaki redirect'i kaldır**

Find:
```dart
      GoRoute(
        path: '/loyalty-cards',
        // MVP defer: loyalty/sadakat özelliği kapalı (bkz.
        // docs/muhendislik/2026-yeedoy-loyalty-mvp-defer-decision.md).
        // Nav'dan erişim zaten kaldırıldı; deep-link/manuel URL erişimine
        // karşı güvenlik için redirect eklendi. DB/RPC dosyaları dokunulmadan
        // bırakıldı, route tanımı geriye dönük uyumluluk için saklı tutuldu.
        redirect: (c, s) => '/profile',
        pageBuilder: (c, s) => buildFadeSlidePage(
          state: s,
          child: const SadakatKartlarimSayfasi(),
        ),
      ),
```

Replace with:
```dart
      GoRoute(
        path: '/loyalty-cards',
        pageBuilder: (c, s) => buildFadeSlidePage(
          state: s,
          child: const SadakatKartlarimSayfasi(),
        ),
      ),
```

- [ ] **Step 2: `flutter analyze`**

Run (uygulamalar/mobil içinden): `flutter analyze`
Expected: Hata yok.

- [ ] **Step 3: Commit**

```bash
git add lib/app/router.dart
git commit -m "fix(mobil): sadakat v1 — /loyalty-cards redirect'ini kaldır, sayfa artık gerçek ve erişilebilir"
```

---

### Task 4: Profil sayfasına nav girişi ekle

**Files:**
- Modify: `uygulamalar/mobil/lib/features/profile/ui/profile_page.dart`

- [ ] **Step 1: `_ProfileAccountList`'e "Sadakat Kartlarım" satırını ekle**

Find (in `_ProfileAccountList.build`, after the "Diyet Profilim" `ListTile` + its `Divider`):

```dart
              ListTile(
                leading: const Icon(
                  Icons.restaurant_menu_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Diyet Profilim'),
                subtitle: const Text('Beslenme tercih ve alerjilerini belirt'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/diet-profile'),
              ),
              const Divider(height: 1, color: AppColors.border),
```

Replace with (adds a new ListTile + Divider right after):
```dart
              ListTile(
                leading: const Icon(
                  Icons.restaurant_menu_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Diyet Profilim'),
                subtitle: const Text('Beslenme tercih ve alerjilerini belirt'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/diet-profile'),
              ),
              const Divider(height: 1, color: AppColors.border),
              ListTile(
                leading: const Icon(
                  Icons.loyalty_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Sadakat Kartlarım'),
                subtitle: const Text('Kartlarını ve QR kodunu gör'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/loyalty-cards'),
              ),
              const Divider(height: 1, color: AppColors.border),
```

- [ ] **Step 2: `flutter analyze`**

Run (uygulamalar/mobil içinden): `flutter analyze`
Expected: Hata yok.

- [ ] **Step 3: Commit**

```bash
git add lib/features/profile/ui/profile_page.dart
git commit -m "feat(mobil): sadakat v1 — profil sayfasına Sadakat Kartlarım nav girişi ekle"
```

---

### Task 5: Doğrulama

**Files:** (yalnızca doğrulama, yeni kod yok)

- [ ] **Step 1: Tam `flutter analyze`**

Run (uygulamalar/mobil içinden): `flutter analyze`
Expected: Hata/uyarı yok.

- [ ] **Step 2: Dürüstlük notu**

Bu faz **canlı bir cihaz/emülatörde test edilmedi** — sadece statik analiz (`flutter analyze`) ile doğrulandı. Kullanıcıya raporda bu açıkça belirtilmeli (bu projede önceki mobil değişikliklerde de aynı dürüstlük notu kullanılmış — bkz. proje geçmişi, "cihazda test edilmedi" notları).

- [ ] **Step 3: Kullanıcıya rapor**

Değişen dosyalar, `flutter analyze` sonucu, cihazda test edilmediği notu — özetle. Bu, Sadakat v1'in tüm zincirinin (DB → owner web → müşteri web → mobil) kod olarak tamamlandığını, ama mobil tarafın gerçek cihazda doğrulanmadığını bildirir.
