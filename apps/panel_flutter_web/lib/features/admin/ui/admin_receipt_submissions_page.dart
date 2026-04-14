import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/media/app_network_image.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../../auth/domain/auth_providers.dart';
import '../data/admin_receipt_submissions_repository.dart';
import '../domain/admin_receipt_submission.dart';
import '../../../shared/ui/design_system.dart';

class AdminReceiptSubmissionsPage extends ConsumerStatefulWidget {
  const AdminReceiptSubmissionsPage({super.key});

  @override
  ConsumerState<AdminReceiptSubmissionsPage> createState() =>
      _AdminReceiptSubmissionsPageState();
}

class _AdminReceiptSubmissionsPageState
    extends ConsumerState<AdminReceiptSubmissionsPage> {
  final _queryCtrl = TextEditingController();

  bool _loading = true;
  bool _detailLoading = false;
  Object? _error;
  List<AdminReceiptSubmission> _items = const [];
  List<AdminReceiptSubmissionMatch> _matches = const [];
  List<AdminReceiptBatchOpportunity> _batchOpportunities = const [];
  AdminReceiptSubmissionSummary? _summary;
  String _reviewStatus = 'all';
  bool _onlyUnmatched = false;
  String? _selectedReceiptId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(adminReceiptSubmissionsRepositoryProvider);
      final results = await Future.wait<dynamic>([
        repo.fetchSummary(
          query: _queryCtrl.text,
          reviewStatus: _normalizedReviewStatus,
          onlyUnmatched: _onlyUnmatched,
        ),
        repo.listSubmissions(
          query: _queryCtrl.text,
          reviewStatus: _normalizedReviewStatus,
          onlyUnmatched: _onlyUnmatched,
          limit: 80,
        ),
        repo.listBatchOpportunities(),
      ]);

      final items = results[1] as List<AdminReceiptSubmission>;
      final preservedSelection = items.any((item) => item.id == _selectedReceiptId)
          ? _selectedReceiptId
          : (items.isNotEmpty ? items.first.id : null);

      if (!mounted) return;
      setState(() {
        _summary = results[0] as AdminReceiptSubmissionSummary?;
        _items = items;
        _batchOpportunities = results[2] as List<AdminReceiptBatchOpportunity>;
        _selectedReceiptId = preservedSelection;
      });
      await _loadDetail(_selectedReceiptId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadDetail(String? receiptId) async {
    if (receiptId == null || receiptId.isEmpty) {
      if (mounted) {
        setState(() => _matches = const []);
      }
      return;
    }
    setState(() => _detailLoading = true);
    try {
      final matches = await ref
          .read(adminReceiptSubmissionsRepositoryProvider)
          .listMatches(receiptId: receiptId);
      if (!mounted) return;
      setState(() => _matches = matches);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    } finally {
      if (mounted) setState(() => _detailLoading = false);
    }
  }

  Future<void> _openReviewSheet(AdminReceiptSubmission item) async {
    final l10n = context.l10n;
    final noteCtrl = TextEditingController(text: item.reviewNote ?? '');
    var selectedStatus = item.reviewStatus;
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> save() async {
            setModalState(() => saving = true);
            try {
              await ref
                  .read(adminReceiptSubmissionsRepositoryProvider)
                  .updateReview(
                    receiptId: item.id,
                    reviewStatus: selectedStatus,
                    reviewNote: noteCtrl.text.trim(),
                    reviewedBy: ref.read(userProvider)?.id,
                  );
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              await _load();
              if (!mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                SnackBar(content: Text(l10n.adminReceiptSubmissionsSaved)),
              );
            } catch (e) {
              if (!mounted) return;
              setModalState(() => saving = false);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.adminReceiptSubmissionsReviewSheetTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  items: [
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text(
                        l10n.adminReceiptSubmissionsStatusPending,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'reviewed',
                      child: Text(
                        l10n.adminReceiptSubmissionsStatusReviewed,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'needs_followup',
                      child: Text(
                        l10n.adminReceiptSubmissionsStatusNeedsFollowup,
                      ),
                    ),
                  ],
                  onChanged: (value) => setModalState(
                    () => selectedStatus = value ?? 'pending',
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.adminReceiptSubmissionsReviewStatusLabel,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: l10n.adminReceiptSubmissionsReviewNoteLabel,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving ? null : save,
                    child: Text(
                      saving ? l10n.saving : l10n.adminReceiptSubmissionsSaveReview,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    noteCtrl.dispose();
  }

  AdminReceiptSubmission? get _selectedItem {
    for (final item in _items) {
      if (item.id == _selectedReceiptId) return item;
    }
    return null;
  }

  String? get _normalizedReviewStatus =>
      _reviewStatus == 'all' ? null : _reviewStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelPageHeader(
            padding: EdgeInsets.zero,
            title: Text(l10n.adminReceiptSubmissionsTitle),
            description: l10n.adminReceiptSubmissionsSubtitle,
            actions: [
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                tooltip: l10n.yenile,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFilters(context),
          const SizedBox(height: 12),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                AppErrorMapper.message(_error),
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          const SizedBox(height: 12),
          if (_summary != null) _buildSummary(context),
          if (_summary != null) const SizedBox(height: 12),
          _buildBatchOpportunities(context),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 1080) {
                  return Row(
                    children: [
                      Expanded(flex: 5, child: _buildListPane(context)),
                      const SizedBox(width: 12),
                      Expanded(flex: 6, child: _buildDetailPane(context)),
                    ],
                  );
                }
                return ListView(
                  children: [
                    SizedBox(height: 420, child: _buildListPane(context)),
                    const SizedBox(height: 12),
                    SizedBox(height: 560, child: _buildDetailPane(context)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: _queryCtrl,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              hintText: l10n.adminReceiptSubmissionsSearchHint,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
        ),
        DropdownButton<String>(
          value: _reviewStatus,
          items: [
            DropdownMenuItem(
              value: 'all',
              child: Text(l10n.adminReceiptSubmissionsStatusAll),
            ),
            DropdownMenuItem(
              value: 'pending',
              child: Text(l10n.adminReceiptSubmissionsStatusPending),
            ),
            DropdownMenuItem(
              value: 'needs_followup',
              child: Text(l10n.adminReceiptSubmissionsStatusNeedsFollowup),
            ),
            DropdownMenuItem(
              value: 'reviewed',
              child: Text(l10n.adminReceiptSubmissionsStatusReviewed),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _reviewStatus = value);
            _load();
          },
        ),
        FilterChip(
          selected: _onlyUnmatched,
          label: Text(l10n.adminReceiptSubmissionsOnlyUnmatched),
          onSelected: (selected) {
            setState(() => _onlyUnmatched = selected);
            _load();
          },
        ),
        FilledButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.search),
          label: Text(l10n.adminSponsorshipSearchAction),
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final l10n = context.l10n;
    final summary = _summary!;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MetricCard(
          title: l10n.adminReceiptSubmissionsSummaryTotal,
          value: '${summary.totalCount}',
        ),
        _MetricCard(
          title: l10n.adminReceiptSubmissionsSummaryPending,
          value: '${summary.pendingCount}',
        ),
        _MetricCard(
          title: l10n.adminReceiptSubmissionsSummaryNeedsFollowup,
          value: '${summary.needsFollowupCount}',
        ),
        _MetricCard(
          title: l10n.adminReceiptSubmissionsSummaryZeroMatch,
          value: '${summary.zeroMatchCount}',
        ),
        _MetricCard(
          title: l10n.adminReceiptSubmissionsSummaryRecent24h,
          value: '${summary.recent24hCount}',
        ),
        _MetricCard(
          title: l10n.adminReceiptSubmissionsSummaryBusinesses,
          value: '${summary.businessCount}',
        ),
      ],
    );
  }

  Widget _buildBatchOpportunities(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.adminReceiptSubmissionsBatchTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.adminReceiptSubmissionsBatchDescription,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          if (_batchOpportunities.isEmpty)
            Text(
              l10n.adminReceiptSubmissionsBatchEmpty,
              style: const TextStyle(color: AppColors.muted),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in _batchOpportunities)
                  SizedBox(
                    width: 260,
                    child: OutlinedButton(
                      onPressed: () {
                        _queryCtrl.text = item.businessName;
                        _load();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.businessName,
                              style: const TextStyle(
                                color: AppColors.textStrong,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if ((item.chainName ?? '').isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.chainName!,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              l10n.adminReceiptSubmissionsBatchValue(
                                item.pendingCount,
                                item.zeroMatchCount,
                                _fmtDateTime(item.lastSubmittedAt),
                              ),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildListPane(BuildContext context) {
    final l10n = context.l10n;
    if (!_loading && _items.isEmpty) {
      return AppEmptyState(
        icon: Icons.receipt_long_outlined,
        title: l10n.adminReceiptSubmissionsEmptyTitle,
        description: l10n.adminReceiptSubmissionsEmptyDescription,
      );
    }

    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _items[index];
        final selected = item.id == _selectedReceiptId;
        return AppCard(
          onTap: () {
            setState(() => _selectedReceiptId = item.id);
            _loadDetail(item.id);
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: selected
                  ? Border.all(color: AppColors.info, width: 1.5)
                  : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 88,
                      height: 88,
                      child: item.imageUrl.isEmpty
                          ? const ColoredBox(
                              color: AppColors.card,
                              child: Icon(Icons.receipt_long_outlined),
                            )
                          : AppNetworkImage(
                              url: item.imageUrl,
                              variant: AppImageVariant.thumb,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.businessName.isEmpty
                                    ? l10n.businessLabel
                                    : item.businessName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusPill(
                              label: _reviewStatusLabel(context, item.reviewStatus),
                              color: _reviewStatusColor(item.reviewStatus),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.adminReceiptSubmissionsMatchSummary(
                            item.matchesCount,
                            _fmtDateTime(item.createdAt),
                          ),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _locationSummary(context, item),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        if ((item.reviewNote ?? '').isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            item.reviewNote!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailPane(BuildContext context) {
    final l10n = context.l10n;
    final item = _selectedItem;
    if (item == null) {
      return AppEmptyState(
        icon: Icons.fact_check_outlined,
        title: l10n.adminReceiptSubmissionsDetailEmptyTitle,
        description: l10n.adminReceiptSubmissionsDetailEmptyDescription,
      );
    }

    return AppCard(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.businessName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _locationSummary(context, item),
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusPill(
                  label: _reviewStatusLabel(context, item.reviewStatus),
                  color: _reviewStatusColor(item.reviewStatus),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _openReviewSheet(item),
                  icon: const Icon(Icons.rule_folder_outlined),
                  label: Text(l10n.adminReceiptSubmissionsReviewAction),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/b/${item.businessId}'),
                  icon: const Icon(Icons.open_in_new_outlined),
                  label: Text(l10n.adminReceiptSubmissionsOpenBusinessAction),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(
                    '/admin/businesses?q=${Uri.encodeComponent(item.businessName)}',
                  ),
                  icon: const Icon(Icons.storefront_outlined),
                  label: Text(
                    l10n.adminReceiptSubmissionsOpenBusinessAdminAction,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (item.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AppNetworkImage(
                  url: item.imageUrl,
                  variant: AppImageVariant.medium,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricCard(
                  title: l10n.adminReceiptSubmissionsDetailMatches,
                  value: '${item.matchesCount}',
                ),
                _MetricCard(
                  title: l10n.adminReceiptSubmissionsDetailSubmittedAt,
                  value: _fmtDateTime(item.createdAt),
                ),
                _MetricCard(
                  title: l10n.adminReceiptSubmissionsDetailUser,
                  value: _shortId(item.userId),
                ),
              ],
            ),
            if ((item.reviewNote ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.adminReceiptSubmissionsReviewNoteLabel,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(item.reviewNote!),
            ],
            const SizedBox(height: 16),
            Text(
              l10n.adminReceiptSubmissionsMatchTableTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.adminReceiptSubmissionsMatchTableDescription,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            if (_detailLoading)
              const LinearProgressIndicator(minHeight: 6)
            else if (_matches.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  l10n.adminReceiptSubmissionsNoMatches,
                  style: const TextStyle(color: AppColors.muted),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(
                      label: Text(
                        l10n.adminReceiptSubmissionsMatchItemColumn,
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        l10n.adminReceiptSubmissionsMatchDetectedColumn,
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        l10n.adminReceiptSubmissionsMatchCurrentColumn,
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        l10n.adminReceiptSubmissionsMatchDeltaColumn,
                      ),
                    ),
                  ],
                  rows: [
                    for (final match in _matches)
                      DataRow(
                        cells: [
                          DataCell(Text(match.itemName)),
                          DataCell(Text(_formatMoney(match.detectedPriceCents))),
                          DataCell(Text(_formatMoney(match.currentPriceCents))),
                          DataCell(
                            Text(
                              _formatDelta(match.deltaCents),
                              style: TextStyle(
                                color: match.deltaCents == 0
                                    ? AppColors.muted
                                    : match.deltaCents > 0
                                    ? AppColors.danger
                                    : AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

String _locationSummary(BuildContext context, AdminReceiptSubmission item) {
  final parts = <String>[
    if ((item.chainName ?? '').isNotEmpty) item.chainName!,
    if ((item.city ?? '').isNotEmpty) item.city!,
    if ((item.district ?? '').isNotEmpty) item.district!,
  ];
  if (parts.isEmpty) return context.l10n.adminSuggestionsNoLocation;
  return parts.join(' • ');
}

String _reviewStatusLabel(BuildContext context, String status) {
  final l10n = context.l10n;
  return switch (status) {
    'reviewed' => l10n.adminReceiptSubmissionsStatusReviewed,
    'needs_followup' => l10n.adminReceiptSubmissionsStatusNeedsFollowup,
    _ => l10n.adminReceiptSubmissionsStatusPending,
  };
}

Color _reviewStatusColor(String status) {
  return switch (status) {
    'reviewed' => AppColors.success,
    'needs_followup' => AppColors.warning,
    _ => AppColors.info,
  };
}

String _fmtDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day.$month.${date.year} $hour:$minute';
}

String _shortId(String value) {
  if (value.length <= 8) return value;
  return '${value.substring(0, 8)}...';
}

String _formatMoney(int cents) {
  return '₺${(cents / 100).toStringAsFixed(2)}';
}

String _formatDelta(int cents) {
  final prefix = cents > 0 ? '+' : '';
  return '$prefix${_formatMoney(cents)}';
}
