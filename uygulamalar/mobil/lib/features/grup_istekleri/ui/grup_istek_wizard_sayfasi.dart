import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../uygulama/tema/renkler.dart';
import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../core/depolama/konum_tercihleri.dart';
import '../../kimlik/domain/kimlik_saglayicilari.dart';
import '../data/grup_istekleri_deposu.dart';
import '../../../features/shared/ui/tasarim_sistemi.dart';

class GroupRequestWizardPage extends ConsumerStatefulWidget {
  const GroupRequestWizardPage({super.key});

  @override
  ConsumerState<GroupRequestWizardPage> createState() =>
      _GroupRequestWizardPageState();
}

class _GroupRequestWizardPageState
    extends ConsumerState<GroupRequestWizardPage> {
  // Step control
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 3;

  // Step 1 — İşletme Seçimi
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();

  // Step 2 — Detaylar
  final _partyCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _selectedDateTime;

  // Step 3 — Özet + Gönder
  bool _submitting = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _prefillLocation();
    _partyCtrl.text = '2';
  }

  Future<void> _prefillLocation() async {
    final saved = await LocationPrefs.read();
    if (saved == null || !mounted) return;
    _cityCtrl.text = saved.$1;
    _districtCtrl.text = saved.$2;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _categoryCtrl.dispose();
    _partyCtrl.dispose();
    _budgetCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _totalSteps) return;
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validateStep1() {
    final city = _cityCtrl.text.trim();
    return city.isNotEmpty;
  }

  bool _validateStep2() {
    final party = int.tryParse(_partyCtrl.text.trim());
    final budget = _parseBudget(_budgetCtrl.text.trim());
    return party != null && party >= 1 && party <= 50 && budget != null && _selectedDateTime != null;
  }

  void _nextStep() {
    if (_currentStep == 0 && !_validateStep1()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen şehir bilgisini girin.')),
      );
      return;
    }
    if (_currentStep == 1 && !_validateStep2()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tarih, kişi sayısı ve bütçeyi doldurun.'),
        ),
      );
      return;
    }
    _goToStep(_currentStep + 1);
  }

  void _prevStep() => _goToStep(_currentStep - 1);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final user = ref.watch(userProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.groupRequestWizardTitle)),
      body: Column(
        children: [
          _StepIndicator(
            current: _currentStep,
            total: _totalSteps,
            labels: const ['İşletme', 'Detaylar', 'Özet'],
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentStep = i),
              children: [
                _Step1Location(
                  cityCtrl: _cityCtrl,
                  districtCtrl: _districtCtrl,
                  categoryCtrl: _categoryCtrl,
                  onNext: _nextStep,
                ),
                _Step2Details(
                  partyCtrl: _partyCtrl,
                  budgetCtrl: _budgetCtrl,
                  notesCtrl: _notesCtrl,
                  selectedDateTime: _selectedDateTime,
                  onDateTimeSelected: (dt) =>
                      setState(() => _selectedDateTime = dt),
                  onBack: _prevStep,
                  onNext: _nextStep,
                ),
                _Step3Summary(
                  city: _cityCtrl.text.trim(),
                  district: _districtCtrl.text.trim(),
                  category: _categoryCtrl.text.trim(),
                  party: int.tryParse(_partyCtrl.text.trim()) ?? 0,
                  budget: _parseBudget(_budgetCtrl.text.trim()) ?? 0,
                  notes: _notesCtrl.text.trim(),
                  dateTime: _selectedDateTime,
                  submitting: _submitting,
                  error: _error,
                  onBack: _prevStep,
                  onEdit: (step) => _goToStep(step),
                  onSubmit: _submit,
                ),
              ],
            ),
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
      setState(() => _error = 'Lütfen tüm zorunlu alanları doldurun.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final id = await ref
          .read(groupRequestsRepositoryProvider)
          .createGroupRequest(
            city: city,
            districts: district.isEmpty ? [] : [district],
            category: category.isEmpty ? null : category,
            dateTime: dt,
            partySize: party,
            budgetTotalCents: budget,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          );
      if (!mounted) return;
      context.go('/grup-istekleri/$id?created=1');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e;
      });
    }
  }
}

// ── Step Indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.current,
    required this.total,
    required this.labels,
  });

  final int current;
  final int total;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  color: i <= current
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
            _StepDot(
              index: i,
              label: labels[i],
              state: i < current
                  ? _StepDotState.done
                  : i == current
                      ? _StepDotState.active
                      : _StepDotState.inactive,
            ),
          ],
        ],
      ),
    );
  }
}

enum _StepDotState { done, active, inactive }

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.label,
    required this.state,
  });

  final int index;
  final String label;
  final _StepDotState state;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (state) {
      _StepDotState.done => (AppColors.primary, Colors.white),
      _StepDotState.active => (AppColors.primary, Colors.white),
      _StepDotState.inactive => (AppColors.border, AppColors.muted),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: state == _StepDotState.done
              ? Icon(Icons.check, color: fg, size: 16)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight:
                state == _StepDotState.active ? FontWeight.w800 : FontWeight.w500,
            color: state == _StepDotState.inactive
                ? AppColors.muted
                : AppColors.textStrong,
          ),
        ),
      ],
    );
  }
}

// ── Step 1: İşletme Seçimi (Şehir/İlçe/Kategori) ─────────────────────────────

class _Step1Location extends StatelessWidget {
  const _Step1Location({
    required this.cityCtrl,
    required this.districtCtrl,
    required this.categoryCtrl,
    required this.onNext,
  });

  final TextEditingController cityCtrl;
  final TextEditingController districtCtrl;
  final TextEditingController categoryCtrl;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const Text(
          'Mekan Bilgileri',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Hangi şehir ve ilçede mekan arıyorsunuz?',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: cityCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Şehir *',
            prefixIcon: Icon(Icons.location_city_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: districtCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'İlçe (opsiyonel)',
            prefixIcon: Icon(Icons.place_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: categoryCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Mutfak / Kategori (opsiyonel)',
            hintText: 'örn. İtalyan, Türk, Cafe...',
            prefixIcon: Icon(Icons.restaurant_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Devam'),
          ),
        ),
      ],
    );
  }
}

// ── Step 2: Detaylar ──────────────────────────────────────────────────────────

class _Step2Details extends StatelessWidget {
  const _Step2Details({
    required this.partyCtrl,
    required this.budgetCtrl,
    required this.notesCtrl,
    required this.selectedDateTime,
    required this.onDateTimeSelected,
    required this.onBack,
    required this.onNext,
  });

  final TextEditingController partyCtrl;
  final TextEditingController budgetCtrl;
  final TextEditingController notesCtrl;
  final DateTime? selectedDateTime;
  final ValueChanged<DateTime> onDateTimeSelected;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const Text(
          'Talep Detayları',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tarih, kişi sayısı ve bütçenizi belirleyin.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 20),
        _DateTimePicker(
          dateTime: selectedDateTime,
          onSelect: onDateTimeSelected,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: partyCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Kişi Sayısı * (1-50)',
            prefixIcon: Icon(Icons.group_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: budgetCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Toplam Bütçe (TL) *',
            prefixIcon: Icon(Icons.payments_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: notesCtrl,
          maxLines: 3,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Notlar (opsiyonel)',
            hintText: 'Özel istekler, tercihler...',
            prefixIcon: Icon(Icons.notes_outlined),
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Geri'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: onNext,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Özeti Gör'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Step 3: Özet + Gönder ─────────────────────────────────────────────────────

class _Step3Summary extends StatelessWidget {
  const _Step3Summary({
    required this.city,
    required this.district,
    required this.category,
    required this.party,
    required this.budget,
    required this.notes,
    required this.dateTime,
    required this.submitting,
    required this.error,
    required this.onBack,
    required this.onEdit,
    required this.onSubmit,
  });

  final String city;
  final String district;
  final String category;
  final int party;
  final int budget;
  final String notes;
  final DateTime? dateTime;
  final bool submitting;
  final Object? error;
  final VoidCallback onBack;
  final void Function(int step) onEdit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final budgetDisplay = (budget / 100).toStringAsFixed(0);
    final dateDisplay = dateTime == null
        ? 'Belirtilmedi'
        : '${dateTime!.day.toString().padLeft(2, '0')}.'
              '${dateTime!.month.toString().padLeft(2, '0')}.'
              '${dateTime!.year}  '
              '${dateTime!.hour.toString().padLeft(2, '0')}:'
              '${dateTime!.minute.toString().padLeft(2, '0')}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const Text(
          'Özet',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Talep bilgilerini kontrol edin ve gönderin.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Mekan Bilgileri',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => onEdit(0),
                    child: const Text('Düzenle'),
                  ),
                ],
              ),
              _SummaryRow(
                label: 'Şehir',
                value: city.isEmpty ? '—' : city,
              ),
              if (district.isNotEmpty)
                _SummaryRow(label: 'İlçe', value: district),
              if (category.isNotEmpty)
                _SummaryRow(label: 'Kategori', value: category),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Talep Detayları',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => onEdit(1),
                    child: const Text('Düzenle'),
                  ),
                ],
              ),
              _SummaryRow(label: 'Tarih / Saat', value: dateDisplay),
              _SummaryRow(label: 'Kişi Sayısı', value: '$party kişi'),
              _SummaryRow(label: 'Toplam Bütçe', value: '$budgetDisplay TL'),
              if (notes.isNotEmpty)
                _SummaryRow(label: 'Notlar', value: notes),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            AppErrorMapper.message(error),
            style: const TextStyle(color: AppColors.danger, fontSize: 13),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: submitting ? null : onSubmit,
            icon: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_outlined),
            label: const Text(
              'Grup Talebi Oluştur',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Geri'),
        ),
        const SizedBox(height: 20),
        AppEmptyState(
          icon: Icons.info_outline,
          title: AppLocalizations.of(context).groupRequestWizardInfoTitle,
          description:
              AppLocalizations.of(context).groupRequestWizardInfoDescription,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date / Time Picker ────────────────────────────────────────────────────────

class _DateTimePicker extends StatelessWidget {
  const _DateTimePicker({required this.dateTime, required this.onSelect});

  final DateTime? dateTime;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final text = dateTime == null
        ? 'Tarih ve Saat Seç *'
        : '${dateTime!.day.toString().padLeft(2, '0')}.'
              '${dateTime!.month.toString().padLeft(2, '0')}.'
              '${dateTime!.year}  '
              '${dateTime!.hour.toString().padLeft(2, '0')}:'
              '${dateTime!.minute.toString().padLeft(2, '0')}';

    final hasDate = dateTime != null;

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
        onSelect(
          DateTime(date.year, date.month, date.day, time.hour, time.minute),
        );
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: hasDate ? AppColors.primary : AppColors.border,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      icon: Icon(
        Icons.event,
        color: hasDate ? AppColors.primary : AppColors.muted,
      ),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            color: hasDate ? AppColors.textStrong : AppColors.muted,
            fontWeight: hasDate ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
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
