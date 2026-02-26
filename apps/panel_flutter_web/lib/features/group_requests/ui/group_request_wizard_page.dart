import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/storage/location_prefs.dart';
import '../../auth/domain/auth_providers.dart';
import '../data/group_requests_repository.dart';
import '../../../src/ui/design_system.dart';

class GroupRequestWizardPage extends ConsumerStatefulWidget {
  const GroupRequestWizardPage({super.key});

  @override
  ConsumerState<GroupRequestWizardPage> createState() => _GroupRequestWizardPageState();
}

class _GroupRequestWizardPageState extends ConsumerState<GroupRequestWizardPage> {
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _partyCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime? _selectedDateTime;
  bool _submitting = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _prefillLocation();
  }

  Future<void> _prefillLocation() async {
    final saved = await LocationPrefs.read();
    if (saved == null || !mounted) return;
    _cityCtrl.text = saved.$1;
    _districtCtrl.text = saved.$2;
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _categoryCtrl.dispose();
    _partyCtrl.dispose();
    _budgetCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Grup Yemeği Talebi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Detayları gir',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 10),
          if (_error != null) ...[
            Text(
              AppErrorMapper.message(_error),
              style: const TextStyle(color: AppColors.danger),
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: _cityCtrl,
            decoration: const InputDecoration(labelText: 'Şehir'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _districtCtrl,
            decoration: const InputDecoration(labelText: 'İlçe'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _categoryCtrl,
            decoration: const InputDecoration(labelText: 'Kategori (kahve, lokanta...)'),
          ),
          const SizedBox(height: 8),
          _DateTimePicker(
            dateTime: _selectedDateTime,
            onSelect: (dt) => setState(() => _selectedDateTime = dt),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _partyCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Kişi sayısı'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _budgetCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Toplam bütçe (?,?)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notlar'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Talep Oluştur'),
            ),
          ),
          const SizedBox(height: 8),
          const AppEmptyState(
            icon: Icons.info_outline,
            title: 'Teklifler işletmelerden gelir',
            description: 'Talebin açıldıktan sonra işletmeler teklif verebilir.',
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final city = _cityCtrl.text.trim();
    final district = _districtCtrl.text.trim();
    final category = _categoryCtrl.text.trim();
    final party = int.tryParse(_partyCtrl.text.trim());
    final budget = _parseBudget(_budgetCtrl.text.trim());
    final dt = _selectedDateTime;
    if (city.isEmpty || party == null || budget == null || dt == null) {
      setState(() => _error = 'Eksik alan var');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final id = await ref.read(groupRequestsRepositoryProvider).createGroupRequest(
            city: city,
            districts: district.isEmpty ? [] : [district],
            category: category.isEmpty ? null : category,
            dateTime: dt,
            partySize: party,
            budgetTotalCents: budget,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );
      if (!mounted) return;
      context.go('/group-requests/$id?created=1');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e;
      });
    }
  }
}

class _DateTimePicker extends StatelessWidget {
  const _DateTimePicker({required this.dateTime, required this.onSelect});

  final DateTime? dateTime;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final text = dateTime == null
        ? 'Tarih ve saat seç'
        : '${dateTime!.day.toString().padLeft(2, '0')}.'
            '${dateTime!.month.toString().padLeft(2, '0')}.'
            '${dateTime!.year}  '
            '${dateTime!.hour.toString().padLeft(2, '0')}:'
            '${dateTime!.minute.toString().padLeft(2, '0')}';
    return OutlinedButton.icon(
      onPressed: () async {
        final now = DateTime.now();
        final date = await showDatePicker(
          context: context,
          firstDate: now,
          lastDate: now.add(const Duration(days: 365)),
          initialDate: dateTime ?? now,
        );
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(dateTime ?? now),
        );
        if (time == null) return;
        onSelect(DateTime(date.year, date.month, date.day, time.hour, time.minute));
      },
      icon: const Icon(Icons.event),
      label: Text(text),
    );
  }
}

int? _parseBudget(String raw) {
  if (raw.isEmpty) return null;
  final normalized = raw.replaceAll(',', '.');
  final value = double.tryParse(normalized);
  if (value == null || value <= 0) return null;
  return (value * 100).round();
}


