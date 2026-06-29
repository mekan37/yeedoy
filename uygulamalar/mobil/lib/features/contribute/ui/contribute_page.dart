import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../../../app/theme/colors.dart';
import '../../../core/linking/yeedoy_route_resolver.dart';
import '../../../features/profile/domain/contribution_history.dart';
import '../../../features/profile/domain/contribution_history_provider.dart';
import '../../../features/profile/domain/profile_stats_provider.dart';

class ContributePage extends ConsumerStatefulWidget {
  const ContributePage({super.key});

  @override
  ConsumerState<ContributePage> createState() => _ContributePageState();
}

class _ContributePageState extends ConsumerState<ContributePage> {
  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(contributionHistoryProvider);
    final statsAsync = ref.watch(myProfileStatsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(contributionHistoryProvider);
            ref.invalidate(myProfileStatsProvider);
          },
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHeader(context),
              _buildHeroCard(context),
              const SizedBox(height: 16),
              _buildActionTiles(context),
              const SizedBox(height: 24),
              historyAsync.when(
                loading: () => _buildRecentSection(context, null),
                error: (e, st) => const SizedBox.shrink(),
                data: (h) => _buildRecentSection(context, h),
              ),
              const SizedBox(height: 16),
              statsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
                data: (stats) => historyAsync.whenData((h) {
                  final thisWeek = h.recentItems
                      .where((i) => i.createdAt.isAfter(
                            DateTime.now().subtract(const Duration(days: 7)),
                          ))
                      .length;
                  return _buildStatsCard(
                    score: stats.contributionScore,
                    weeklyCount: thisWeek,
                  );
                }).value ?? const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merhaba! 👋',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                SizedBox(height: 2),
                Text(
                  'Katkı Yap',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Topluluğa katkı sağlayarak menüleri ve fiyatları güncel tut.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: const Color(0xFFF4F5F7),
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () => context.push('/inbox'),
                  icon: const Icon(
                    Icons.notifications_outlined,
                    size: 22,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Hero card ────────────────────────────────────────────────────────────────

  Widget _buildHeroCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 12, 18),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFBCFCF)),
        ),
        child: Row(
          children: [
            // Star with sparkles
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Icon(Icons.star_rounded, color: AppColors.primary, size: 34),
                  const Positioned(
                    top: 6,
                    right: 4,
                    child: Text('✦', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                  ),
                  const Positioned(
                    bottom: 8,
                    left: 4,
                    child: Text('✦', style: TextStyle(fontSize: 8, color: AppColors.primary)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Katkıların değerli!',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.textStrong,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Doğrulanan katkılarla puan ve rozet kazan.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Action tiles ─────────────────────────────────────────────────────────────

  Widget _buildActionTiles(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.qr_code_2_rounded,
            title: 'QR Menü Tara',
            subtitle: 'Mekanın QR menüsünü hızlıca tara',
            onTap: () => _startQrScan(context),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.camera_alt_outlined,
            title: 'Fotoğraf Yükle',
            subtitle: 'Menü, mekan veya yemek fotoğrafı ekle',
            onTap: () => _openContributeSheet(context),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.local_offer_outlined,
            title: 'Fiyat Değişimi Doğrula',
            subtitle: 'Güncel fiyat bilgisini onayla',
            onTap: () => _openContributeSheet(context),
          ),
        ],
      ),
    );
  }

  // ── Recent contributions ──────────────────────────────────────────────────

  Widget _buildRecentSection(BuildContext context, ContributionHistory? history) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Son katkıların',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Tümünü gör'),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: _buildRecentList(history),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentList(ContributionHistory? history) {
    if (history == null) {
      return Column(
        children: List.generate(3, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }),
      );
    }

    final items = history.recentItems.take(3).toList();

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Henüz katkın yok.\nYukarıdan bir katkı türü seçerek başlayabilirsin!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.5),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: 68),
          _RecentItem(item: items[i]),
        ],
      ],
    );
  }

  // ── Stats card ────────────────────────────────────────────────────────────

  Widget _buildStatsCard({required int score, required int weeklyCount}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFBCFCF)),
        ),
        child: Row(
          children: [
            // Icon
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star_rounded, color: Colors.white, size: 26),
                ),
                const Positioned(
                  top: 2,
                  right: 0,
                  child: Text('✦', style: TextStyle(fontSize: 9, color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // Score
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Katkı puanın',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            Container(
              width: 1,
              height: 40,
              color: const Color(0xFFFBCFCF),
              margin: const EdgeInsets.symmetric(horizontal: 14),
            ),
            // Weekly
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bu hafta',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  Text(
                    '$weeklyCount katkı yaptın',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            // Medal icon
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.military_tech_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _startQrScan(BuildContext context) async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (!mounted || file == null) return;

    final scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    try {
      final input = InputImage.fromFilePath(file.path);
      final barcodes = await scanner.processImage(input);
      String? decoded;
      for (final b in barcodes) {
        final v = b.rawValue?.trim();
        if (v != null && v.isNotEmpty) {
          decoded = v;
          break;
        }
      }
      if (!mounted) return;
      if (decoded != null) {
        final route = resolveYeedoyRouteFromQr(decoded);
        if (route != null) {
          router.go(route);
          return;
        }
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('QR kod okundu, incelemeye gönderildi.')),
      );
    } finally {
      await scanner.close();
    }
  }

  void _openContributeSheet(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Katkı yapmak için bir işletme sayfasını ziyaret edin.',
        ),
      ),
    );
    context.go('/discover');
  }
}

// ── Action tile ───────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textStrong,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent item row ───────────────────────────────────────────────────────────

class _RecentItem extends StatelessWidget {
  const _RecentItem({required this.item});
  final ContributionHistoryItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Type icon in circle
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_typeIcon(item.type), color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textStrong,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _typeLabel(item.type),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 1),
                Text(
                  _timeAgo(item.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusBadge(status: item.status),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.muted,
            size: 18,
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) => switch (type) {
        'price' => Icons.local_offer_outlined,
        'menu' => Icons.restaurant_menu_outlined,
        _ => Icons.storefront_outlined,
      };

  String _typeLabel(String type) => switch (type) {
        'price' => 'Fiyat doğrulaması',
        'menu' => 'Menü katkısı',
        _ => 'İşletme önerisi',
      };
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      'approved' => _Chip(
          icon: Icons.check_circle_outline_rounded,
          label: 'Onaylandı',
          iconColor: const Color(0xFF16A34A),
          bg: const Color(0xFFDCFCE7),
          text: const Color(0xFF16A34A),
        ),
      'rejected' => _Chip(
          icon: Icons.cancel_outlined,
          label: 'Reddedildi',
          iconColor: AppColors.danger,
          bg: const Color(0xFFFEE2E2),
          text: AppColors.danger,
        ),
      'under_review' => _Chip(
          icon: Icons.visibility_outlined,
          label: 'İnceleniyor',
          iconColor: const Color(0xFF3B82F6),
          bg: const Color(0xFFDBEAFE),
          text: const Color(0xFF3B82F6),
        ),
      _ => _Chip(
          icon: Icons.hourglass_bottom_rounded,
          label: 'Beklemede',
          iconColor: const Color(0xFFD97706),
          bg: const Color(0xFFFEF3C7),
          text: const Color(0xFFD97706),
        ),
    };
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bg,
    required this.text,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bg;
  final Color text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes} dakika önce';
  if (diff.inHours < 24) return '${diff.inHours} saat önce';
  if (diff.inDays == 1) return '1 gün önce';
  return '${diff.inDays} gün önce';
}
