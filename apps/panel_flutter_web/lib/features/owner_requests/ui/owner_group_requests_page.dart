import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../auth/domain/auth_providers.dart';
import '../../group_requests/data/group_requests_repository.dart';
import '../../group_requests/domain/group_request_models.dart';
import '../../owner_claims/my_claims_controller.dart';
import '../../../domain/models/owner_claim.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../../../shared/ui/design_system.dart';

class OwnerGroupRequestsPage extends ConsumerStatefulWidget {
  const OwnerGroupRequestsPage({super.key});

  @override
  ConsumerState<OwnerGroupRequestsPage> createState() =>
      _OwnerGroupRequestsPageState();
}

class _OwnerGroupRequestsPageState
    extends ConsumerState<OwnerGroupRequestsPage> {
  String _selectedBusinessId = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(userProvider);
    if (user == null) {
      final redirect = Uri.encodeComponent(
        GoRouterState.of(context).uri.toString(),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/login?redirect=$redirect');
      });
      return const Center(child: CircularProgressIndicator());
    }

    final claimsAsync = ref.watch(myClaimsProvider);
    final approved = claimsAsync.maybeWhen(
      data: (items) =>
          items.where((c) => c.claim.status == 'approved').toList(),
      orElse: () => const <OwnerClaimItem>[],
    );
    if (_selectedBusinessId.isEmpty && approved.isNotEmpty) {
      _selectedBusinessId = approved.first.claim.businessId;
    }

    final requestsAsync = _selectedBusinessId.isEmpty
        ? const AsyncData(<GroupRequest>[])
        : ref.watch(_openRequestsProvider(_selectedBusinessId));

    final offersAsync = _selectedBusinessId.isEmpty
        ? const AsyncData(<GroupOffer>[])
        : ref.watch(_myOffersProvider(_selectedBusinessId));

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        PanelPageHeader(
          eyebrow: 'Owner',
          title: Text(l10n.ownerGroupRequestsTitle),
          description: 'Gelen grup rezervasyon taleplerini inceleyin ve teklif gönderin.',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          claimsAsync.when(
            loading: () => const _SkeletonBlock(),
            error: (e, _) => _ErrorBox(
              message: AppErrorMapper.message(e),
              onRetry: () => ref.read(myClaimsProvider.notifier).refresh(),
            ),
            data: (items) {
              final approvedItems = items
                  .where((c) => c.claim.status == 'approved')
                  .toList();
              if (approvedItems.isEmpty) {
                return _EmptyBox(message: l10n.ownerApprovedBusinessNotFound);
              }
              return _BusinessSelector(
                items: approvedItems,
                selectedId: _selectedBusinessId,
                onChanged: (id) {
                  setState(() => _selectedBusinessId = id);
                  ref.invalidate(_openRequestsProvider(id));
                  ref.invalidate(_myOffersProvider(id));
                },
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            l10n.ownerGroupRequestsOpenRequests,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          requestsAsync.when(
            loading: () => const _SkeletonBlock(),
            error: (e, _) =>
                _ErrorBox(message: AppErrorMapper.message(e), onRetry: () {}),
            data: (items) {
              if (items.isEmpty) {
                return AppEmptyState(
                  icon: Icons.inbox_outlined,
                  title: l10n.ownerGroupRequestsEmptyTitle,
                  description: l10n.ownerGroupRequestsEmptyDescription,
                );
              }
              return Column(
                children: [
                  for (final req in items) ...[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${req.city} • ${_formatDate(req.dateTime)}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.ownerGroupRequestsPartyBudget(
                              req.partySize,
                              _formatPrice(req.budgetTotalCents),
                            ),
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: () => _openOfferSheet(req),
                              child: Text(
                                l10n.ownerGroupRequestsOfferAction,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            l10n.ownerGroupRequestsMyOffers,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          offersAsync.when(
            loading: () => const _SkeletonBlock(),
            error: (e, _) =>
                _ErrorBox(message: AppErrorMapper.message(e), onRetry: () {}),
            data: (offers) {
              if (offers.isEmpty) {
                return AppEmptyState(
                  icon: Icons.outbox_outlined,
                  title: l10n.ownerGroupRequestsOffersEmptyTitle,
                  description: l10n.ownerGroupRequestsOffersEmptyDescription,
                );
              }
              return Column(
                children: [
                  for (final offer in offers) ...[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatPrice(offer.offeredTotalCents),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.ownerGroupRequestsOfferStatus(
                              _localizedOfferStatus(context, offer.status),
                            ),
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openOfferSheet(GroupRequest req) async {
    final priceCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    final dessert = ValueNotifier<bool>(false);
    final drinks = ValueNotifier<bool>(false);
    final menuFixed = ValueNotifier<bool>(true);

    final res = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.ownerGroupRequestsOfferAction,
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.l10n.ownerGroupRequestsTotalOfferLabel,
                ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<bool>(
                valueListenable: dessert,
                builder: (_, value, _) => CheckboxListTile(
                  value: value,
                  onChanged: (v) => dessert.value = v ?? false,
                  title: Text(context.l10n.ownerGroupRequestsDessertIncluded),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: drinks,
                builder: (_, value, _) => CheckboxListTile(
                  value: value,
                  onChanged: (v) => drinks.value = v ?? false,
                  title: Text(context.l10n.ownerGroupRequestsDrinksIncluded),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: menuFixed,
                builder: (_, value, _) => CheckboxListTile(
                  value: value,
                  onChanged: (v) => menuFixed.value = v ?? false,
                  title: Text(context.l10n.ownerGroupRequestsMenuFixed),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: messageCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: context.l10n.ownerDescriptionOptional,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(context.l10n.submit),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (res != true) return;
    final price = _parseBudget(priceCtrl.text.trim());
    if (price == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(context.l10n.ownerGroupRequestsEnterValidPrice),
          ),
        );
      }
      return;
    }
    try {
      await ref
          .read(groupRequestsRepositoryProvider)
          .submitGroupOffer(
            requestId: req.id,
            businessId: _selectedBusinessId,
            offeredTotalCents: price,
            includes: {
              'dessert': dessert.value,
              'drinks': drinks.value,
              'menu_fixed': menuFixed.value,
            },
            message: messageCtrl.text.trim().isEmpty
                ? null
                : messageCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text(context.l10n.ownerGroupRequestsOfferSent)),
        );
      }
      ref.invalidate(_openRequestsProvider(_selectedBusinessId));
      ref.invalidate(_myOffersProvider(_selectedBusinessId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
      }
    } finally {
      priceCtrl.dispose();
      messageCtrl.dispose();
    }
  }
}

final _openRequestsProvider = FutureProvider.family<List<GroupRequest>, String>(
  (ref, businessId) async {
    final repo = ref.read(groupRequestsRepositoryProvider);
    final city = await repo.fetchBusinessCity(businessId);
    if (city == null || city.isEmpty) return const [];
    return repo.listOpenRequestsForBusiness(
      city: city,
      categories: const [],
      businessId: businessId,
    );
  },
);

final _myOffersProvider = FutureProvider.family<List<GroupOffer>, String>((
  ref,
  businessId,
) async {
  final repo = ref.read(groupRequestsRepositoryProvider);
  return repo.listOffersForBusiness(businessId);
});

class _BusinessSelector extends StatelessWidget {
  const _BusinessSelector({
    required this.items,
    required this.selectedId,
    required this.onChanged,
  });

  final List<OwnerClaimItem> items;
  final String selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '${context.l10n.businessLabel}:',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: selectedId.isEmpty ? null : selectedId,
            items: [
              for (final item in items)
                DropdownMenuItem(
                  value: item.claim.businessId,
                  child: Text(item.businessName),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              onChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (i) => const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: _SkeletonCard(),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 10, color: AppColors.border),
          const SizedBox(height: 6),
          Container(height: 10, width: 160, color: AppColors.border),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(message, style: const TextStyle(color: AppColors.muted)),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(context.l10n.retry),
          ),
        ],
      ),
    );
  }
}

String _formatPrice(int cents) {
  final value = cents / 100.0;
  final text = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  return 'TL $text';
}

String _formatDate(DateTime time) {
  return '${time.day.toString().padLeft(2, '0')}.'
      '${time.month.toString().padLeft(2, '0')}.'
      '${time.year}';
}

int? _parseBudget(String raw) {
  if (raw.isEmpty) return null;
  final normalized = raw.replaceAll(',', '.');
  final value = double.tryParse(normalized);
  if (value == null || value <= 0) return null;
  return (value * 100).round();
}

String _localizedOfferStatus(BuildContext context, String status) {
  switch (status.trim().toLowerCase()) {
    case 'approved':
      return context.l10n.approved;
    case 'rejected':
      return context.l10n.rejected;
    case 'pending':
      return context.l10n.pending;
    default:
      return status;
  }
}
