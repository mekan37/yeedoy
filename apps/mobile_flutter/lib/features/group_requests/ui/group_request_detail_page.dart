import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../discovery/data/search_repository.dart';
import '../data/group_requests_repository.dart';
import '../domain/group_request_models.dart';
import '../../discovery/domain/business_card.dart';
import '../../../features/shared/ui/design_system.dart';

class GroupRequestDetailPage extends ConsumerStatefulWidget {
  const GroupRequestDetailPage({super.key, required this.requestId});
  final String requestId;

  @override
  ConsumerState<GroupRequestDetailPage> createState() =>
      _GroupRequestDetailPageState();
}

class _GroupRequestDetailPageState
    extends ConsumerState<GroupRequestDetailPage> {
  bool _accepting = false;

  String get _shareUrl =>
      '${AppConfig.webBaseUrl}/group-requests/${widget.requestId}';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final created =
        GoRouterState.of(context).uri.queryParameters['created'] == '1';
    final repo = ref.watch(groupRequestsRepositoryProvider);
    final shareUrl = _shareUrl;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.groupRequestDetailTitle),
        actions: [
          IconButton(
            tooltip: t.share,
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: shareUrl));
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(content: Text(t.groupRequestLinkCopied)),
              );
            },
            icon: const Icon(Icons.link),
          ),
          IconButton(
            tooltip: t.yenile,
            onPressed: () => _reloadRequestAndOffers(force: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<GroupRequest?>(
        future: _loadRequest(repo, widget.requestId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, _) => const AppSkeletonCard(),
            );
          }
          if (snapshot.hasError) {
            return _errorState(context, snapshot.error);
          }
          final request = snapshot.data;
          if (request == null) {
            return Center(child: Text(t.groupRequestNotFound));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (created)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.groupRequestCreatedBannerTitle,
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t.groupRequestCreatedBannerDescription,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.groupRequestLinkTitle,
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      shareUrl,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await Clipboard.setData(
                            ClipboardData(text: shareUrl),
                          );
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text(t.groupRequestLinkCopied)),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: Text(t.groupRequestCopyAction),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.groupRequestAddSuggestionTitle,
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.groupRequestAddSuggestionDescription,
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: request.status == 'open'
                            ? () => _openSuggestSheet(context, request)
                            : null,
                        child: Text(t.groupRequestAddSuggestionAction),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${request.city} • ${_formatDateTime(request.dateTime)}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.groupRequestPartyAndBudget(
                        request.partySize,
                        _formatPrice(request.budgetTotalCents),
                      ),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    if ((request.notes ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(request.notes!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t.groupRequestOffersTitle,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ref
                  .watch(_offersProvider(widget.requestId))
                  .when(
                    loading: () => Column(
                      children: [
                        const AppSkeletonCard(),
                        const SizedBox(height: 10),
                        const AppSkeletonCard(),
                      ],
                    ),
                    error: (e, _) => _errorState(context, e),
                    data: (offers) {
                      if (offers.isEmpty) {
                        return AppEmptyState(
                          icon: Icons.inbox_outlined,
                          title: t.groupRequestNoOffersTitle,
                          description: t.groupRequestNoOffersDescription,
                        );
                      }
                      final topOfferId = _topOfferId(offers);
                      return Column(
                        children: [
                          for (final offer in offers) ...[
                            _OfferCard(
                              offer: offer.offer,
                              businessName: offer.businessName,
                              onAccept: request.status == 'open'
                                  ? () => _acceptOffer(offer.offer)
                                  : null,
                              accepting: _accepting,
                              votes: offer.offer.votesCount,
                              isTopContributor: offer.offer.id == topOfferId,
                              onVote: () => _vote(offer.offer),
                              canVote: request.status == 'open',
                              myVote: offer.offer.myVote,
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      );
                    },
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _errorState(BuildContext context, Object? error) {
    final t = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppEmptyState(
          icon: Icons.error_outline,
          title: t.sectionLoadFailed,
          description: AppErrorMapper.message(error),
          ctaLabel: t.retry,
          onCta: () => _reloadRequestAndOffers(force: true),
        ),
      ],
    );
  }

  void _reloadRequestAndOffers({required bool force}) {
    if (force) {
      ref.read(groupRequestsRepositoryProvider).invalidateRequest(widget.requestId);
    }
    ref.invalidate(_offersProvider(widget.requestId));
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _acceptOffer(GroupOffer offer) async {
    if (_accepting) return;
    setState(() => _accepting = true);
    try {
      await ref
          .read(groupRequestsRepositoryProvider)
          .acceptGroupOffer(offer.id);
      if (!mounted) return;
      await _showAcceptedSuccess(context, offer, _shareUrl);
      _reloadRequestAndOffers(force: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  Future<void> _vote(GroupOffer offer) async {
    try {
      await ref.read(groupRequestsRepositoryProvider).voteGroupOffer(
        offer.id,
        voted: offer.myVote != 1,
      );
      _reloadRequestAndOffers(force: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  String? _topOfferId(List<_OfferItem> offers) {
    if (offers.isEmpty) return null;
    String? bestId;
    var bestVotes = 0;
    for (final offer in offers) {
      if (offer.offer.votesCount > bestVotes) {
        bestVotes = offer.offer.votesCount;
        bestId = offer.offer.id;
      }
    }
    return bestVotes > 0 ? bestId : null;
  }

  void _openSuggestSheet(BuildContext context, GroupRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SuggestBusinessSheet(request: request),
    );
  }
}

Future<GroupRequest?> _loadRequest(
  GroupRequestsRepository repo,
  String id,
) async {
  final list = await repo.listMyRequests();
  try {
    return list.firstWhere((r) => r.id == id);
  } catch (_) {
    return null;
  }
}

class _OfferItem {
  const _OfferItem({required this.offer, required this.businessName});
  final GroupOffer offer;
  final String businessName;
}

final _offersProvider = FutureProvider.family<List<_OfferItem>, String>((
  ref,
  requestId,
) async {
  final repo = ref.read(groupRequestsRepositoryProvider);
  final offers = await repo.listOffersForRequest(requestId);
  if (offers.isEmpty) return const [];
  final ids = offers.map((e) => e.businessId).toSet().toList();
  final names = await repo.fetchBusinessNames(ids);
  return [
    for (final offer in offers)
      _OfferItem(offer: offer, businessName: names[offer.businessId] ?? ''),
  ];
});

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.businessName,
    required this.onAccept,
    required this.accepting,
    required this.votes,
    required this.isTopContributor,
    required this.onVote,
    required this.canVote,
    required this.myVote,
  });

  final GroupOffer offer;
  final String businessName;
  final VoidCallback? onAccept;
  final bool accepting;
  final int votes;
  final bool isTopContributor;
  final VoidCallback onVote;
  final bool canVote;
  final int? myVote;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  businessName.isEmpty
                      ? t.groupRequestBusinessFallback
                      : businessName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (isTopContributor) _Badge(t.groupRequestTopContributorBadge),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            t.groupRequestOfferPriceLabel(
              _formatPrice(offer.offeredTotalCents),
            ),
            style: const TextStyle(color: AppColors.muted),
          ),
          if ((offer.message ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(offer.message!),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _VotePill(votes: votes),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: canVote ? onVote : null,
                child: Text(
                  myVote == 1
                      ? t.groupRequestUndoVoteAction
                      : t.groupRequestVoteAction,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: onAccept == null || accepting ? null : onAccept,
                child: accepting
                    ? Text(t.groupRequestProcessing)
                    : Text(t.groupRequestAcceptOfferAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textStrong,
        ),
      ),
    );
  }
}

class _VotePill extends StatelessWidget {
  const _VotePill({required this.votes});

  final int votes;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        t.groupRequestVotesLabel(votes),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SuggestBusinessSheet extends ConsumerStatefulWidget {
  const _SuggestBusinessSheet({required this.request});

  final GroupRequest request;

  @override
  ConsumerState<_SuggestBusinessSheet> createState() =>
      _SuggestBusinessSheetState();
}

class _SuggestBusinessSheetState extends ConsumerState<_SuggestBusinessSheet> {
  final _queryCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _searching = false;
  Object? _error;
  List<BusinessCardModel> _results = const [];
  BusinessCardModel? _selected;
  bool _submitting = false;

  @override
  void dispose() {
    _queryCtrl.dispose();
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final t = AppLocalizations.of(context);
    final q = _queryCtrl.text.trim();
    if (q.length < 2) {
      setState(() {
        _results = const [];
        _error = t.groupRequestSearchMinChars;
      });
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final repo = ref.read(searchRepositoryProvider);
      final district = widget.request.districts.isEmpty
          ? null
          : widget.request.districts.first;
      final res = await repo.searchBusinesses(
        query: q,
        city: widget.request.city,
        district: district,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _results = res;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _searching = false;
      });
    }
  }

  int? _parsePriceCents() {
    final raw = _priceCtrl.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value <= 0) return null;
    return (value * 100).round();
  }

  Future<void> _submitOffer() async {
    final t = AppLocalizations.of(context);
    final selected = _selected;
    final priceCents = _parsePriceCents();
    if (selected == null || priceCents == null) {
      setState(() => _error = t.groupRequestBusinessAndPriceRequired);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(groupRequestsRepositoryProvider)
          .submitGroupOffer(
            requestId: widget.request.id,
            businessId: selected.id,
            offeredTotalCents: priceCents,
            includes: {'source': 'group'},
            message: _noteCtrl.text.trim().isEmpty
                ? null
                : _noteCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ref
          .read(groupRequestsRepositoryProvider)
          .invalidateRequest(widget.request.id);
      ref.invalidate(_offersProvider(widget.request.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.groupRequestSuggestionAdded)));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final selected = _selected;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.groupRequestAddSuggestionTitle,
              style: context.sectionTitleStyle,
            ),
            const SizedBox(height: 8),
            if (_error != null) ...[
              Text(
                AppErrorMapper.message(_error),
                style: const TextStyle(color: AppColors.danger),
              ),
              const SizedBox(height: 8),
            ],
            if (selected == null) ...[
              TextField(
                controller: _queryCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  labelText: t.groupRequestSearchBusinessLabel,
                  suffixIcon: IconButton(
                    tooltip: t.ara,
                    onPressed: _searching ? null : _search,
                    icon: const Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/suggest'),
                  child: Text(t.groupRequestSuggestIfMissing),
                ),
              ),
              const SizedBox(height: 8),
              if (_searching)
                const Center(child: CircularProgressIndicator())
              else if (_results.isEmpty)
                AppEmptyState(
                  icon: Icons.search_off,
                  title: t.noProductsFound,
                  description: t.groupRequestTryDifferentName,
                )
              else
                SizedBox(
                  height: 320,
                  child: ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final b = _results[index];
                      final subtitleParts = <String>[
                        if ((b.district ?? '').isNotEmpty) b.district!,
                        if ((b.city ?? '').isNotEmpty) b.city!,
                      ];
                      return AppCard(
                        onTap: () => setState(() => _selected = b),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitleParts.isEmpty
                                  ? b.category
                                  : '${b.category} • ${subtitleParts.join(' / ')}',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ] else ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selected.category,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: t.groupRequestOfferTotalPriceLabel,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteCtrl,
                maxLines: 2,
                decoration: InputDecoration(labelText: t.groupRequestNoteLabel),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() => _selected = null),
                    child: Text(t.groupRequestChangeAction),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _submitting ? null : _submitOffer,
                    child: _submitting ? Text(t.submitting) : Text(t.submit),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> _showAcceptedSuccess(
  BuildContext context,
  GroupOffer offer,
  String shareUrl,
) async {
  final t = AppLocalizations.of(context);
  final text = t.groupRequestAcceptedSummary(
    _formatPrice(offer.offeredTotalCents),
  );
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.share,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(text, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: text));
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                      child: Text(t.groupRequestCopyResultAction),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: shareUrl));
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                      child: Text(t.groupRequestLinkTitle),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go('/b/${offer.businessId}');
                  },
                  child: Text(t.businessHeaderDirectionsAction),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _formatPrice(int cents) {
  final value = cents / 100.0;
  final text = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  return 'TL$text';
}

String _formatDateTime(DateTime time) {
  return '${time.day.toString().padLeft(2, '0')}.'
      '${time.month.toString().padLeft(2, '0')}.'
      '${time.year} '
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}

