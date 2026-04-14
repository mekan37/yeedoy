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
  final t = AppLocalizations.of(context);
  final deep = AppConfig.businessDeepLink(business.id);
  final web = AppConfig.businessWebUrl(business.id);
  final msg = t.shareBusinessMessage(
    business.name,
    _locText(context, business.district, business.city),
    web,
    deep,
  );
  await SharePlus.instance.share(ShareParams(text: msg));
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

String _heroImageForCategory(String category) {
  final c = category.toLowerCase();
  if (c.contains('steak') || c.contains('et')) {
    return 'assets/images/categories/kebap.png';
  }
  if (c.contains('burger')) {
    return 'assets/images/categories/burger.png';
  }
  if (c.contains('pizza')) {
    return 'assets/images/categories/pizza.png';
  }
  if (c.contains('kahvalt')) {
    return 'assets/images/categories/kahvalti.png';
  }
  return 'assets/images/categories/doner.png';
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
