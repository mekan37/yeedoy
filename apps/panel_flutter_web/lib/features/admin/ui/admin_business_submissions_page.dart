import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../data/admin_business_submissions_repository.dart';
import '../domain/admin_business_submission.dart';

class AdminBusinessSubmissionsPage extends ConsumerStatefulWidget {
  const AdminBusinessSubmissionsPage({super.key});

  @override
  ConsumerState<AdminBusinessSubmissionsPage> createState() =>
      _AdminBusinessSubmissionsPageState();
}

class _AdminBusinessSubmissionsPageState
    extends ConsumerState<AdminBusinessSubmissionsPage> {
  String? _statusFilter;
  bool _loading = true;
  Object? _error;
  List<AdminBusinessSubmission> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(adminBusinessSubmissionsRepositoryProvider);
      final res = await repo.listSubmissions(status: _statusFilter);
      if (!mounted) return;
      setState(() {
        _items = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppErrorMapper.message(_error),
              style: const TextStyle(color: AppColors.danger),
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _load, child: const Text('Tekrar dene')),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Durum:',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _statusFilter ?? '',
                items: const [
                  DropdownMenuItem(value: '', child: Text('T?m?')),
                  DropdownMenuItem(value: 'new', child: Text('Yeni')),
                  DropdownMenuItem(value: 'approved', child: Text('Onayland?')),
                  DropdownMenuItem(
                    value: 'rejected',
                    child: Text('Reddedildi'),
                  ),
                ],
                onChanged: (value) {
                  setState(
                    () => _statusFilter = value?.isEmpty == true ? null : value,
                  );
                  _load();
                },
              ),
              const Spacer(),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'BaÅŸvuru bulunamadÄ±.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _SubmissionCard(
                  item: _items[i],
                  onApprove: () => _approve(_items[i]),
                  onReject: () => _reject(_items[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _approve(AdminBusinessSubmission item) async {
    final ok = await _confirm(context, 'BaÅŸvuruyu onaylamak istiyor musun?');
    if (!ok) return;
    try {
      await ref
          .read(adminBusinessSubmissionsRepositoryProvider)
          .approve(item.id);
      if (mounted) _load();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _reject(AdminBusinessSubmission item) async {
    final noteCtrl = TextEditingController();
    final res = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reddet'),
        content: TextField(
          controller: noteCtrl,
          decoration: const InputDecoration(labelText: 'Not (opsiyonel)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('VazgeÃ§'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, noteCtrl.text.trim()),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
    if (res == null) return;
    try {
      await ref
          .read(adminBusinessSubmissionsRepositoryProvider)
          .reject(item.id, note: res);
      if (mounted) _load();
    } catch (e) {
      _showError(e);
    } finally {
      noteCtrl.dispose();
    }
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  final AdminBusinessSubmission item;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (item.status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.danger,
      _ => AppColors.warning,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              '${item.district} â€¢ ${item.city}',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 6),
            Text(item.address, style: const TextStyle(color: AppColors.slate)),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _fmtDate(item.createdAt),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: item.status == 'new' ? onApprove : null,
                    child: const Text('Onayla'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: item.status == 'new' ? onReject : null,
                    child: const Text('Reddet'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _confirm(BuildContext context, String message) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Emin misin?'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('VazgeÃ§'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Onayla'),
        ),
      ],
    ),
  );
  return res ?? false;
}

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
