import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../data/admin_incident_repository.dart';

class AdminIncidentCenterPage extends ConsumerStatefulWidget {
  const AdminIncidentCenterPage({super.key});

  @override
  ConsumerState<AdminIncidentCenterPage> createState() =>
      _AdminIncidentCenterPageState();
}

class _AdminIncidentCenterPageState extends ConsumerState<AdminIncidentCenterPage> {
  final _incidentKeyCtrl = TextEditingController(text: 'yanlis-fiyat');
  final _titleCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _actionCtrl = TextEditingController();
  String _status = 'open';
  String _visibility = 'public';
  bool _saving = false;

  @override
  void dispose() {
    _incidentKeyCtrl.dispose();
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _actionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text(
            'Kriz Müdahale Merkezi',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sahte işletme, yanlış fiyat ve medya krizleri için hızlı panel.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          _QuickPanel(onTap: (route) => context.go(route)),
          const SizedBox(height: 12),
          const _ReadyResponses(),
          const SizedBox(height: 12),
          _LogComposer(
            incidentKeyCtrl: _incidentKeyCtrl,
            titleCtrl: _titleCtrl,
            summaryCtrl: _summaryCtrl,
            actionCtrl: _actionCtrl,
            status: _status,
            visibility: _visibility,
            saving: _saving,
            onStatusChanged: (v) => setState(() => _status = v),
            onVisibilityChanged: (v) => setState(() => _visibility = v),
            onSave: _save,
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<IncidentUpdate>>(
            future: ref.read(adminIncidentRepositoryProvider).listAdmin(limit: 100),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Text(
                  AppErrorMapper.message(snap.error),
                  style: const TextStyle(color: AppColors.danger),
                );
              }
              final items = snap.data ?? const [];
              if (items.isEmpty) {
                return const Text('Henüz kayıtlı kriz logu yok.');
              }
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Şeffaf Log',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      for (final item in items.take(20)) ...[
                        Text(
                          '${item.incidentKey} • ${item.status.toUpperCase()} • ${_fmtTime(item.createdAt)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textStrong,
                          ),
                        ),
                        Text(item.title),
                        Text(item.summary, style: const TextStyle(color: AppColors.muted)),
                        Text(
                          'Nasıl düzelttik: ${item.actionTaken}',
                          style: const TextStyle(color: AppColors.textStrong),
                        ),
                        const Divider(height: 18),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_incidentKeyCtrl.text.trim().isEmpty ||
        _titleCtrl.text.trim().isEmpty ||
        _summaryCtrl.text.trim().isEmpty ||
        _actionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tüm alanları doldur.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(adminIncidentRepositoryProvider).create(
        incidentKey: _incidentKeyCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        summary: _summaryCtrl.text.trim(),
        actionTaken: _actionCtrl.text.trim(),
        status: _status,
        visibility: _visibility,
      );
      if (!mounted) return;
      _titleCtrl.clear();
      _summaryCtrl.clear();
      _actionCtrl.clear();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _fmtTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}

class _QuickPanel extends StatelessWidget {
  const _QuickPanel({required this.onTap});

  final void Function(String route) onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hızlı Müdahale Paneli',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => onTap('/admin/reports'),
                  child: const Text('Rapor Kuyruğu'),
                ),
                OutlinedButton(
                  onPressed: () => onTap('/admin/businesses'),
                  child: const Text('İşletme İncele'),
                ),
                OutlinedButton(
                  onPressed: () => onTap('/admin/audit'),
                  child: const Text('Denetim Log'),
                ),
                OutlinedButton(
                  onPressed: () => onTap('/guvenlik-durumu'),
                  child: const Text('Nasıl Düzelttik Ekranı'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadyResponses extends StatelessWidget {
  const _ReadyResponses();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Hazır Cevaplar',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 8),
            Text(
              'Yanlış fiyat: Hata kaydı açıldı, ilgili menü geçici olarak geri plana alındı, doğrulama sonrasi tekrar aktif.',
            ),
            SizedBox(height: 6),
            Text(
              'Sahte işletme: Kayıt incelemeye alındı, görünürlük düşürüldü, yinelenen/sahte sinyalleri ile otomatik kısıy uygulandı.',
            ),
            SizedBox(height: 6),
            Text(
              'Medya senaryosu: Açık zaman çizelgesi yayınlandı, yapılan düzeltmeler ve SLA adımları şeffaf şekilde paylaşıldı.',
            ),
          ],
        ),
      ),
    );
  }
}

class _LogComposer extends StatelessWidget {
  const _LogComposer({
    required this.incidentKeyCtrl,
    required this.titleCtrl,
    required this.summaryCtrl,
    required this.actionCtrl,
    required this.status,
    required this.visibility,
    required this.saving,
    required this.onStatusChanged,
    required this.onVisibilityChanged,
    required this.onSave,
  });

  final TextEditingController incidentKeyCtrl;
  final TextEditingController titleCtrl;
  final TextEditingController summaryCtrl;
  final TextEditingController actionCtrl;
  final String status;
  final String visibility;
  final bool saving;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onVisibilityChanged;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Şeffaf Log Girdisi',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: incidentKeyCtrl,
              decoration: const InputDecoration(labelText: 'Olay anahtarı'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Başlık'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: summaryCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Ne oldu?'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: actionCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Nasıl düzelttik?'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                DropdownButton<String>(
                  value: status,
                  items: const [
                    DropdownMenuItem(value: 'open', child: Text('open')),
                    DropdownMenuItem(value: 'mitigated', child: Text('mitigated')),
                    DropdownMenuItem(value: 'resolved', child: Text('resolved')),
                  ],
                  onChanged: (v) {
                    if (v != null) onStatusChanged(v);
                  },
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: visibility,
                  items: const [
                    DropdownMenuItem(value: 'public', child: Text('public')),
                    DropdownMenuItem(value: 'internal', child: Text('internal')),
                  ],
                  onChanged: (v) {
                    if (v != null) onVisibilityChanged(v);
                  },
                ),
                const Spacer(),
                FilledButton(
                  onPressed: saving ? null : onSave,
                  child: Text(saving ? 'Kaydediliyor...' : 'Log ekle'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

