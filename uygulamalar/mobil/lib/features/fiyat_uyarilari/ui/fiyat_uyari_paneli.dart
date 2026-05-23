import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../uygulama/tema/renkler.dart';
import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../core/depolama/konum_tercihleri.dart';
import '../data/fiyat_uyari_deposu.dart';
import '../../../features/shared/ui/tasarim_sistemi.dart';

Future<void> showPriceAlertSheet({
  required BuildContext context,
  required String initialQuery,
  String? initialCity,
  String? initialDistrict,
  String? initialCategory,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PriceAlertSheet(
      initialQuery: initialQuery,
      initialCity: initialCity,
      initialDistrict: initialDistrict,
      initialCategory: initialCategory,
    ),
  );
}

class _PriceAlertSheet extends ConsumerStatefulWidget {
  const _PriceAlertSheet({
    required this.initialQuery,
    this.initialCity,
    this.initialDistrict,
    this.initialCategory,
  });

  final String initialQuery;
  final String? initialCity;
  final String? initialDistrict;
  final String? initialCategory;

  @override
  ConsumerState<_PriceAlertSheet> createState() => _PriceAlertSheetState();
}

class _PriceAlertSheetState extends ConsumerState<_PriceAlertSheet> {
  late final TextEditingController _queryCtrl;
  final _priceCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  bool _saving = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _queryCtrl = TextEditingController(text: widget.initialQuery);
    _cityCtrl.text = widget.initialCity ?? '';
    _districtCtrl.text = widget.initialDistrict ?? '';
    _categoryCtrl.text = widget.initialCategory ?? '';
    _prefillLocation();
  }

  Future<void> _prefillLocation() async {
    if (_cityCtrl.text.isNotEmpty || _districtCtrl.text.isNotEmpty) return;
    final saved = await LocationPrefs.read();
    if (saved == null || !mounted) return;
    _cityCtrl.text = saved.$1;
    _districtCtrl.text = saved.$2;
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _priceCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.priceAlertSheetTitle,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (_error != null) ...[
              Text(
                AppErrorMapper.message(_error),
                style: const TextStyle(color: AppColors.danger),
              ),
              const SizedBox(height: 8),
            ],
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _queryCtrl,
                    decoration: InputDecoration(labelText: t.priceAlertSheetQueryLabel),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: t.priceAlertSheetMaxPriceLabel),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _cityCtrl,
                    decoration: InputDecoration(labelText: t.groupRequestWizardCityLabel),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _districtCtrl,
                    decoration: InputDecoration(labelText: t.groupRequestWizardDistrictLabel),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _categoryCtrl,
                    decoration: InputDecoration(
                      labelText: t.priceAlertSheetCategoryLabel,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    final query = _queryCtrl.text.trim();
    final maxPrice = _parsePrice(_priceCtrl.text.trim());
    if (query.isEmpty || maxPrice == null) {
      setState(() => _error = t.priceAlertSheetValidationError);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(priceAlertsRepositoryProvider).createPriceAlert(
            query: query,
            maxPriceCents: (maxPrice * 100).round(),
            city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
            district:
                _districtCtrl.text.trim().isEmpty ? null : _districtCtrl.text.trim(),
            category:
                _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.priceAlertSheetSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e;
      });
    }
  }
}

double? _parsePrice(String value) {
  if (value.isEmpty) return null;
  final normalized = value.replaceAll(',', '.');
  return double.tryParse(normalized);
}





