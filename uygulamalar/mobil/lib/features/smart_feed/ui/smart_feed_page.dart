import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/media/app_network_image.dart';
import '../../discovery/domain/business_card.dart';
import '../../discovery/domain/discovery_search_notifier.dart';
import '../domain/smart_feed_controller.dart';
import '../domain/smart_feed_models.dart';

class SmartFeedPage extends ConsumerStatefulWidget {
  const SmartFeedPage({super.key});

  @override
  ConsumerState<SmartFeedPage> createState() => _SmartFeedPageState();
}

class _SmartFeedPageState extends ConsumerState<SmartFeedPage> {
  final _feedPageCtrl = PageController();
  int _feedPage = 0;

  @override
  void dispose() {
    _feedPageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(smartFeedProvider);
    final discovery = ref.watch(discoverySearchProvider);
    final openNow = discovery.items.where((b) => b.isOpenNow == true).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () =>
          ref.read(smartFeedProvider.notifier).loadInitial(force: true),
      child: CustomScrollView(
        slivers: [
          // ── Page header ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Akıllı Akış',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textStrong,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sana özel öneriler, anlık keşifler',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── 3 quick-access cards ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickCard(
                          icon: Icons.favorite_rounded,
                          iconBg: const Color(0xFFFEE2E2),
                          iconColor: AppColors.primary,
                          title: 'Senin İçin',
                          titleColor: AppColors.primary,
                          desc: 'Zevklerine ve alışkanlıklarına göre öneriler',
                          onTap: () => context.go('/discover'),
                        ),
                      ),
                      VerticalDivider(
                        width: 1,
                        color: const Color(0xFFE5E7EB),
                      ),
                      Expanded(
                        child: _QuickCard(
                          icon: Icons.eco_rounded,
                          iconBg: const Color(0xFFDCFCE7),
                          iconColor: const Color(0xFF15803D),
                          title: 'Diyetine Uygun',
                          titleColor: const Color(0xFF15803D),
                          desc: 'Diyet profilinle uyumlu sağlıklı seçenekler',
                          onTap: () => context.go('/diet-profile'),
                        ),
                      ),
                      VerticalDivider(
                        width: 1,
                        color: const Color(0xFFE5E7EB),
                      ),
                      Expanded(
                        child: _QuickCard(
                          icon: Icons.bolt_rounded,
                          iconBg: const Color(0xFFFEF3C7),
                          iconColor: const Color(0xFFD97706),
                          title: 'Popüler',
                          titleColor: const Color(0xFFD97706),
                          desc: 'Şehrinde en çok beğenilen mekanlar',
                          onTap: () => context.go('/discover'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Nearby & open section ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Yakınında ve Şu An Açık',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/discover'),
                    child: const Text(
                      'Tümünü Gör',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 256,
              child: openNow.isEmpty
                  ? _buildNearbyPlaceholder(context)
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: openNow.length,
                      separatorBuilder: (_, i2) => const SizedBox(width: 12),
                      itemBuilder: (ctx, i) =>
                          _NearbyCard(item: openNow[i]),
                    ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Smart suggestions section ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Akıllı Öneriler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showWhySheet(context),
                    child: Row(
                      children: const [
                        Text(
                          'Neden bu öneriler?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.info_outline_rounded,
                            size: 14, color: AppColors.muted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: const [
                    Expanded(
                      child: _SmartFeature(
                        icon: Icons.psychology_rounded,
                        iconColor: Color(0xFF7C3AED),
                        iconBg: Color(0xFFEDE9FE),
                        label: 'Geçmiş tercihlerine benzer mekanlar',
                      ),
                    ),
                    Expanded(
                      child: _SmartFeature(
                        icon: Icons.favorite_rounded,
                        iconColor: Color(0xFFDB2777),
                        iconBg: Color(0xFFFCE7F3),
                        label: 'Beğendiğin lezzetlere göre eşleştirme',
                      ),
                    ),
                    Expanded(
                      child: _SmartFeature(
                        icon: Icons.access_time_rounded,
                        iconColor: Color(0xFF0D9488),
                        iconBg: Color(0xFFCCFBF1),
                        label: 'Gitme saatine göre kategoriler',
                      ),
                    ),
                    Expanded(
                      child: _SmartFeature(
                        icon: Icons.wb_sunny_rounded,
                        iconColor: Color(0xFFD97706),
                        iconBg: Color(0xFFFEF3C7),
                        label: 'Hava durumuna uygun öneriler',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Personalised feed section ───────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Sana Özel Bugünkü Akış',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textStrong,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          if (st.loading && st.items.isEmpty)
            const SliverToBoxAdapter(child: _FeedSkeleton())
          else if (!st.loading && st.items.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                child: Center(
                  child: Column(
                    children: const [
                      Icon(Icons.dynamic_feed_outlined,
                          size: 48, color: AppColors.muted),
                      SizedBox(height: 12),
                      Text(
                        'Henüz akış içeriği yok.\nKeşfetmeye başla!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: PageView.builder(
                  controller: _feedPageCtrl,
                  itemCount: st.items.length,
                  onPageChanged: (i) => setState(() => _feedPage = i),
                  itemBuilder: (ctx, i) =>
                      _FeedSwipeCard(item: st.items[i]),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    st.items.length.clamp(0, 6),
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _feedPage ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _feedPage
                            ? AppColors.primary
                            : const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildNearbyPlaceholder(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      separatorBuilder: (_, i2) => const SizedBox(width: 12),
      itemBuilder: (ctx, i) => Container(
        width: 196,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F7),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showWhySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Neden bu öneriler?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.textStrong,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Akıllı Akış; geçmiş ziyaretlerin, beğendiklerin, bulunduğun konum ve günün saatini analiz ederek sana özel öneriler sunar. Diyet profilin ve hava durumu da dikkate alınır.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick access card ─────────────────────────────────────────────────────────

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.titleColor,
    required this.desc,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final Color titleColor;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.muted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

// ── Nearby open business card ─────────────────────────────────────────────────

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({required this.item});
  final BusinessCardModel item;

  @override
  Widget build(BuildContext context) {
    final name = item.name;
    final district = item.district ?? '';
    final city = item.city ?? '';
    final location = [district, city].where((s) => s.isNotEmpty).join(', ');
    final rating = item.qualityScore ?? item.avgRating ?? 0.0;
    final reviewCount = item.reviewCount ?? 0;
    final distance = item.distanceKm;
    final tags = <String>[
      if (item.category.isNotEmpty) item.category,
    ];

    return GestureDetector(
      onTap: () => context.push('/b/${item.id}'),
      child: Container(
        width: 196,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (BusinessCardModel has no imageUrl field — show placeholder)
            Stack(
              children: [
                Container(
                  height: 128,
                  width: double.infinity,
                  color: AppColors.primarySoft,
                  child: const Center(
                    child: Icon(Icons.restaurant_outlined,
                        color: AppColors.primary, size: 36),
                  ),
                ),
                // Open badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15803D),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Şu an açık',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // Favorite button
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_outline_rounded,
                        size: 16, color: AppColors.muted),
                  ),
                ),
              ],
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.textStrong,
                      ),
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 11, color: AppColors.muted),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 12, color: AppColors.star),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textStrong,
                          ),
                        ),
                        if (reviewCount > 0) ...[
                          Text(
                            ' ($reviewCount)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                        if (distance != null) ...[
                          const Spacer(),
                          const Icon(Icons.near_me_outlined,
                              size: 11, color: AppColors.muted),
                          const SizedBox(width: 2),
                          Text(
                            distance < 1
                                ? '${(distance * 1000).round()} m'
                                : '${distance.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: tags.take(3).map((tag) => _Tag(tag)).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Smart feature item ────────────────────────────────────────────────────────

class _SmartFeature extends StatelessWidget {
  const _SmartFeature({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.muted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feed swipe card ───────────────────────────────────────────────────────────

class _FeedSwipeCard extends StatelessWidget {
  const _FeedSwipeCard({required this.item});
  final SmartFeedEvent item;

  @override
  Widget build(BuildContext context) {
    final imageUrl = (item.payload['image_url'] ?? '').toString().trim();
    final title = item.businessName;
    final subtitle = (item.payload['subtitle'] ?? '').toString();
    final distance = item.payload['distance_km'];
    final distLabel = distance is num
        ? (distance < 1
            ? '${(distance * 1000).round()} m'
            : '${distance.toStringAsFixed(1)} km')
        : null;
    final rating =
        (item.payload['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = (item.payload['review_count'] as int?) ?? 0;
    final tags = <String>[
      if ((item.payload['category'] ?? '').toString().isNotEmpty)
        item.payload['category'].toString(),
    ];
    final isDiscount =
        (item.payload['discount_pct'] as int?) ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => context.push('/b/${item.businessId}'),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              // Image
              Stack(
                children: [
                  SizedBox(
                    width: 140,
                    height: 220,
                    child: imageUrl.isNotEmpty
                        ? AppNetworkImage(
                            url: imageUrl,
                            width: 140,
                            height: 220,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: AppColors.primarySoft,
                            child: const Center(
                              child: Icon(Icons.restaurant_outlined,
                                  color: AppColors.primary, size: 40),
                            ),
                          ),
                  ),
                  if (isDiscount > 0)
                    Positioned(
                      top: 10,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          '%$isDiscount indirim',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Bugün senin için"
                      Row(
                        children: const [
                          Icon(Icons.auto_awesome,
                              size: 12, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Bugün senin için',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Bookmark + title
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textStrong,
                              ),
                            ),
                          ),
                          const Icon(Icons.bookmark_outline_rounded,
                              size: 18, color: AppColors.muted),
                        ],
                      ),
                      if (distLabel != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 12, color: AppColors.muted),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                distLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          children:
                              tags.take(3).map((t) => _Tag(t)).toList(),
                        ),
                      ],
                      const Spacer(),
                      if (rating > 0)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7F1D1D),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        size: 13, color: Colors.white),
                                    const SizedBox(width: 3),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                if (reviewCount > 0)
                                  Text(
                                    '($reviewCount)',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F7),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// ── Tag chip ──────────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.muted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
