import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_error_mapper.dart';
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
    return AppCard(
      padding: EdgeInsets.all(tokens.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Riskli Kullanicilar', style: context.subtitleStyle),
              const Spacer(),
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<int>(
                  initialValue: st.minScore,
                  items: const [
                    DropdownMenuItem(value: 15, child: Text('Skor >= 15')),
                    DropdownMenuItem(value: 20, child: Text('Skor >= 20')),
                    DropdownMenuItem(value: 30, child: Text('Skor >= 30')),
                    DropdownMenuItem(value: 40, child: Text('Skor >= 40')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    ref
                        .read(adminRiskControllerProvider.notifier)
                        .setMinScore(v);
                  },
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Filtre',
                  ),
                ),
              ),
              SizedBox(width: tokens.space8),
              AppButton(
                label: 'Yenile',
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
            const AppEmptyState(
              icon: Icons.shield_outlined,
              title: 'Riskli kullanici yok',
              description: 'Bu filtrede su an islem gerektiren kullanici yok.',
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
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Aksiyon Nedeni'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aksiyon: $action'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Reason (zorunlu)',
                hintText: 'Kisa aciklama girin',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Uygula'),
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
    required this.onAction,
  });

  final AdminRiskQueueItem item;
  final bool isBusy;
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
                _scoreChip(item.riskScore),
                const Spacer(),
                IconButton(
                  tooltip: 'Kopyala',
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
                _smallChip('Sinyal: ${item.signalCount}'),
                _smallChip('Yeni hesap: ${item.newAccountHits}'),
                _smallChip('Cihaz degisimi: ${item.deviceChangeHits}'),
                _smallChip('IP burst: ${item.sameIpHits}'),
                _smallChip('Kopya metin: ${item.duplicateTextHits}'),
              ],
            ),
            SizedBox(height: tokens.space8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppButton(
                  label: 'Soft limit 60dk',
                  variant: AppButtonVariant.secondary,
                  onPressed: isBusy ? null : () => onAction('soft_limit', 60),
                ),
                AppButton(
                  label: 'Auto pending 12s',
                  variant: AppButtonVariant.secondary,
                  onPressed: isBusy
                      ? null
                      : () => onAction('auto_pending', 720),
                ),
                AppButton(
                  label: 'Shadow ban 24s',
                  variant: AppButtonVariant.secondary,
                  onPressed: isBusy ? null : () => onAction('shadow_ban', 1440),
                ),
                AppButton(
                  label: 'Temizle',
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

Widget _scoreChip(int score) {
  final tone = score >= 80
      ? AppBadgeTone.danger
      : (score >= 50 ? AppBadgeTone.warning : AppBadgeTone.info);
  return AppBadge(label: 'Skor $score', tone: tone);
}

Widget _smallChip(String text) {
  return AppChip(label: text);
}

String _short(String value) {
  if (value.length <= 10) return value;
  return '${value.substring(0, 10)}...';
}

