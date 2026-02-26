import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/errors/app_error_mapper.dart';
import '../../../../core/network/supabase_provider.dart';
import '../../../../features/group_requests/domain/group_request_models.dart';

class AdminGroupRequestsPage extends ConsumerWidget {
  const AdminGroupRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(_adminRequestsProvider);
    final offersAsync = ref.watch(_adminOffersProvider);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Talepler', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 10),
          requestsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(
              AppErrorMapper.message(e),
              style: const TextStyle(color: AppColors.danger),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Text('Kayıt yok', style: TextStyle(color: AppColors.muted));
              }
              return Column(
                children: [
                  for (final req in items) ...[
                    _RequestRow(req: req),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const Text('Teklifler', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 10),
          offersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(
              AppErrorMapper.message(e),
              style: const TextStyle(color: AppColors.danger),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Text('Kayıt yok', style: TextStyle(color: AppColors.muted));
              }
              return Column(
                children: [
                  for (final offer in items) ...[
                    _OfferRow(offer: offer),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

final _adminRequestsProvider = FutureProvider<List<GroupRequest>>((ref) async {
  final client = ref.read(supabaseProvider);
  final res = await client
      .from('group_requests')
      .select()
      .order('created_at', ascending: false)
      .limit(50);
  final rows = (res as List?) ?? const [];
  return rows
      .whereType<Map>()
      .map((row) => GroupRequest.fromMap(row.cast<String, dynamic>()))
      .toList();
});

final _adminOffersProvider = FutureProvider<List<GroupOffer>>((ref) async {
  final client = ref.read(supabaseProvider);
  final res = await client
      .from('group_offers')
      .select()
      .order('created_at', ascending: false)
      .limit(50);
  final rows = (res as List?) ?? const [];
  return rows
      .whereType<Map>()
      .map((row) => GroupOffer.fromMap(row.cast<String, dynamic>()))
      .toList();
});

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.req});
  final GroupRequest req;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${req.city} • ${req.partySize} kişi',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(req.status, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _OfferRow extends StatelessWidget {
  const _OfferRow({required this.offer});
  final GroupOffer offer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              offer.businessId,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            offer.status,
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

