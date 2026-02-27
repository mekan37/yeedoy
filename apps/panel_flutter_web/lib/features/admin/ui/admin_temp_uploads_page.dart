import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/media/app_network_image.dart';
import '../../auth/domain/auth_providers.dart';
import '../data/admin_temp_uploads_repository.dart';
import '../domain/admin_temp_upload_item.dart';
import '../../../shared/ui/design_system.dart';

class AdminTempUploadsPage extends ConsumerStatefulWidget {
  const AdminTempUploadsPage({super.key});

  @override
  ConsumerState<AdminTempUploadsPage> createState() =>
      _AdminTempUploadsPageState();
}

class _AdminTempUploadsPageState extends ConsumerState<AdminTempUploadsPage> {
  bool _loading = true;
  Object? _error;
  List<AdminTempUploadItem> _items = const [];

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
      final repo = ref.read(adminTempUploadsRepositoryProvider);
      final items = await repo.listPending(limit: 50);
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _promote(AdminTempUploadItem item) async {
    final repo = ref.read(adminTempUploadsRepositoryProvider);
    final assetType = item.kind == 'menu_pdf' ? 'menu_pdf' : 'menu_page';
    try {
      await repo.promote(tempUploadId: item.id, assetType: assetType);
      if (!mounted) return;
      setState(() => _items = _items.where((e) => e.id != item.id).toList());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Menüye aktarıldı.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _reject(AdminTempUploadItem item) async {
    final noteCtrl = TextEditingController();
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reddet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Red nedeni (opsiyonel)',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Vazgeç'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(context).pop(noteCtrl.text.trim()),
                      child: const Text('Reddet'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    noteCtrl.dispose();
    if (!mounted || note == null) return;
    final reviewerId = ref.read(userProvider)?.id;
    if (reviewerId == null || reviewerId.isEmpty) return;
    try {
      await ref
          .read(adminTempUploadsRepositoryProvider)
          .reject(tempUploadId: item.id, note: note, reviewerId: reviewerId);
      if (!mounted) return;
      setState(() => _items = _items.where((e) => e.id != item.id).toList());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kayıt reddedildi.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Geçici yükleme inceleme',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading) const AppSkeletonBox(height: 72),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                AppErrorMapper.message(_error),
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: !_loading && _items.isEmpty
                ? const AppEmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'Bekleyen geçici yükleme yok',
                    description:
                        'Yeni gönderimler geldiğinde burada listelenir.',
                  )
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return AppCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 108,
                                height: 96,
                                child: item.previewUrl == null
                                    ? const ColoredBox(
                                        color: AppColors.card,
                                        child: Icon(Icons.image_not_supported),
                                      )
                                    : AppNetworkImage(
                                        url: item.previewUrl!,
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
                                  Text(
                                    item.kind,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'business_id: ${item.businessId}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _fmtDate(item.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      FilledButton.tonal(
                                        onPressed: () => _promote(item),
                                        child: const Text('Menüye aktar'),
                                      ),
                                      OutlinedButton(
                                        onPressed: () => _reject(item),
                                        child: const Text('Reddet'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            context.go('/b/${item.businessId}'),
                                        child: const Text('İşletmeye git'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

String _fmtDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day.$month.${date.year} $hour:$minute';
}
