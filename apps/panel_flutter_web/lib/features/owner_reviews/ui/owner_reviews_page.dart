import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../shared/ui/components/owner_business_guard.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../../owner_onboarding/domain/owner_onboarding_providers.dart';
import '../domain/owner_review_models.dart';
import '../domain/owner_reviews_controller.dart';

class OwnerReviewsPage extends ConsumerStatefulWidget {
  const OwnerReviewsPage({super.key, required this.businessId});
  final String businessId;

  @override
  ConsumerState<OwnerReviewsPage> createState() => _OwnerReviewsPageState();
}

class _OwnerReviewsPageState extends ConsumerState<OwnerReviewsPage> {
  final _scrollCtrl = ScrollController();
  bool _redirecting = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 300) {
        ref
            .read(ownerReviewsControllerProvider(widget.businessId).notifier)
            .loadMore();
      }
    });
    ref.listenManual(ownerOnboardingProgressProvider(widget.businessId),
        (previous, next) {
      final bypass =
          GoRouterState.of(context).uri.queryParameters['onboarding'] == '1';
      if (bypass || _redirecting || !mounted) return;
      next.whenData((progress) {
        if (_redirecting || progress.stepCompleted >= 5 || !mounted) return;
        _redirecting = true;
        final redirect = Uri.encodeComponent(
          GoRouterState.of(context).uri.toString(),
        );
        context.go(
          '/owner/onboarding?businessId=${widget.businessId}&redirect=$redirect',
        );
      });
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return OwnerBusinessGuard(
      businessId: widget.businessId,
      builder: (context, ref) {
        final st =
            ref.watch(ownerReviewsControllerProvider(widget.businessId));
        final ctrl = ref.read(
            ownerReviewsControllerProvider(widget.businessId).notifier);

        return Column(
          children: [
            PanelPageHeader(
              eyebrow: l10n.ownerShellPanelTitle,
              title: Text(l10n.ownerReviewsTitle),
              description: l10n.ownerReviewsDescription,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: ctrl.refresh,
                child: ListView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    // Sort selector
                    Row(
                      children: [
                        SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                              value: 'newest',
                              label: Text(l10n.sortNewest),
                            ),
                            ButtonSegment(
                              value: 'helpful',
                              label: Text(l10n.sortMostHelpful),
                            ),
                          ],
                          selected: {st.sort},
                          onSelectionChanged: (s) => ctrl.setSort(s.first),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Error
                    if (st.error != null)
                      _ErrorRow(
                        error: st.error,
                        onRetry: ctrl.refresh,
                      ),
                    // Loading
                    if (st.isLoading && st.items.isEmpty)
                      const _ReviewsSkeleton(),
                    // Empty
                    if (!st.isLoading && st.items.isEmpty && st.error == null)
                      _EmptyReviews(l10n: l10n),
                    // List
                    for (final review in st.items) ...[
                      _OwnerReviewCard(
                        review: review,
                        businessId: widget.businessId,
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (st.isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Review card with inline reply editor
// ---------------------------------------------------------------------------

class _OwnerReviewCard extends ConsumerStatefulWidget {
  const _OwnerReviewCard({
    required this.review,
    required this.businessId,
  });

  final OwnerReviewItem review;
  final String businessId;

  @override
  ConsumerState<_OwnerReviewCard> createState() => _OwnerReviewCardState();
}

class _OwnerReviewCardState extends ConsumerState<_OwnerReviewCard> {
  bool _editing = false;
  late final TextEditingController _textCtrl;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.review.replyContent ?? '');
  }

  @override
  void didUpdateWidget(_OwnerReviewCard old) {
    super.didUpdateWidget(old);
    if (old.review.replyContent != widget.review.replyContent && !_editing) {
      _textCtrl.text = widget.review.replyContent ?? '';
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveReply() async {
    final text = _textCtrl.text.trim();
    if (text.length < 10) return;
    setState(() => _saving = true);
    final ctrl = ref
        .read(ownerReviewsControllerProvider(widget.businessId).notifier);
    final err = await ctrl.submitReply(
      reviewId: widget.review.id,
      content: text,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (err == null) _editing = false;
    });
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ?? l10n.ownerReviewsReplySaved),
    ));
  }

  Future<void> _deleteReply() async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.ownerReviewsDeleteReplyButton),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.ownerReviewsReplyCancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(l10n.ownerReviewsDeleteReplyButton),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _deleting = true);
    final ctrl = ref
        .read(ownerReviewsControllerProvider(widget.businessId).notifier);
    final err = await ctrl.deleteReply(reviewId: widget.review.id);
    if (!mounted) return;
    setState(() => _deleting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ?? l10n.ownerReviewsReplyDeleted),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final review = widget.review;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: stars + date
            Row(
              children: [
                _Stars(rating: review.rating),
                const Spacer(),
                Text(
                  _fmtDate(review.createdAt),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                _StatusBadge(status: review.status),
              ],
            ),
            if ((review.title ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.title!,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              review.content,
              style: const TextStyle(color: AppColors.slate),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.helpfulCount(review.helpfulCount),
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            // Reply section
            if (_editing) ...[
              _ReplyEditor(
                controller: _textCtrl,
                hint: l10n.ownerReviewsReplyHint,
                saving: _saving,
                onSave: _saveReply,
                onCancel: () => setState(() {
                  _editing = false;
                  _textCtrl.text = review.replyContent ?? '';
                }),
                saveLabel: l10n.ownerReviewsReplySaveButton,
                cancelLabel: l10n.ownerReviewsReplyCancelButton,
              ),
            ] else if (review.hasReply) ...[
              _ExistingReply(
                content: review.replyContent!,
                replyAt: review.replyAt,
                ownerReplyLabel: l10n.ownerReviewsOwnerReplyLabel,
                onEdit: () => setState(() {
                  _editing = true;
                  _textCtrl.text = review.replyContent!;
                }),
                onDelete: _deleting ? null : _deleteReply,
                editLabel: l10n.ownerReviewsEditReplyButton,
                deleteLabel: l10n.ownerReviewsDeleteReplyButton,
              ),
            ] else ...[
              TextButton.icon(
                onPressed: () => setState(() => _editing = true),
                icon: const Icon(Icons.reply_rounded, size: 16),
                label: Text(l10n.ownerReviewsReplyButton),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReplyEditor extends StatelessWidget {
  const _ReplyEditor({
    required this.controller,
    required this.hint,
    required this.saving,
    required this.onSave,
    required this.onCancel,
    required this.saveLabel,
    required this.cancelLabel,
  });

  final TextEditingController controller;
  final String hint;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final String saveLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 8,
          maxLength: 2000,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: saving ? null : onCancel,
              child: Text(cancelLabel),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: saving ? null : onSave,
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(saveLabel),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExistingReply extends StatelessWidget {
  const _ExistingReply({
    required this.content,
    required this.replyAt,
    required this.ownerReplyLabel,
    required this.onEdit,
    required this.onDelete,
    required this.editLabel,
    required this.deleteLabel,
  });

  final String content;
  final DateTime? replyAt;
  final String ownerReplyLabel;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final String editLabel;
  final String deleteLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_rounded,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                ownerReplyLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
              if (replyAt != null) ...[
                const SizedBox(width: 8),
                Text(
                  _fmtDate(replyAt!),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
              const Spacer(),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(editLabel,
                    style: const TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.danger,
                ),
                child: Text(deleteLabel,
                    style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});
  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => Icon(
        i < rating ? Icons.star_rounded : Icons.star_border_rounded,
        size: 16,
        color: i < rating ? AppColors.star : AppColors.border,
      )),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    if (status == 'approved') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: const TextStyle(fontSize: 10, color: AppColors.warning),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppErrorMapper.message(error),
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

class _ReviewsSkeleton extends StatelessWidget {
  const _ReviewsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 10, color: AppColors.card),
                  const SizedBox(height: 8),
                  Container(height: 10, width: 200, color: AppColors.card),
                  const SizedBox(height: 8),
                  Container(height: 10, width: 140, color: AppColors.card),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Text(
          l10n.ownerReviewsEmpty,
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
    );
  }
}

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
