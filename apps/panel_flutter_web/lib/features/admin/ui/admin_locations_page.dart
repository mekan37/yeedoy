import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../domain/admin_locations_controller.dart';

class AdminLocationsPage extends ConsumerStatefulWidget {
  const AdminLocationsPage({super.key});

  @override
  ConsumerState<AdminLocationsPage> createState() => _AdminLocationsPageState();
}

class _AdminLocationsPageState extends ConsumerState<AdminLocationsPage> {
  final fromCtrl = TextEditingController();
  final toCtrl = TextEditingController();
  String table = 'businesses';
  String column = 'city';
  bool caseInsensitive = true;
  bool submitting = false;

  @override
  void dispose() {
    fromCtrl.dispose();
    toCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(adminLocationsControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Araçlar > Konumlar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  initialValue: table,
                  items: const [
                    DropdownMenuItem(value: 'businesses', child: Text('İşletmeler')),
                    DropdownMenuItem(value: 'business_suggestions', child: Text('İşletme Önerileri')),
                  ],
                  onChanged: (v) => setState(() => table = v ?? table),
                  decoration: const InputDecoration(labelText: 'Tablo'),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  initialValue: column,
                  items: const [
                    DropdownMenuItem(value: 'city', child: Text('Şehir')),
                    DropdownMenuItem(value: 'district', child: Text('İlçe')),
                  ],
                  onChanged: (v) => setState(() => column = v ?? column),
                  decoration: const InputDecoration(labelText: 'Bölüm'),
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  Checkbox(
                    value: caseInsensitive,
                    onChanged: (v) => setState(() => caseInsensitive = v ?? true),
                  ),
                  const Text('Büyük/küçük harf duyarsız'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: fromCtrl,
                  decoration: const InputDecoration(labelText: 'ile'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: toCtrl,
                  decoration: const InputDecoration(labelText: 'için'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: st.isLoading || submitting
                    ? null
                    : () async {
                        try {
                          final count =
                              await ref.read(adminLocationsControllerProvider.notifier).preview(
                                table: table,
                                column: column,
                                from: fromCtrl.text.trim(),
                                caseInsensitive: caseInsensitive,
                              );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Etkilenecek kayıt: $count')),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppErrorMapper.message(e))),
                          );
                        }
                      },
                child: Text(st.isLoading ? 'Kontrol ediliyor...' : 'Bekleyin'),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: st.isLoading || submitting
                    ? null
                    : () async {
                        final from = fromCtrl.text.trim();
                        final to = toCtrl.text.trim();
                        if (from.isEmpty || to.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('From ve To gerekli.')),
                          );
                          return;
                        }
                        final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Onay'),
                                content: Text(
                                  '"$from" -> "$to" değeri değiştirilecek. Emin misin?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Vazgeç'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Uygula'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                        if (!ok) return;
                        setState(() => submitting = true);
                        try {
                          await ref.read(adminLocationsControllerProvider.notifier).apply(
                                table: table,
                                column: column,
                                from: from,
                                to: to,
                                caseInsensitive: caseInsensitive,
                              );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Güncellendi.')),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppErrorMapper.message(e))),
                          );
                        } finally {
                          if (mounted) setState(() => submitting = false);
                        }
                      },
                child: Text(submitting ? 'Uygulanıyor...' : 'Uygula'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (st.previewCount > 0)
            Text('Etkilenecek kayıt: ${st.previewCount}',
                style: const TextStyle(color: AppColors.muted)),
          if (st.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                AppErrorMapper.message(st.error),
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
        ],
      ),
    );
  }
}





