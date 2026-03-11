import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_error_mapper.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../shared/ui/design_system.dart';
import '../../domain/admin_risk_controller.dart';
import '../../domain/admin_risk_models.dart';

class AdminRiskQueueSection extends ConsumerStatefulWidget {
  const AdminRiskQueueSection({super.key});

  @override
  ConsumerState<AdminRiskQueueSection> createState() =>
      _AdminRiskQueueSectionState();
}

class _AdminRiskQueueSectionState extends ConsumerState<AdminRiskQueueSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(adminRiskControllerProvider.notifier).loadInitial(),
    );
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 260) {
        ref.read(adminRiskControllerProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(adminRiskControllerProvider);
    final tokens = AppTokens.of(context);
    final l10n = context.l10n;
    return AppCard(
      padding: EdgeInsets.all(tokens.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l10n.adminRiskQueueTitle, style: context.subtitleStyle),
              const Spacer(),
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<int>(
                  initialValue: st.minScore,
                  items: [
                    DropdownMenuItem(
                      value: 15,
                      child: Text(l10n.adminRiskQueueScoreThreshold(15)),
                    ),
                    DropdownMenuItem(
                      value: 20,
                      child: Text(l10n.adminRiskQueueScoreThreshold(20)),
                    ),
                    DropdownMenuItem(
                      value: 30,
                      child: Text(l10n.adminRiskQueueScoreThreshold(30)),
                    ),
                    DropdownMenuItem(
                      value: 40,
                      child: Text(l10n.adminRiskQueueScoreThreshold(40)),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    ref
                        .read(adminRiskControllerProvider.notifier)
                        .setMinScore(v);
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: l10n.adminRiskQueueFilterLabel,
                  ),
                ),
              ),
              SizedBox(width: tokens.space8),
              AppButton(
                label: l10n.yenile,
                icon: Icons.refresh,
                variant: AppButtonVariant.ghost,
                onPressed: () =>
                    ref.read(adminRiskControllerProvider.notifier).refresh(),
              ),
            ],
          ),
          SizedBox(height: tokens.space8),
          if (st.error != null)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.space8),
              child: Text(
                AppErrorMapper.message(st.error),
                style: context.bodyStyle.copyWith(color: Colors.red),
              ),
            ),
          if (st.loading && st.items.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.space16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (st.items.isEmpty)
            AppEmptyState(
              icon: Icons.shield_outlined,
              title: l10n.adminRiskQueueEmptyTitle,
              description: l10n.adminRiskQueueEmptyDescription,
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: st.items.length + (st.loadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= st.items.length) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final item = st.items[index];
                  final isBusy = st.busyUserId == item.userId;
                  return _RiskRow(
                    item: item,
                    isBusy: isBusy,
                    l10n: l10n,
                    onAction: (action, minutes) async {
                      final reason = await _askReason(context, action);
                      if (reason == null || reason.trim().isEmpty) return;
                      if (!mounted) return;
                      await ref
                          .read(adminRiskControllerProvider.notifier)
                          .applyAction(
                            userId: item.userId,
                            action: action,
                            minutes: minutes,
                            reason: reason.trim(),
                          );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

Future<String?> _askReason(BuildContext context, String action) async {
  final l10n = context.l10n;
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(l10n.adminRiskQueueReasonDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.adminRiskQueueActionWithName(action)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.adminRiskQueueReasonLabel,
                hintText: l10n.adminRiskQueueReasonHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l10n.apply),
          ),
        ],
      );
    },
  );
  controller.dispose();
  return result;
}

class _RiskRow extends StatelessWidget {
  const _RiskRow({
    required this.item,
    required this.isBusy,
    required this.l10n,
    required this.onAction,
  });

  final AdminRiskQueueItem item;
  final bool isBusy;
  final AppLocalizations l10n;
  final Future<void> Function(String action, int minutes) onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.space8),
      child: AppCard(
        padding: EdgeInsets.all(tokens.space12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _short(item.userId),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 6),
                _scoreChip(l10n, item.riskScore),
                const Spacer(),
                IconButton(
                  tooltip: l10n.adminRiskQueueCopyUserId,
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: item.userId)),
                  icon: const Icon(Icons.copy, size: 16),
                ),
              ],
            ),
            SizedBox(height: tokens.space8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _smallChip(l10n.adminRiskQueueSignalCount(item.signalCount)),
                _smallChip(
                  l10n.adminRiskQueueNewAccountHits(item.newAccountHits),
                ),
                _smallChip(
                  l10n.adminRiskQueueDeviceChangeHits(item.deviceChangeHits),
                ),
                _smallChip(l10n.adminRiskQueueSameIpHits(item.sameIpHits)),
                _smallChip(
                  l10n.adminRiskQueueDuplicateTextHits(
                    item.duplicateTextHits,
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.space8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppButton(
                  label: l10n.adminRiskQueueSoftLimitAction(60),
                  variant: AppButtonVariant.secondary,
                  onPressed: isBusy ? null : () => onAction('soft_limit', 60),
                ),
                AppButton(
                  label: l10n.adminRiskQueueAutoPendingAction(12),
                  variant: AppButtonVariant.secondary,
                  onPressed: isBusy
                      ? null
                      : () => onAction('auto_pending', 720),
                ),
                AppButton(
                  label: l10n.adminRiskQueueShadowBanAction(24),
                  variant: AppButtonVariant.secondary,
                  onPressed: isBusy ? null : () => onAction('shadow_ban', 1440),
                ),
                AppButton(
                  label: l10n.adminRiskQueueClearAction,
                  variant: AppButtonVariant.ghost,
                  onPressed: isBusy ? null : () => onAction('clear', 1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _scoreChip(AppLocalizations l10n, int score) {
  final tone = score >= 80
      ? AppBadgeTone.danger
      : (score >= 50 ? AppBadgeTone.warning : AppBadgeTone.info);
  return AppBadge(label: l10n.adminRiskQueueScoreLabel(score), tone: tone);
}

Widget _smallChip(String text) {
  return AppChip(label: text);
}

String _short(String value) {
  if (value.length <= 10) return value;
  return '${value.substring(0, 10)}...';
}

