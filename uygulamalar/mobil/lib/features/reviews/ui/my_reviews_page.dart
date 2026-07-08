import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/media/app_network_image.dart';
import '../../auth/domain/auth_providers.dart';
import '../domain/my_review_entry.dart';
import '../domain/reviews_provider.dart';

// ── Filter tab enum ───────────────────────────────────────────────────────────

enum _Tab { all, published, pending }

// ── Page ──────────────────────────────────────────────────────────────────────

class MyReviewsPage extends ConsumerStatefulWidget {
  const MyReviewsPage({super.key});

  @override
  ConsumerState<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends ConsumerState<MyReviewsPage> {
  _Tab _tab = _Tab.all;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    if (user == null) {
      return _buildUnauthenticated(context);
    }

    final reviewsAsync = ref.watch(myReviewsProvider(user.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            reviewsAsync.when(
              loading: () => const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (e, _) => Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppErrorMapper.message(e),
                          style: const TextStyle(color: AppColors.danger),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () =>
                              ref.invalidate(myReviewsProvider(user.id)),
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (reviews) {
                final filtered = _filterReviews(reviews, _tab);
                return Expanded(
                  child: _buildBody(context, reviews, filtered, user.id),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              _IconBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => context.canPop()
                    ? context.pop()
                    : context.go('/profile'),
              ),
              const Expanded(
                child: Text(
                  'Yorumlarım',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              _IconBtn(
                icon: Icons.tune_rounded,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Deneyimlerini paylaştığın mekanlar',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────────

  Widget _buildBody(
    BuildContext context,
    List<MyReviewEntry> all,
    List<MyReviewEntry> filtered,
    String userId,
  ) {
    final publishedCount =
        all.where((r) => r.status == 'approved').length;
    final pendingCount =
        all.where((r) => r.status == 'pending').length;

    return CustomScrollView(
      slivers: [
        // ── Tab bar ──────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _buildTabBar(all.length, publishedCount, pendingCount),
          ),
        ),

        // ── Hero card ─────────────────────────────────────────────────────────
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildHeroCard(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // ── Review list ───────────────────────────────────────────────────────
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (ctx2, i2) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) =>
                  _ReviewCard(entry: filtered[i], userId: userId),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          // ── Community guidelines card ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: _buildGuidelinesCard(context),
            ),
          ),
        ],
      ],
    );
  }

  // ── Tab bar ──────────────────────────────────────────────────────────────────

  Widget _buildTabBar(int total, int published, int pending) {
    return Row(
      children: [
        _TabChip(
          label: 'Tümü',
          count: total,
          icon: Icons.chat_bubble_outline_rounded,
          selected: _tab == _Tab.all,
          selectedColor: AppColors.primary,
          onTap: () => setState(() => _tab = _Tab.all),
        ),
        const SizedBox(width: 8),
        _TabChip(
          label: 'Yayınlanan',
          count: published,
          icon: Icons.check_circle_outline_rounded,
          selected: _tab == _Tab.published,
          selectedColor: const Color(0xFF16A34A),
          onTap: () => setState(() => _tab = _Tab.published),
        ),
        const SizedBox(width: 8),
        _TabChip(
          label: 'Bekleyen',
          count: pending,
          icon: Icons.access_time_rounded,
          selected: _tab == _Tab.pending,
          selectedColor: const Color(0xFFD97706),
          onTap: () => setState(() => _tab = _Tab.pending),
        ),
      ],
    );
  }

  // ── Hero card ─────────────────────────────────────────────────────────────────

  Widget _buildHeroCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Yorumların değerli!',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textStrong,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Deneyimlerin diğer kullanıcılara yol gösteriyor. Teşekkür ederiz.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Guidelines card ───────────────────────────────────────────────────────────

  Widget _buildGuidelinesCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/legal'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFE0E7FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Color(0xFF4F46E5),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yorumların bizim için önemli',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.textStrong,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Topluluk kurallarımıza uygun yapılan yorumlar yayınlanır. Detaylı bilgi için tıkla.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final label = switch (_tab) {
      _Tab.published => 'Yayınlanmış yorumun yok.',
      _Tab.pending => 'Onay bekleyen yorumun yok.',
      _Tab.all => 'Henüz yorum yapmadın.',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.rate_review_outlined,
              size: 52,
              color: AppColors.muted,
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Unauthenticated ───────────────────────────────────────────────────────────

  Widget _buildUnauthenticated(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.login_rounded,
                      size: 48,
                      color: AppColors.muted,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Yorumlarını görmek için giriş yap.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      onPressed: () =>
                          context.go('/login?redirect=/my-reviews'),
                      child: const Text('Giriş Yap'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  List<MyReviewEntry> _filterReviews(
    List<MyReviewEntry> all,
    _Tab tab,
  ) {
    return switch (tab) {
      _Tab.all => all,
      _Tab.published =>
        all.where((r) => r.status == 'approved').toList(),
      _Tab.pending =>
        all.where((r) => r.status == 'pending').toList(),
    };
  }
}

// ── Tab chip ──────────────────────────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? selectedColor : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? selectedColor
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : selectedColor,
              ),
              const SizedBox(width: 4),
              Text(
                '$label ($count)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textStrong,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Review card ───────────────────────────────────────────────────────────────

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({
    required this.entry,
    required this.userId,
  });

  final MyReviewEntry entry;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        onTap: () => context.push('/b/${entry.businessId}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Business image ────────────────────────────────────────────
              _BusinessImage(imageUrl: entry.businessImageUrl),
              const SizedBox(width: 12),
              // ── Content ───────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name row + badge + menu
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            entry.businessName.isNotEmpty
                                ? entry.businessName
                                : entry.businessId,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.textStrong,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _StatusBadge(status: entry.status),
                        const SizedBox(width: 4),
                        _MenuButton(entry: entry, userId: userId),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Location
                    _buildLocation(),
                    const SizedBox(height: 6),
                    // Stars + time
                    Row(
                      children: [
                        ..._buildStars(entry.rating),
                        const SizedBox(width: 6),
                        const Text(
                          '•',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _timeAgo(entry.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Content
                    Text(
                      entry.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Like count
                    if (entry.helpfulCount > 0)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite_outline_rounded,
                              size: 14,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${entry.helpfulCount}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocation() {
    final parts = <String>[
      if ((entry.businessDistrict ?? '').trim().isNotEmpty)
        entry.businessDistrict!.trim(),
      if ((entry.businessCity ?? '').trim().isNotEmpty)
        entry.businessCity!.trim(),
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 12,
          color: AppColors.muted,
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            parts.join(', '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildStars(int rating) {
    return List.generate(5, (i) {
      return Icon(
        i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
        size: 14,
        color: i < rating ? AppColors.star : AppColors.muted,
      );
    });
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Az önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} hafta önce';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} ay önce';
    return '${(diff.inDays / 365).floor()} yıl önce';
  }
}

// ── Business image ────────────────────────────────────────────────────────────

class _BusinessImage extends StatelessWidget {
  const _BusinessImage({this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    const size = 76.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null && imageUrl!.trim().isNotEmpty
            ? AppNetworkImage(
                url: imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
              )
            : Container(
                color: AppColors.primarySoft,
                child: const Icon(
                  Icons.restaurant_outlined,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color, bg) = switch (status) {
      'approved' => (
          'Yayınlandı',
          Icons.check_rounded,
          const Color(0xFF16A34A),
          const Color(0xFFDCFCE7),
        ),
      'pending' => (
          'Onay Bekliyor',
          Icons.access_time_rounded,
          const Color(0xFFD97706),
          const Color(0xFFFEF3C7),
        ),
      _ => (
          'Reddedildi',
          Icons.close_rounded,
          const Color(0xFFDC2626),
          const Color(0xFFFEE2E2),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 3-dot menu button ─────────────────────────────────────────────────────────

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.entry, required this.userId});
  final MyReviewEntry entry;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 18,
        color: AppColors.muted,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16),
              SizedBox(width: 8),
              Text('Düzenle'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
              SizedBox(width: 8),
              Text('Sil', style: TextStyle(color: AppColors.danger)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'edit') {
          context.push('/b/${entry.businessId}/review?edit=${entry.id}');
        }
      },
    );
  }
}

// ── Icon button ───────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4F5F7),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 18, color: AppColors.textStrong),
        ),
      ),
    );
  }
}
