import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/location/user_location_controller.dart';
import '../../../features/shared/ui/design_system.dart';

class BudgetComboEntryCard extends ConsumerStatefulWidget {
  const BudgetComboEntryCard({super.key});

  @override
  ConsumerState<BudgetComboEntryCard> createState() =>
      _BudgetComboEntryCardState();
}

class _BudgetComboEntryCardState extends ConsumerState<BudgetComboEntryCard> {
  final TextEditingController _budgetCtrl = TextEditingController(text: '300');
  int _partySize = 2;
  String? _category;

  static const _categories = [
    null,
    'Kafe',
    'Restoran',
    'Tatlıcı',
    'Kahvaltı',
    'Balık / Et',
    'Mekan',
  ];

  @override
  void dispose() {
    _budgetCtrl.dispose();
    super.dispose();
  }

  int _parseBudgetCents() {
    final raw = _budgetCtrl.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value <= 0) return 0;
    return (value * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(userLocationProvider);
    final city = (loc.city ?? '').trim();
    final district = (loc.district ?? '').trim();
    final hasLocation = city.isNotEmpty && district.isNotEmpty;
    final budgetCents = _parseBudgetCents();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.budgetComboEntryTitle,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasLocation
                ? '$city - $district'
                : context.l10n.budgetComboLocationNotSelected,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _budgetCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: context.l10n.budgetComboBudgetLabel,
                    prefixText: 'TL ',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.budgetComboPartySizeLabel,
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _partySize <= 1
                            ? null
                            : () => setState(() => _partySize--),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$_partySize',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _partySize++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String?>(
            initialValue: _category,
            items: _categories
                .map(
                  (c) => DropdownMenuItem<String?>(
                    value: c,
                    child: Text(_categoryLabel(context, c)),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _category = value),
            decoration: InputDecoration(
              labelText: context.l10n.budgetComboCategoryOptionalLabel,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: !hasLocation || budgetCents <= 0
                  ? null
                  : () {
                      final params = {
                        'city': city,
                        'district': district,
                        'party': _partySize.toString(),
                        'budget': budgetCents.toString(),
                        ...?(_category == null
                            ? null
                            : {'category': _category}),
                      };
                      context.go(
                        Uri(
                          path: '/budget-combos',
                          queryParameters: params,
                        ).toString(),
                      );
                    },
              child: Text(context.l10n.budgetComboSeeSuggestions),
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(BuildContext context, String? value) {
    final t = context.l10n;
    return switch (value) {
      null => t.budgetComboAllCategories,
      'Kafe' => t.budgetComboCategoryCafe,
      'Restoran' => t.budgetComboCategoryRestaurant,
      'Tatlıcı' => t.budgetComboCategoryDessert,
      'Kahvaltı' => t.budgetComboCategoryBreakfast,
      'Balık / Et' => t.budgetComboCategoryFishMeat,
      'Mekan' => t.budgetComboCategoryVenue,
      _ => value,
    };
  }
}


