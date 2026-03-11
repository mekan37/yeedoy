import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/errors/app_error_mapper.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../data/admin_monetization_repository.dart';
import '../../data/admin_businesses_repository.dart';
import '../../domain/admin_models.dart';
import '../../domain/admin_sponsorship_packages_controller.dart';
import '../../domain/admin_sponsorships_controller.dart';

class AdminSponsorshipCreateSheet extends ConsumerStatefulWidget {
  const AdminSponsorshipCreateSheet({
    super.key,
    this.initialBusiness,
    this.initialSurface,
    this.initialTargeting,
  });

  final AdminBusinessItem? initialBusiness;
  final String? initialSurface;
  final Map<String, dynamic>? initialTargeting;

  @override
  ConsumerState<AdminSponsorshipCreateSheet> createState() => _AdminSponsorshipCreateSheetState();
}

class _AdminSponsorshipCreateSheetState extends ConsumerState<AdminSponsorshipCreateSheet> {
  final _businessSearchCtrl = TextEditingController();
  final _startsCtrl = TextEditingController();
  final _endsCtrl = TextEditingController();
  final _dailyCapCtrl = TextEditingController();
  final _totalCapCtrl = TextEditingController();
  final _priorityCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();

  List<AdminBusinessItem> _businessResults = [];
  AdminBusinessItem? _selectedBusiness;
  String _surface = 'discovery';
  String? _packageId;
  List<String> _cities = [];
  List<String> _districts = [];
  List<String> _categories = [];
  Object? _error;
  bool _loading = false;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _selectedBusiness = widget.initialBusiness;
    _surface = widget.initialSurface ?? 'discovery';
    final targeting = widget.initialTargeting ?? {};
    _cities = _readList(targeting['city']);
    _districts = _readList(targeting['district']);
    _categories = _readList(targeting['category']);
  }

  @override
  void dispose() {
    _businessSearchCtrl.dispose();
    _startsCtrl.dispose();
    _endsCtrl.dispose();
    _dailyCapCtrl.dispose();
    _totalCapCtrl.dispose();
    _priorityCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final packagesState = ref.watch(adminSponsorshipPackagesControllerProvider);
    final packages = packagesState.items
        .where((package) => package.surface == _surface && package.isActive)
        .toList();
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.adminSponsorshipCreateTitle,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            _businessPicker(),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: ValueKey(_surface),
              initialValue: _surface,
              items: [
                DropdownMenuItem(
                  value: 'discovery',
                  child: Text(l10n.adminSponsorshipSurfaceDiscovery),
                ),
                DropdownMenuItem(
                  value: 'business_page',
                  child: Text(l10n.adminSponsorshipSurfaceBusinessPage),
                ),
                DropdownMenuItem(
                  value: 'stories',
                  child: Text(l10n.adminSponsorshipPackagesSurfaceStories),
                ),
                DropdownMenuItem(
                  value: 'verified',
                  child: Text(l10n.adminSponsorshipPackagesSurfaceVerified),
                ),
                DropdownMenuItem(
                  value: 'premium',
                  child: Text(l10n.adminSponsorshipPackagesSurfacePremium),
                ),
              ],
              onChanged: (v) => setState(() {
                _surface = v ?? 'discovery';
                _packageId = null;
              }),
              decoration: InputDecoration(
                labelText: l10n.adminSponsorshipSurfaceLabel,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey(_packageId),
              initialValue: _packageId,
              items: [
                for (final p in packages)
                  DropdownMenuItem(
                    value: p.id,
                    child: Text(
                      l10n.adminSponsorshipPackageOption(p.name, p.durationDays),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _packageId = v),
              decoration: InputDecoration(
                labelText: l10n.adminSponsorshipPackageLabel,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startsCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.adminSponsorshipStartDateLabel,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _endsCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.adminSponsorshipEndDateLabel,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dailyCapCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.adminSponsorshipDailyCapLabel,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _totalCapCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.adminSponsorshipTotalCapLabel,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _priorityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.adminSponsorshipPriorityOptionalLabel,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.adminSponsorshipTargetingTitle,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            _chipsInput(
              label: l10n.city,
              controller: _cityCtrl,
              values: _cities,
              onAdd: (v) => setState(() => _cities = [..._cities, v]),
              onRemove: (v) => setState(() => _cities = _cities.where((e) => e != v).toList()),
            ),
            const SizedBox(height: 6),
            _chipsInput(
              label: l10n.district,
              controller: _districtCtrl,
              values: _districts,
              onAdd: (v) => setState(() => _districts = [..._districts, v]),
              onRemove: (v) => setState(() => _districts = _districts.where((e) => e != v).toList()),
            ),
            const SizedBox(height: 6),
            _chipsInput(
              label: l10n.ownerCategoryLabel,
              controller: _categoryCtrl,
              values: _categories,
              onAdd: (v) => setState(() => _categories = [..._categories, v]),
              onRemove: (v) => setState(() => _categories = _categories.where((e) => e != v).toList()),
            ),
            const SizedBox(height: 10),
            if (_error != null)
              Text(
                AppErrorMapper.message(_error),
                style: const TextStyle(color: AppColors.danger),
              ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: Text(
                  _loading
                      ? l10n.adminSponsorshipSavingAction
                      : l10n.adminSponsorshipCreateAction,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _businessPicker() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.businessLabel,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _businessSearchCtrl,
                decoration: InputDecoration(
                  hintText: l10n.adminSponsorshipSearchBusinessHint,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _searching ? null : _searchBusinesses,
              child: Text(
                _searching
                    ? l10n.adminSponsorshipSearchingAction
                    : l10n.adminSponsorshipSearchAction,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedBusiness != null)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selectedBusiness!.name} • ${_selectedBusiness!.city ?? '-'}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedBusiness = null),
                  child: Text(l10n.adminSponsorshipRemoveBusinessAction),
                ),
              ],
            ),
          ),
        if (_selectedBusiness == null && _businessResults.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _businessResults.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, i) {
                final b = _businessResults[i];
                return ListTile(
                  title: Text(b.name),
                  subtitle: Text('${b.district ?? ''} • ${b.city ?? ''}'),
                  onTap: () => setState(() {
                    _selectedBusiness = b;
                    _businessResults = [];
                  }),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _chipsInput({
    required String label,
    required TextEditingController controller,
    required List<String> values,
    required void Function(String) onAdd,
    required void Function(String) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(labelText: label),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                final v = controller.text.trim();
                if (v.isEmpty) return;
                controller.clear();
                onAdd(v);
              },
              child: Text(context.l10n.adminSponsorshipAddTargetingValueAction),
            ),
          ],
        ),
        if (values.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final v in values)
                Chip(
                  label: Text(v),
                  onDeleted: () => onRemove(v),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _searchBusinesses() async {
    final q = _businessSearchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    try {
      final repo = ref.read(adminBusinessesRepositoryProvider);
      final items = await repo.listBusinesses(limit: 10, offset: 0, query: q);
      setState(() => _businessResults = items);
    } catch (e) {
      setState(() => _error = e);
    } finally {
      setState(() => _searching = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedBusiness == null) {
      setState(
        () => _error = Exception(context.l10n.adminSponsorshipSelectBusinessError),
      );
      return;
    }
    if (_packageId == null || _packageId!.isEmpty) {
      setState(
        () => _error = Exception(context.l10n.adminSponsorshipSelectPackageError),
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final targeting = <String, dynamic>{};
      if (_cities.isNotEmpty) targeting['city'] = _cities;
      if (_districts.isNotEmpty) targeting['district'] = _districts;
      if (_categories.isNotEmpty) targeting['category'] = _categories;
      final priority = int.tryParse(_priorityCtrl.text.trim());
      if (priority != null) targeting['priority'] = priority;

      final repo = ref.read(adminMonetizationRepositoryProvider);
      await repo.createSponsorship(
        businessId: _selectedBusiness!.id,
        packageId: _packageId!,
        surface: _surface,
        startsAt: _parseDate(_startsCtrl.text.trim()),
        endsAt: _parseDate(_endsCtrl.text.trim()),
        targeting: targeting,
        dailyCap: int.tryParse(_dailyCapCtrl.text.trim()),
        totalCap: int.tryParse(_totalCapCtrl.text.trim()),
      );
      ref.read(adminSponsorshipsControllerProvider.notifier).refresh();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.adminSponsorshipCreated)),
      );
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

List<String> _readList(dynamic v) {
  if (v is List) return v.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
  return [];
}

DateTime? _parseDate(String input) {
  if (input.isEmpty) return null;
  return DateTime.tryParse(input);
}



