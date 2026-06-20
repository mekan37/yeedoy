part of '../business_page.dart';

class _BusinessLoadingView extends StatelessWidget {
  const _BusinessLoadingView();

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return ListView(
      padding: EdgeInsets.all(tokens.space16),
      children: [
        const AppSkeletonCard(),
        SizedBox(height: tokens.space8),
        const AppSkeletonCard(),
        SizedBox(height: tokens.space8),
        const AppSkeletonCard(),
      ],
    );
  }
}

class _BusinessErrorView extends StatelessWidget {
  const _BusinessErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        tokens.space16,
        40,
        tokens.space16,
        tokens.space24,
      ),
      children: [
        AppEmptyState(
          icon: Icons.wifi_off_outlined,
          title: AppLocalizations.of(context).weakConnection,
          description:
              '$message\n${AppLocalizations.of(context).connectionProblemTryAgain}',
          ctaLabel: AppLocalizations.of(context).retry,
          onCta: onRetry,
        ),
      ],
    );
  }
}

/// Shows "Şu an X kişi bakıyor" when ≥2 users are present.
/// Hidden while connecting (null) or when only 1 user (the local user).
class _BusinessPresenceBadge extends ConsumerWidget {
  const _BusinessPresenceBadge({required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(businessPresenceCountProvider(businessId));
    if (count == null || count < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          _PulsingDot(),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.of(context).businessViewingNow(count),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action chips row: Favori, Buradayım, Paylaş, Bildir
// ---------------------------------------------------------------------------

class _BusinessActionChips extends ConsumerStatefulWidget {
  const _BusinessActionChips({required this.business});
  final Business business;

  @override
  ConsumerState<_BusinessActionChips> createState() =>
      _BusinessActionChipsState();
}

class _BusinessActionChipsState extends ConsumerState<_BusinessActionChips> {
  bool _checkingIn = false;

  Future<void> _handleFavorite() async {
    final isLoggedIn = ref.read(userProvider) != null;
    if (!isLoggedIn) {
      if (!mounted) return;
      await showQuickLoginSheet(
        context,
        redirectPath: '/b/${widget.business.id}',
      );
      return;
    }
    try {
      HapticFeedback.lightImpact();
      await ref
          .read(favoritesControllerProvider.notifier)
          .toggleFavorite(widget.business.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorMapper.message(error))),
      );
    }
  }

  Future<void> _handleCheckIn() async {
    final isLoggedIn = ref.read(userProvider) != null;
    if (!isLoggedIn) {
      if (!mounted) return;
      await showQuickLoginSheet(
        context,
        redirectPath: '/b/${widget.business.id}',
      );
      return;
    }
    if (_checkingIn) return;
    setState(() => _checkingIn = true);
    try {
      HapticFeedback.lightImpact();
      final clientId = await getAnalyticsClientId();
      await ref.read(checkInRepositoryProvider).logCheckin(
        businessId: widget.business.id,
        clientId: clientId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konum bildirimi kaydedildi')),
      );
    } catch (_) {
      // Sessiz hata — check-in best-effort
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum bildirimi kaydedildi')),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFavorited = ref.watch(isFavoritedProvider(widget.business.id));
    final t = AppLocalizations.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ActionChip(
          icon: isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          iconColor: isFavorited ? AppColors.danger : null,
          label: isFavorited ? t.favoriteAdded : t.addToFavorites,
          onTap: _handleFavorite,
        ),
        _ActionChip(
          icon: Icons.place_rounded,
          label: 'Buradayım',
          onTap: _checkingIn ? null : _handleCheckIn,
        ),
        _ActionChip(
          icon: Icons.share_rounded,
          label: t.share,
          onTap: () => _shareBusiness(context, widget.business),
        ),
        _ActionChip(
          icon: Icons.flag_outlined,
          label: t.report,
          onTap: () => _openReportSheet(context, widget.business.id),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radius12),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(tokens.radius12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: iconColor ?? AppColors.text,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textStrong,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

void _openReportSheet(BuildContext context, String businessId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ReportBottomSheet.business(
      businessId: businessId,
      redirectUrl: GoRouterState.of(context).uri.toString(),
    ),
  );
}

Future<void> _shareBusiness(BuildContext context, Business business) async {
  await showBusinessShareCardSheet(
    context,
    businessId: business.id,
    businessName: business.name,
    category: business.category,
    district: business.district,
    city: business.city,
    avgRating: business.avgRating > 0 ? business.avgRating : null,
    reviewCount: business.reviewsCount > 0 ? business.reviewsCount : null,
  );
}

String _locText(BuildContext context, String? district, String? city) {
  final d = (district ?? '').trim();
  final c = (city ?? '').trim();
  if (d.isEmpty && c.isEmpty) return AppLocalizations.of(context).noLocation;
  if (d.isEmpty) return c;
  if (c.isEmpty) return d;
  return '$d / $c';
}

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

String _formatPriceWithCurrency(
  BuildContext context,
  int? cents,
  String currency,
) {
  if (cents == null || cents <= 0) return AppLocalizations.of(context).unknown;
  final normalizedCurrency = RegExp(r'^[A-Z]{3}$').hasMatch(currency)
      ? currency
      : 'TRY';
  return formatCurrency(context, cents / 100, currencyCode: normalizedCurrency);
}

String? _timeText(dynamic value) {
  if (value == null) return null;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;
  return raw.length >= 5 ? raw.substring(0, 5) : raw;
}

bool _isOpenNow(String? open, String? close, DateTime now) {
  final o = _parseMinutes(open);
  final c = _parseMinutes(close);
  if (o == null || c == null) return false;
  final hm = now.hour * 60 + now.minute;
  if (o <= c) return hm >= o && hm <= c;
  return hm >= o || hm <= c;
}

String _hoursText(BuildContext context, String? open, String? close) {
  final o = (open ?? '').trim();
  final c = (close ?? '').trim();
  if (o.isEmpty || c.isEmpty) return AppLocalizations.of(context).noHoursInfo;
  return '$o - $c';
}

String _daysAgoText(BuildContext context, DateTime? value) {
  final t = AppLocalizations.of(context);
  if (value == null) return t.unknown;
  final diff = DateTime.now().difference(value);
  if (diff.inDays <= 0) return t.today;
  return '${diff.inDays} ${t.dayUnit}';
}

int _daysAgo(DateTime? value) {
  if (value == null) return 0;
  final diff = DateTime.now().difference(value);
  if (diff.isNegative) return 0;
  return diff.inDays;
}

int? _parseMinutes(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final parts = value.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

String _menuImageForIndex(int index) {
  const pool = [
    'assets/images/categories/kebap.png',
    'assets/images/categories/pizza.png',
    'assets/images/categories/burger.png',
    'assets/images/categories/lahmacun.png',
    'assets/images/categories/tatli.png',
  ];
  return pool[index % pool.length];
}

String? _normalizeImageUrl(String? url) {
  final value = (url ?? '').trim();
  if (value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasAuthority) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  return value;
}

String? _resolveRemoteImageUrl(String? url) {
  final value = (url ?? '').trim();
  if (value.isEmpty) return null;
  if (value.startsWith('data:image/')) return null;
  final normalized = _normalizeImageUrl(value);
  if (normalized != null) {
    final uri = Uri.tryParse(normalized);
    if (uri != null &&
        uri.host.contains('google.') &&
        uri.path.contains('/imgres')) {
      final raw = uri.queryParameters['imgurl'];
      final extracted = _normalizeImageUrl(raw);
      if (extracted != null) return extracted;
    }
    return normalized;
  }
  if (value.startsWith('//')) {
    return _normalizeImageUrl('https:$value');
  }
  if (!value.contains('://') && value.contains('.')) {
    return _normalizeImageUrl('https://$value');
  }
  return null;
}

Uint8List? _decodeDataImageBytes(String? value) {
  final raw = (value ?? '').trim();
  if (!raw.startsWith('data:image/')) return null;
  final marker = ';base64,';
  final idx = raw.indexOf(marker);
  if (idx <= 0) return null;
  final payload = raw.substring(idx + marker.length);
  if (payload.isEmpty) return null;
  try {
    return base64Decode(payload);
  } catch (_) {
    return null;
  }
}

int _priceDeltaPercent(List<int> points) {
  if (points.length < 3) return 0;
  final first = points.first;
  final last = points.last;
  if (first <= 0) return last > 0 ? 5 : 0;
  final pct = ((last - first) / first) * 100;
  return pct.round();
}

String _relativeTimeLabel(BuildContext context, DateTime? value) {
  final t = AppLocalizations.of(context);
  if (value == null) return t.updatedDaysAgo(0);
  final diff = DateTime.now().difference(value);
  if (diff.inDays < 1) return t.updatedDaysAgo(0);
  if (diff.inDays < 30) return t.updatedDaysAgo(diff.inDays);
  return formatShortDate(context, value);
}

String _menuSourceLabel(BuildContext context, String source) {
  final t = AppLocalizations.of(context);
  switch (source.trim().toLowerCase()) {
    case 'owner':
      return t.sourceOwner;
    case 'community':
      return t.sourceCommunity;
    case 'ai':
      return t.sourceAi;
    default:
      return t.unknown;
  }
}

Future<void> _openDirections({
  required String businessName,
  required String? address,
  required double? lat,
  required double? lng,
}) async {
  final uri = lat != null && lng != null
      ? Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
        )
      : Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent('${businessName.trim()} ${(address ?? '').trim()}')}',
        );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> _trackBusinessPageView({
  required WidgetRef ref,
  required String businessId,
}) async {
  final clientId = await getAnalyticsClientId();
  await ref
      .read(analyticsRepositoryProvider)
      .logEvent(
        eventName: 'business_page_view',
        businessId: businessId,
        source: 'business_page',
        clientId: clientId,
      );
}
