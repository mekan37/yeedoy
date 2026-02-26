import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../features/admin/data/admin_incident_repository.dart';

class CrisisStatusPage extends ConsumerWidget {
  const CrisisStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Güvenlik Durumu')),
      body: FutureBuilder<List<IncidentUpdate>>(
        future: ref
            .read(adminIncidentRepositoryProvider)
            .listPublic(limit: 100),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(
              child: Text('Durum kayıtları yüklenemedi. Lütfen tekrar deneyin.'),
            );
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aktif olay kaydı yok. Yine de bir sorun gördüysen rapor ekranından bize iletebilirsin.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const Text(
                'Nasıl düzelttik',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
              ),
              const SizedBox(height: 6),
              const Text(
                'Olayları açık şekilde paylaşıyor, düzeltme adımlarını timeline olarak yayınız.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              for (final item in items) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textStrong,
                                ),
                              ),
                            ),
                            _StatusChip(status: item.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.incidentKey} • ${_fmt(item.createdAt)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.summary,
                          style: const TextStyle(color: AppColors.text),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nasıl düzelttik: ${item.actionTaken}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textStrong,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'resolved' => ('Çözüldü', AppColors.success),
      'mitigated' => ('Kontrol altına alındı', AppColors.warning),
      _ => ('Açık', AppColors.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _fmt(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
}

