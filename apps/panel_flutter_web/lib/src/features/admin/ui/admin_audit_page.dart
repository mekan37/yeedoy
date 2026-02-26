import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_error_mapper.dart';
import '../../../ui/design_system.dart';
import '../domain/admin_audit_controller.dart';
import '../domain/admin_audit_models.dart';
import 'widgets/admin_risk_queue_section.dart';

class AdminAuditPage extends ConsumerStatefulWidget {
  const AdminAuditPage({super.key, this.ownerMode = false});

  final bool ownerMode;

  @override
  ConsumerState<AdminAuditPage> createState() => _AdminAuditPageState();
}

class _AdminAuditPageState extends ConsumerState<AdminAuditPage> {
  final scrollCtrl = ScrollController();
  final targetIdCtrl = TextEditingController();
  String actionFilter = '';
  String targetTypeFilter = '';

  static const actionOptions = [
    '',
    'business.updated',
    'menu.created',
    'menu.updated',
    'menu.deleted',
    'menu_item.created',
    'menu_item.updated',
    'menu_item.deleted',
    'claim.approved',
    'claim.rejected',
    'claim.assigned',
    'claim.updated',
    'report.status_changed',
    'report.assigned',
    'report.handled',
    'report.updated',
    'user.banned',
    'user.unbanned',
  ];

  static const tableOptions = [
    '',
    'business',
    'menu',
    'menu_item',
    'owner_claim',
    'report',
    'user_profile',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(adminAuditControllerProvider.notifier).loadInitial(),
    );
    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >=
          scrollCtrl.position.maxScrollExtent - 300) {
        ref.read(adminAuditControllerProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    scrollCtrl.dispose();
    targetIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(adminAuditControllerProvider);
    final tokens = AppTokens.of(context);

    return Padding(
      padding: tokens.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.ownerMode ? 'İşlem Geçmişi' : 'Denetim Kaydı',
                style: context.titleStyle,
              ),
              SizedBox(width: tokens.space8),
              AppBadge(
                label: '${st.items.length} kayıt',
                tone: AppBadgeTone.info,
              ),
              const Spacer(),
              AppButton(
                label: 'Yenile',
                icon: Icons.refresh,
                variant: AppButtonVariant.secondary,
                onPressed: () =>
                    ref.read(adminAuditControllerProvider.notifier).refresh(),
              ),
            ],
          ),
          tokens.gap12(),
          AppCard(
            child: _FiltersRow(
              actionFilter: actionFilter,
              targetTypeFilter: targetTypeFilter,
              targetIdCtrl: targetIdCtrl,
              actionOptions: actionOptions,
              tableOptions: tableOptions,
              onActionChanged: (v) {
                actionFilter = v ?? '';
                _applyFilters();
              },
              onTargetTypeChanged: (v) {
                targetTypeFilter = v ?? '';
                _applyFilters();
              },
              onApply: _applyFilters,
            ),
          ),
          tokens.gap12(),
          const AdminRiskQueueSection(),
          tokens.gap12(),
          if (st.error != null)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.space8),
              child: Text(
                AppErrorMapper.message(st.error),
                style: context.bodyStyle.copyWith(color: Colors.red),
              ),
            ),
          Expanded(
            child: AppCard(
              padding: EdgeInsets.all(tokens.space12),
              child: _buildContent(context, st, tokens),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AdminAuditState st,
    AppTokens tokens,
  ) {
    if (st.isLoading && st.items.isEmpty) {
      return ListView.separated(
        itemCount: 6,
        separatorBuilder: (context, index) => SizedBox(height: tokens.space8),
        itemBuilder: (context, index) => const AppSkeletonCard(lines: 3),
      );
    }

    if (!st.isLoading && st.items.isEmpty) {
      return AppEmptyState(
        icon: Icons.receipt_long,
        title: 'Kayıt bulunamadı',
        description: 'Filtreleri genişletip tekrar deneyin.',
        ctaLabel: 'Filtreleri temizle',
        onCta: () {
          actionFilter = '';
          targetTypeFilter = '';
          targetIdCtrl.clear();
          _applyFilters();
        },
      );
    }

    return ListView(
      controller: scrollCtrl,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Oluşturulma')),
              DataColumn(label: Text('Aksiyon')),
              DataColumn(label: Text('Hedef Tür')),
              DataColumn(label: Text('Hedef ID')),
              DataColumn(label: Text('Aktör')),
              DataColumn(label: Text('')),
            ],
            rows: [
              for (final item in st.items)
                DataRow(
                  onSelectChanged: (_) => _openDetails(context, item),
                  cells: [
                    DataCell(
                      Text(
                        '${_fmtRelative(item.createdAt)} • ${_fmtDateTime(item.createdAt)}',
                      ),
                    ),
                    DataCell(Text(item.action)),
                    DataCell(Text(item.targetType)),
                    DataCell(_copyCell(item.targetId)),
                    DataCell(
                      Text(
                        item.actorRole.isEmpty
                            ? _short(item.actorId)
                            : '${item.actorRole} • ${_short(item.actorId)}',
                      ),
                    ),
                    DataCell(
                      AppButton(
                        label: 'Detay',
                        variant: AppButtonVariant.ghost,
                        onPressed: () => _openDetails(context, item),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (st.isLoadingMore)
          Padding(
            padding: EdgeInsets.only(top: tokens.space12),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  void _applyFilters() {
    ref
        .read(adminAuditControllerProvider.notifier)
        .setFilters(
          actionFilter: actionFilter,
          targetTypeFilter: targetTypeFilter,
          targetId: targetIdCtrl.text.trim(),
        );
    ref.read(adminAuditControllerProvider.notifier).loadInitial();
  }

  Widget _copyCell(String value) {
    return Row(
      children: [
        Text(_short(value)),
        IconButton(
          icon: const Icon(Icons.copy, size: 16),
          tooltip: 'Kopyala',
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Kopyalandı.')));
          },
        ),
      ],
    );
  }

  Future<void> _openDetails(
    BuildContext context,
    AdminAuditLogItem item,
  ) async {
    final pretty = _prettyJson(item.meta);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Denetim Detayı', style: ctx.subtitleStyle),
              const SizedBox(height: 10),
              Text('Oluşturulma: ${_fmtDateTime(item.createdAt)}'),
              Text('Aksiyon: ${item.action}'),
              Text('Hedef Tür: ${item.targetType}'),
              Text('Hedef ID: ${item.targetId}'),
              Text('Aktör ID: ${item.actorId}'),
              Text('Aktör Rolü: ${item.actorRole}'),
              if ((item.ip ?? '').isNotEmpty) Text('IP: ${item.ip}'),
              if ((item.userAgent ?? '').isNotEmpty)
                Text('User-Agent: ${item.userAgent}'),
              const SizedBox(height: 12),
              Text('Önce / Sonra', style: ctx.subtitleStyle),
              const SizedBox(height: 6),
              AppCard(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _prettyJson({
                    'before': item.beforeData,
                    'after': item.afterData,
                  }),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Text('Meta', style: ctx.subtitleStyle),
              const SizedBox(height: 6),
              AppCard(
                padding: const EdgeInsets.all(12),
                child: Text(
                  pretty,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FiltersRow extends StatelessWidget {
  const _FiltersRow({
    required this.actionFilter,
    required this.targetTypeFilter,
    required this.targetIdCtrl,
    required this.actionOptions,
    required this.tableOptions,
    required this.onActionChanged,
    required this.onTargetTypeChanged,
    required this.onApply,
  });

  final String actionFilter;
  final String targetTypeFilter;
  final TextEditingController targetIdCtrl;
  final List<String> actionOptions;
  final List<String> tableOptions;
  final ValueChanged<String?> onActionChanged;
  final ValueChanged<String?> onTargetTypeChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Wrap(
      spacing: tokens.space12,
      runSpacing: tokens.space12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String?>(
            key: ValueKey('action-$actionFilter'),
            initialValue: actionFilter.isEmpty ? null : actionFilter,
            items: actionOptions
                .map(
                  (a) => DropdownMenuItem<String?>(
                    value: a.isEmpty ? null : a,
                    child: Text(a.isEmpty ? 'Aksiyon (tümü)' : a),
                  ),
                )
                .toList(),
            onChanged: onActionChanged,
            decoration: const InputDecoration(labelText: 'Aksiyon'),
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String?>(
            key: ValueKey('target-$targetTypeFilter'),
            initialValue: targetTypeFilter.isEmpty ? null : targetTypeFilter,
            items: tableOptions
                .map(
                  (t) => DropdownMenuItem<String?>(
                    value: t.isEmpty ? null : t,
                    child: Text(t.isEmpty ? 'Tablo (tümü)' : t),
                  ),
                )
                .toList(),
            onChanged: onTargetTypeChanged,
            decoration: const InputDecoration(labelText: 'Hedef Tür'),
          ),
        ),
        SizedBox(
          width: 320,
          child: TextField(
            controller: targetIdCtrl,
            onSubmitted: (_) => onApply(),
            decoration: const InputDecoration(
              labelText: 'Hedef ID',
              suffixIcon: Icon(Icons.search),
            ),
          ),
        ),
        AppButton(
          label: 'Uygula',
          variant: AppButtonVariant.secondary,
          onPressed: onApply,
        ),
      ],
    );
  }
}

String _short(String id) => id.length > 8 ? '${id.substring(0, 8)}...' : id;

String _fmtDateTime(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '$y-$m-$day $hh:$mm';
}

String _fmtRelative(DateTime d) {
  final now = DateTime.now();
  final diff = now.difference(d);
  if (diff.inMinutes < 1) return 'Şimdi';
  if (diff.inMinutes < 60) return '${diff.inMinutes} dk';
  if (diff.inHours < 24) return '${diff.inHours} sa';
  if (diff.inDays < 7) return '${diff.inDays} gün';
  final weeks = (diff.inDays / 7).floor();
  if (weeks < 5) return '$weeks hf';
  final months = (diff.inDays / 30).floor();
  return '$months ay';
}

String _prettyJson(Object? meta) {
  if (meta == null) return '{}';
  try {
    return const JsonEncoder.withIndent('  ').convert(meta);
  } catch (_) {
    return meta.toString();
  }
}

