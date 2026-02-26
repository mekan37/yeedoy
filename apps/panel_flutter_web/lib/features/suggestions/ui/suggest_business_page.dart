import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/brand/brand_widgets.dart';
import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../src/ui/components/app_scaffold.dart';
import '../data/suggestions_repo.dart';

class SuggestBusinessPage extends ConsumerStatefulWidget {
  const SuggestBusinessPage({super.key});

  @override
  ConsumerState<SuggestBusinessPage> createState() =>
      _SuggestBusinessPageState();
}

class _SuggestBusinessPageState extends ConsumerState<SuggestBusinessPage> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final districtCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final websiteCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  bool loading = false;
  bool _checkingDuplicates = false;
  List<ExistingBusinessCandidate> _duplicates = const [];
  Timer? _dupTimer;

  final categories = const [
    'Kafe',
    'Restoran',
    'Balık',
    'Oto Servis',
    'Klinik',
    'Market',
    'Kuaför',
  ];

  @override
  void dispose() {
    _dupTimer?.cancel();
    nameCtrl.dispose();
    categoryCtrl.dispose();
    cityCtrl.dispose();
    districtCtrl.dispose();
    addressCtrl.dispose();
    phoneCtrl.dispose();
    websiteCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _runDuplicateCheck();
    if (_duplicates.isNotEmpty) {
      final proceed = await _confirmWithDuplicates();
      if (!proceed) return;
    }

    setState(() => loading = true);
    try {
      final id = await ref
          .read(suggestionsRepoProvider)
          .submit(
            name: nameCtrl.text.trim(),
            category: categoryCtrl.text.trim(),
            city: cityCtrl.text.trim().isEmpty ? null : cityCtrl.text.trim(),
            district: districtCtrl.text.trim().isEmpty
                ? null
                : districtCtrl.text.trim(),
            address: addressCtrl.text.trim().isEmpty
                ? null
                : addressCtrl.text.trim(),
            phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
            website: websiteCtrl.text.trim().isEmpty
                ? null
                : websiteCtrl.text.trim(),
            notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
          );

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Önerin alındı mı?'),
          content: Text(
            'Teşekkürler! İnceleme sonucunda işletme yayınlanacak.\n\nTakip Kodu: ${id.substring(0, 8)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 6),
          child: BrandWordmark(height: 26),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          const Text(
            'İşletme Ekle',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bulduğun işletmeyi ekle, topluluğa katkı yap. İnceleme sonucunda yayınlarız.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      onChanged: (_) => _scheduleDuplicateCheck(),
                      decoration: const InputDecoration(
                        labelText: 'İşletme adı',
                      ),
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Zorunlu' : null,
                    ),
                    if (_checkingDuplicates)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    if (_duplicates.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _PossibleDuplicateBox(
                        items: _duplicates,
                        onOpenBusiness: (id) => context.go('/b/$id'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: categories.contains(categoryCtrl.text)
                          ? categoryCtrl.text
                          : null,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => categoryCtrl.text = v ?? '',
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Zorunlu' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: cityCtrl,
                      onChanged: (_) => _scheduleDuplicateCheck(),
                      decoration: const InputDecoration(labelText: 'Şehir'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: districtCtrl,
                      onChanged: (_) => _scheduleDuplicateCheck(),
                      decoration: const InputDecoration(labelText: 'İlçe'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressCtrl,
                      onChanged: (_) => _scheduleDuplicateCheck(),
                      decoration: const InputDecoration(labelText: 'Adres'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Telefon'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: websiteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Web sitesi',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(labelText: 'Notlar'),
                      minLines: 2,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: loading ? null : _submit,
                        child: Text(loading ? '...' : 'Gönder'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleDuplicateCheck() {
    _dupTimer?.cancel();
    _dupTimer = Timer(const Duration(milliseconds: 350), _runDuplicateCheck);
  }

  Future<void> _runDuplicateCheck() async {
    final name = nameCtrl.text.trim();
    if (name.length < 3) {
      if (!mounted) return;
      setState(() {
        _checkingDuplicates = false;
        _duplicates = const [];
      });
      return;
    }
    if (mounted) setState(() => _checkingDuplicates = true);
    try {
      final list = await ref
          .read(suggestionsRepoProvider)
          .findPossibleExisting(
            name: name,
            city: cityCtrl.text.trim(),
            district: districtCtrl.text.trim(),
            address: addressCtrl.text.trim(),
          );
      if (!mounted) return;
      setState(() => _duplicates = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _duplicates = const []);
    } finally {
      if (mounted) setState(() => _checkingDuplicates = false);
    }
  }

  Future<bool> _confirmWithDuplicates() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bu işletme zaten var olabilir'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Arama sonucunda benzer işletmeler bulundu:'),
              const SizedBox(height: 8),
              for (final d in _duplicates.take(3)) ...[
                Text('• ${d.name} (${d.district} / ${d.city})'),
                const SizedBox(height: 4),
              ],
              const SizedBox(height: 8),
              const Text('Yine de yeni öneri göndermek istiyor musun?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yine de Gönder'),
          ),
        ],
      ),
    );
    return res == true;
  }
}

class _PossibleDuplicateBox extends StatelessWidget {
  const _PossibleDuplicateBox({
    required this.items,
    required this.onOpenBusiness,
  });

  final List<ExistingBusinessCandidate> items;
  final ValueChanged<String> onOpenBusiness;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bu işletme zaten var olabilir',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          for (final d in items) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${d.name} • ${d.district} ${d.city}'.trim(),
                    style: const TextStyle(color: AppColors.slate),
                  ),
                ),
                TextButton(
                  onPressed: () => onOpenBusiness(d.id),
                  child: const Text('Aç'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

