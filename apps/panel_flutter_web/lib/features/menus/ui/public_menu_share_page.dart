import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/config/app_config.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/analytics/analytics_client.dart';
import '../../../core/analytics/analytics_repository.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/formatters.dart';
import '../../../core/media/app_network_image.dart';
import '../../../core/web/seo.dart';
import '../../../core/web/web_utils.dart';
import '../../../shared/ui/components/app_scaffold.dart';
import '../../../shared/ui/design_system.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/menu_repository.dart';

class PublicMenuSharePage extends ConsumerStatefulWidget {
  const PublicMenuSharePage({super.key, required this.menuId});
  final String menuId;

  @override
  ConsumerState<PublicMenuSharePage> createState() =>
      _PublicMenuSharePageState();
}

class _PublicMenuSharePageState extends ConsumerState<PublicMenuSharePage> {
  bool _seoSet = false;
  bool _loggedOpen = false;
  bool _loggedCheckin = false;
  int? _tableRating;
  bool _feedbackSent = false;
  bool _submittingFeedback = false;
  final TextEditingController _noteController = TextEditingController();

  // ── Realtime price updates ────────────────────────────────────────────────
  RealtimeChannel? _priceChannel;
  final Map<String, int> _priceOverrides = {};
  final Set<String> _flashItems = {};
  bool _realtimeActive = false;
  String? _subscribedBusinessId;

  @override
  void initState() {
    super.initState();
    _trackOpenOnce();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _priceChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeRealtimePrices(String businessId) {
    if (_subscribedBusinessId == businessId) return; // already subscribed
    _subscribedBusinessId = businessId;
    _priceChannel?.unsubscribe();

    final client = ref.read(supabaseProvider);
    _priceChannel = client
        .channel('public_menu_prices_$businessId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'menu_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'business_id',
            value: businessId,
          ),
          callback: (payload) {
            final rec = payload.newRecord;
            final itemId = rec['id']?.toString();
            final cents = rec['price_cents'];
            if (itemId == null || cents == null) return;
            if (!mounted) return;
            setState(() {
              _priceOverrides[itemId] = (cents as num).toInt();
              _flashItems.add(itemId);
            });
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) setState(() => _flashItems.remove(itemId));
            });
          },
        )
        .subscribe((status, [err]) {
          if (!mounted) return;
          setState(() {
            _realtimeActive =
                status == RealtimeSubscribeStatus.subscribed;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final repo = ref.watch(menuRepositoryProvider);

    return AppScaffold(
      appBar: AppBar(
        title: Text(
          t.appName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: repo.fetchPublicMenuShare(widget.menuId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(AppErrorMapper.message(snap.error)));
          }

          final data = snap.data ?? const {};
          final menu = data['menu'] as Map?;
          final sections =
              (data['sections'] as List?)?.whereType<Map>().toList() ?? [];
          if (menu == null) {
            _setSeoOnce(
              title: t.menuShareNotFoundTitle(t.appName),
              description: t.menuShareNotFoundDescription,
              url: Uri.base.toString(),
              siteName: t.appName,
            );
            return Center(child: Text(t.menuShareNotFoundDescription));
          }

          final businessId = (menu['business_id'] ?? '').toString();
          final menuTitle = (menu['title'] ?? t.menu).toString();
          final tableNo = (Uri.base.queryParameters['table'] ?? '').trim();
          final source = (Uri.base.queryParameters['src'] ?? '')
              .trim()
              .toLowerCase();

          // Subscribe to realtime price updates for this business
          if (businessId.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _subscribeRealtimePrices(businessId),
            );
          }

          if (source == 'qr' && businessId.isNotEmpty) {
            _logCheckinOnce(
              businessId: businessId,
              menuId: widget.menuId,
              tableNo: tableNo.isEmpty ? null : tableNo,
            );
          }

          return FutureBuilder<Map<String, dynamic>?>(
            future: businessId.isEmpty
                ? Future.value(null)
                : repo.fetchBusinessMini(businessId),
            builder: (context, bizSnap) {
              final business = bizSnap.data;
              final businessName = (business?['name'] ?? t.businessLabel)
                  .toString()
                  .trim();
              final logoUrl = (business?['logo_url'] ?? '').toString();
              final openNow = _readBool(
                menu,
                business,
                keys: const ['open_now', 'is_open_now', 'isOpenNow'],
              );
              final nearbyViews = _readInt(
                menu,
                business,
                keys: const [
                  'nearby_views',
                  'nearby_view_count',
                  'nearby_menu_views',
                  'menu_views_48h',
                  'view_count_48h',
                ],
              );
              final shareImage = _pickShareImage(menu, business);

              _setSeoOnce(
                title: '$menuTitle • $businessName | ${t.appName}',
                description: _buildDescription(
                  t,
                  menuTitle,
                  sections,
                  openNow: openNow,
                  nearbyViews: nearbyViews,
                ),
                imageUrl: shareImage ?? (logoUrl.isEmpty ? null : logoUrl),
                url: Uri.base.toString(),
                siteName: t.appName,
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (isMobileWeb()) ...[
                    _OpenAppBanner(
                      onOpen: () async {
                        await _trackAppInstall(businessId);
                        _openApp(businessId, widget.menuId);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (tableNo.isNotEmpty) ...[
                    _TableBadge(tableNo: tableNo),
                    const SizedBox(height: 10),
                  ],
                  _BusinessHeader(
                    businessName: businessName,
                    logoUrl: logoUrl,
                    menuTitle: menuTitle,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (openNow == true)
                        _ShareBadge(icon: Icons.schedule, label: t.openNow),
                      if (nearbyViews != null && nearbyViews > 0)
                        _ShareBadge(
                          icon: Icons.visibility_outlined,
                          label: t.nearbyPeopleViewed(nearbyViews),
                        ),
                      _ShareBadge(
                        icon: Icons.verified_outlined,
                        label: t.verifiedPrices,
                      ),
                      if (_realtimeActive)
                        const _LivePriceBadge(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (sections.isEmpty)
                    Text(t.menuContentNotFound)
                  else
                    for (final s in sections) ...[
                      _SectionBlock(
                        section: s,
                        priceOverrides: _priceOverrides,
                        flashItems: _flashItems,
                      ),
                      const SizedBox(height: 16),
                    ],
                  if (tableNo.isNotEmpty && businessId.isNotEmpty) ...[
                    _TableFeedbackCard(
                      tableNo: tableNo,
                      rating: _tableRating,
                      noteController: _noteController,
                      submitting: _submittingFeedback,
                      sent: _feedbackSent,
                      onRatingSelect: (value) =>
                          setState(() => _tableRating = value),
                      onSubmit: () => _submitFeedback(businessId, tableNo),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 8),
                  _FooterBadge(label: t.preparedWithApp(t.appName)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _setSeoOnce({
    required String title,
    String? description,
    String? imageUrl,
    String? url,
    String? siteName,
  }) {
    if (!kIsWeb || _seoSet) return;
    _seoSet = true;
    setSeo(
      title: title,
      description: description,
      imageUrl: imageUrl,
      url: url,
      siteName: siteName,
    );
  }

  void _openApp(String businessId, String menuId) {
    final deepLink = AppConfig.menuDeepLink(
      menuId: menuId,
      businessId: businessId,
    );
    final fallback = '/menu/$menuId';
    openAppLinkWithFallback(appUrl: deepLink, fallbackUrl: fallback);
  }

  Future<void> _trackOpenOnce() async {
    if (_loggedOpen) return;
    _loggedOpen = true;
    final source = Uri.base.queryParameters['src'];
    final clientId = await getAnalyticsClientId();
    final analytics = ref.read(analyticsRepositoryProvider);
    await analytics.logEvent(
      eventName: 'menu_link_opened',
      menuId: widget.menuId,
      source: source,
      clientId: clientId,
    );
    if (source == 'qr') {
      await analytics.logEvent(
        eventName: 'qr_scanned',
        menuId: widget.menuId,
        source: 'qr',
        clientId: clientId,
      );
    }
  }

  Future<void> _trackAppInstall(String businessId) async {
    final clientId = await getAnalyticsClientId();
    await ref
        .read(analyticsRepositoryProvider)
        .logEvent(
          eventName: 'app_install_from_menu',
          businessId: businessId.isEmpty ? null : businessId,
          menuId: widget.menuId,
          source: 'open_app',
          clientId: clientId,
        );
  }

  Future<void> _logCheckinOnce({
    required String businessId,
    required String menuId,
    required String? tableNo,
  }) async {
    if (_loggedCheckin) return;
    _loggedCheckin = true;
    try {
      final clientId = await getAnalyticsClientId();
      await ref
          .read(supabaseProvider)
          .rpc(
            'log_checkin_v1',
            params: {
              'p_business_id': businessId,
              'p_menu_id': menuId,
              'p_table_no': tableNo,
              'p_client_id': clientId,
            },
          );
    } catch (_) {
      // Silent fail on web open.
    }
  }

  Future<void> _submitFeedback(String businessId, String tableNo) async {
    final t = AppLocalizations.of(context);
    if (_feedbackSent || _submittingFeedback) return;
    final rating = _tableRating;
    if (rating == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.selectRatingFirst)));
      return;
    }
    setState(() => _submittingFeedback = true);
    try {
      final clientId = await getAnalyticsClientId();
      final res = await ref
          .read(supabaseProvider)
          .rpc(
            'submit_table_feedback_v1',
            params: {
              'p_business_id': businessId,
              'p_table_no': tableNo,
              'p_rating': rating,
              'p_note': _noteController.text.trim().isEmpty
                  ? null
                  : _noteController.text.trim(),
              'p_client_id': clientId,
            },
          );
      final ok = res is Map && res['ok'] == true;
      if (!ok) {
        final code = (res is Map ? res['code'] : null)?.toString() ?? 'unknown';
        throw Exception(code);
      }
      if (!mounted) return;
      setState(() {
        _feedbackSent = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.thankYou)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    } finally {
      if (mounted) setState(() => _submittingFeedback = false);
    }
  }
}

class _OpenAppBanner extends StatelessWidget {
  const _OpenAppBanner({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.open_in_new, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t.openAppForBetterExperience,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          FilledButton(onPressed: onOpen, child: Text(t.openApp)),
        ],
      ),
    );
  }
}

class _BusinessHeader extends StatelessWidget {
  const _BusinessHeader({
    required this.businessName,
    required this.logoUrl,
    required this.menuTitle,
  });

  final String businessName;
  final String logoUrl;
  final String menuTitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (logoUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AppNetworkImage(
              url: logoUrl,
              variant: AppImageVariant.thumb,
              width: 48,
              height: 48,
              borderRadius: BorderRadius.circular(12),
            ),
          )
        else
          _logoFallback(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                businessName,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(menuTitle, style: const TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _logoFallback() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.storefront, color: AppColors.slate),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.section,
    this.priceOverrides = const {},
    this.flashItems = const {},
  });

  final Map section;
  final Map<String, int> priceOverrides;
  final Set<String> flashItems;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final title = (section['title'] ?? '').toString();
    final items =
        (section['items'] as List?)?.whereType<Map>().toList() ?? const <Map>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(t.noProductsFound)
        else
          for (final item in items) ...[
            _MenuItemRow(
              item: item,
              priceOverrides: priceOverrides,
              flashItems: flashItems,
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _MenuItemRow extends StatelessWidget {
  const _MenuItemRow({
    required this.item,
    this.priceOverrides = const {},
    this.flashItems = const {},
  });

  final Map item;
  final Map<String, int> priceOverrides;
  final Set<String> flashItems;

  @override
  Widget build(BuildContext context) {
    final itemId = (item['id'] ?? '').toString();
    final name = (item['name'] ?? '').toString();
    final desc = (item['description'] ?? '').toString();

    // Use realtime override if available, else original
    final rawCents = priceOverrides.containsKey(itemId)
        ? priceOverrides[itemId]
        : item['price_cents'] as num?;
    final price = _fmtPrice(context, rawCents, item['currency']?.toString());
    final isFlashing = flashItems.contains(itemId);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isFlashing
            ? const Color(0xFFDCFCE7)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                if (desc.trim().isNotEmpty)
                  Text(
                    desc,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              if (isFlashing)
                const Text(
                  'güncellendi',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LivePriceBadge extends StatefulWidget {
  const _LivePriceBadge();

  @override
  State<_LivePriceBadge> createState() => _LivePriceBadgeState();
}

class _LivePriceBadgeState extends State<_LivePriceBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 7, color: Color(0xFF16A34A)),
            SizedBox(width: 4),
            Text(
              'Canlı Fiyatlar',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF15803D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterBadge extends StatelessWidget {
  const _FooterBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(color: AppColors.muted, fontSize: 12),
      ),
    );
  }
}

class _ShareBadge extends StatelessWidget {
  const _ShareBadge({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textStrong),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

String _fmtPrice(BuildContext context, num? cents, String? currency) {
  if (cents == null) return '—';
  return formatCurrency(
    context,
    cents / 100.0,
    currencyCode: currency ?? 'TRY',
  );
}

String _buildDescription(
  AppLocalizations t,
  String menuTitle,
  List<Map> sections, {
  bool? openNow,
  int? nearbyViews,
}) {
  final items = <String>[];
  for (final s in sections) {
    final list =
        (s['items'] as List?)?.whereType<Map>().toList() ?? const <Map>[];
    for (final i in list) {
      final name = (i['name'] ?? '').toString().trim();
      if (name.isNotEmpty) items.add(name);
      if (items.length >= 6) break;
    }
    if (items.length >= 6) break;
  }
  if (items.isEmpty) return menuTitle;
  final parts = <String>[menuTitle, items.join(', ')];
  if (openNow == true) parts.add(t.openNow);
  if (nearbyViews != null && nearbyViews > 0) {
    parts.add(t.nearbyPeopleViewed(nearbyViews));
  }
  return parts.join(' • ');
}

bool? _readBool(Map? menu, Map? business, {required List<String> keys}) {
  for (final key in keys) {
    final value = menu?[key] ?? business?[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
  }
  return null;
}

int? _readInt(Map? menu, Map? business, {required List<String> keys}) {
  for (final key in keys) {
    final value = menu?[key] ?? business?[key];
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

String? _pickShareImage(Map menu, Map? business) {
  final candidates = [
    menu['share_image_url'],
    menu['cover_url'],
    menu['photo_url'],
    menu['image_url'],
    menu['hero_url'],
    business?['share_image_url'],
    business?['cover_url'],
    business?['logo_url'],
  ];
  for (final item in candidates) {
    final value = (item ?? '').toString().trim();
    if (value.isNotEmpty) return value;
  }
  return null;
}

class _TableBadge extends StatelessWidget {
  const _TableBadge({required this.tableNo});
  final String tableNo;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          t.tableLabel(tableNo),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _TableFeedbackCard extends StatelessWidget {
  const _TableFeedbackCard({
    required this.tableNo,
    required this.rating,
    required this.noteController,
    required this.submitting,
    required this.sent,
    required this.onRatingSelect,
    required this.onSubmit,
  });

  final String tableNo;
  final int? rating;
  final TextEditingController noteController;
  final bool submitting;
  final bool sent;
  final ValueChanged<int> onRatingSelect;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.tableServiceQuestion(tableNo),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: List.generate(5, (i) {
              final value = i + 1;
              return AppFilterChip(
                label: '$value',
                selected: rating == value,
                onTap: sent || submitting ? () {} : () => onRatingSelect(value),
              );
            }),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: noteController,
            minLines: 1,
            maxLines: 2,
            decoration: InputDecoration(hintText: t.shortNoteOptional),
            enabled: !sent && !submitting,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: sent || submitting ? null : onSubmit,
              child: Text(
                sent ? t.submitted : (submitting ? t.submitting : t.submit),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
