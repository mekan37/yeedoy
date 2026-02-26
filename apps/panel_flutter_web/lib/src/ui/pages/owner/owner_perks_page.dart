import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/errors/app_error_mapper.dart';
import '../../../../core/security/app_role_providers.dart';
import '../../../features/owner_businesses/domain/owner_business_state.dart';
import '../../../../features/perks/data/perk_repository.dart';
import '../../../../features/perks/domain/perk_models.dart';
import '../../../../features/perks/domain/perk_providers.dart';
import '../../components/app_empty_state.dart';
import '../../components/app_scaffold.dart';

class OwnerPerksPage extends ConsumerStatefulWidget {
  const OwnerPerksPage({super.key});

  @override
  ConsumerState<OwnerPerksPage> createState() => _OwnerPerksPageState();
}

class _OwnerPerksPageState extends ConsumerState<OwnerPerksPage> {
  @override
  Widget build(BuildContext context) {
    final businessId = ref.watch(selectedOwnerBusinessIdProvider);
    if (businessId == null || businessId.isEmpty) {
      return const AppScaffold(
        body: AppEmptyState(
          icon: Icons.storefront_outlined,
          title: 'İşletme seçilmedi',
          description: 'Üst menüden işletme seçerek devam edin.',
        ),
      );
    }

    final canManageAsync = ref.watch(canManageBusinessProvider(businessId));
    final canManage = canManageAsync.when<bool?>(
      loading: () => null,
      error: (_, _) => false,
      data: (value) => value,
    );
    if (canManage == null) {
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!canManage) {
      return const AppScaffold(
        body: AppEmptyState(
          icon: Icons.lock_outline,
          title: 'Bu işletme için yetkiniz yok',
          description: 'Lütfen başka bir işletme seçin.',
        ),
      );
    }

    final perksAsync = ref.watch(ownerPerksProvider(businessId));

    return AppScaffold(
      appBar: AppBar(
        title: const Text('İkram / Kampanya'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(ownerPerksProvider(businessId)),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => _openCreatePerkSheet(context, businessId),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: perksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: AppErrorMapper.message(e),
          onRetry: () => ref.invalidate(ownerPerksProvider(businessId)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              icon: Icons.card_giftcard_outlined,
              title: 'Henüz kampanya yok',
              description: 'Yeni bir kampanya oluşturarak listede görün.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final perk = items[index];
              return _PerkCard(
                item: perk,
                onStatusChange: (status) async {
                  await _setStatus(context, perk.id, status);
                  ref.invalidate(ownerPerksProvider(businessId));
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreatePerkSheet(context, businessId),
        icon: const Icon(Icons.add),
        label: const Text('Yeni kampanya'),
      ),
    );
  }

  Future<void> _setStatus(
    BuildContext context,
    String perkId,
    String status,
  ) async {
    try {
      final res = await ref
          .read(perkRepositoryProvider)
          .setPerkStatus(perkId: perkId, status: status);
      final ok = (res['ok'] as bool?) ?? false;
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('İşlem başarısız')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
      }
    }
  }

  void _openCreatePerkSheet(BuildContext context, String businessId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CreatePerkSheet(
        businessId: businessId,
        onCreated: () => ref.invalidate(ownerPerksProvider(businessId)),
      ),
    );
  }
}

class _PerkCard extends StatelessWidget {
  const _PerkCard({required this.item, required this.onStatusChange});

  final BusinessPerk item;
  final ValueChanged<String> onStatusChange;

  @override
  Widget build(BuildContext context) {
    final dateText = _perkDateLabel(item.startsAt, item.endsAt);
    final statusLabel = _statusLabel(item.status);
    final statusColor = switch (item.status) {
      'active' => AppColors.success,
      'paused' => AppColors.warning,
      _ => AppColors.muted,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if ((item.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.description!,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
            if (dateText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                dateText,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                if (item.status == 'active')
                  OutlinedButton(
                    onPressed: () => onStatusChange('paused'),
                    child: const Text('Duraklat'),
                  ),
                if (item.status == 'paused')
                  OutlinedButton(
                    onPressed: () => onStatusChange('active'),
                    child: const Text('Aktif et'),
                  ),
                if (item.status != 'ended')
                  OutlinedButton(
                    onPressed: () => onStatusChange('ended'),
                    child: const Text('Bitir'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePerkSheet extends ConsumerStatefulWidget {
  const _CreatePerkSheet({required this.businessId, required this.onCreated});

  final String businessId;
  final VoidCallback onCreated;

  @override
  ConsumerState<_CreatePerkSheet> createState() => _CreatePerkSheetState();
}

class _CreatePerkSheetState extends ConsumerState<_CreatePerkSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _startsCtrl = TextEditingController();
  final _endsCtrl = TextEditingController();
  bool _requiresCheckin = true;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _startsCtrl.dispose();
    _endsCtrl.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String text) {
    final value = text.trim();
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yeni kampanya',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Başlık'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Açıklama (opsiyonel)',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _startsCtrl,
            decoration: const InputDecoration(
              labelText: 'Başlangıç (YYYY-MM-DD HH:MM)',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _endsCtrl,
            decoration: const InputDecoration(
              labelText: 'Bitiş (YYYY-MM-DD HH:MM)',
            ),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Konum doğrulaması gerekli'),
            value: _requiresCheckin,
            onChanged: (value) => setState(() => _requiresCheckin = value),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      final title = _titleCtrl.text.trim();
                      if (title.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Başlık zorunlu')),
                        );
                        return;
                      }
                      setState(() => _saving = true);
                      try {
                        final res = await ref
                            .read(perkRepositoryProvider)
                            .createPerk(
                              businessId: widget.businessId,
                              title: title,
                              description: _descCtrl.text.trim().isEmpty
                                  ? null
                                  : _descCtrl.text.trim(),
                              startsAt: _parseDate(_startsCtrl.text),
                              endsAt: _parseDate(_endsCtrl.text),
                              requiresCheckin: _requiresCheckin,
                            );
                        final ok = (res['ok'] as bool?) ?? false;
                        if (!mounted) return;
                        if (ok) {
                          widget.onCreated();
                          navigator.pop();
                          return;
                        }
                        messenger.showSnackBar(
                          const SnackBar(content: Text('İşlem başarısız')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text(AppErrorMapper.message(e))),
                        );
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              child: const Text('Kaydet'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: const TextStyle(color: AppColors.danger)),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(String status) {
  return switch (status) {
    'active' => 'Aktif',
    'paused' => 'Duraklatıldı',
    'ended' => 'Bitti',
    _ => status,
  };
}

String _perkDateLabel(DateTime? start, DateTime? end) {
  if (start == null && end == null) return '';
  final startText = start == null ? '' : _fmtDateShort(start);
  final endText = end == null ? '' : _fmtDateShort(end);
  if (startText.isNotEmpty && endText.isNotEmpty) {
    return 'Geçerli: $startText - $endText';
  }
  if (startText.isNotEmpty) return 'Başlangıç: $startText';
  return 'Bitiş: $endText';
}

String _fmtDateShort(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
