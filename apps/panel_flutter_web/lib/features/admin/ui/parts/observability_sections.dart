part of '../admin_observability_page.dart';

// ─── Request Trace Card ──────────────────────────────────────────────────────

class _RequestTraceCard extends StatelessWidget {
  const _RequestTraceCard({
    required this.requestId,
    required this.headers,
    required this.payload,
    required this.onGenerate,
  });

  final String requestId;
  final Map<String, Object?> headers;
  final Map<String, Object?> payload;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.adminObservabilityRequestTraceTitle,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          SelectableText(
            l10n.adminObservabilityRequestIdValue(requestId),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          SelectableText(
            l10n.adminObservabilityHeadersValue(jsonEncode(headers)),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          SelectableText(
            l10n.adminObservabilityPayloadValue(jsonEncode(payload)),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.vpn_key_outlined),
            label: Text(l10n.adminObservabilityGenerateRequestId),
          ),
        ],
      ),
    );
  }
}

// ─── Prefs Explorer Card ─────────────────────────────────────────────────────

class _PrefsExplorerCard extends StatelessWidget {
  const _PrefsExplorerCard({required this.future});

  final Future<_PrefsSnapshot> future;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      child: FutureBuilder<_PrefsSnapshot>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Text(
              l10n.adminObservabilityPrefsReadError('${snap.error}'),
              style: const TextStyle(color: AppColors.danger),
            );
          }
          final data = snap.data;
          if (data == null) {
            return Text(l10n.adminObservabilityPrefsEmpty);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.adminObservabilityPrefsExplorerTitle,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              SelectableText(
                jsonEncode({
                  'feature_flags': data.featureFlags,
                  'dev_overrides': {
                    'test_user_id': data.testUserId,
                    'test_city': data.testCity,
                    'test_district': data.testDistrict,
                  },
                  'product_guardrails': data.guardrails,
                  'offline_cache': {
                    'favorite_ids_count': data.favoriteIdsCount,
                    'recent_businesses_count': data.recentBusinessesCount,
                    'categories_count': data.categoriesCount,
                    'favorite_cached_at': data.favoriteCachedAt
                        ?.toIso8601String(),
                  },
                }),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }
}
