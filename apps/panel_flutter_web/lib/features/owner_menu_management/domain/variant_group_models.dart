import 'package:flutter/material.dart';

enum VariantGroupType {
  portion,
  sauce,
  extra,
  doneness,
  custom;

  String get code => name;

  String get trName => switch (this) {
        portion => 'Porsiyon',
        sauce => 'Sos',
        extra => 'Ekstra',
        doneness => 'Pişme Derecesi',
        custom => 'Özel',
      };

  IconData get icon => switch (this) {
        portion => Icons.restaurant_outlined,
        sauce => Icons.water_drop_outlined,
        extra => Icons.add_circle_outline,
        doneness => Icons.local_fire_department_outlined,
        custom => Icons.tune_outlined,
      };

  String get defaultSelectionHint => switch (this) {
        portion => 'Tekil seçim',
        sauce => 'Tekil seçim',
        extra => 'Çoklu seçim',
        doneness => 'Tekil seçim',
        custom => 'Tekil seçim',
      };

  bool get defaultMultiple => this == extra;
  bool get defaultRequired => this == portion;

  static VariantGroupType fromCode(String code) {
    for (final v in values) {
      if (v.name == code) return v;
    }
    return custom;
  }
}

enum VariantSelection {
  single,
  multiple;

  String get code => name;
  String get trLabel => switch (this) {
        single => 'Tekil seçim',
        multiple => 'Çoklu seçim',
      };

  static VariantSelection fromCode(String code) =>
      code == 'multiple' ? multiple : single;
}

class VariantOption {
  const VariantOption({
    required this.id,
    required this.groupId,
    required this.label,
    required this.priceModifierCents,
    required this.isDefault,
    required this.isAvailable,
    required this.sortOrder,
  });

  final String id;
  final String groupId;
  final String label;
  final int priceModifierCents; // signed cents
  final bool isDefault;
  final bool isAvailable;
  final int sortOrder;

  String get priceLabel {
    if (priceModifierCents == 0) return 'Ücretsiz';
    final sign = priceModifierCents > 0 ? '+' : '';
    final tl = (priceModifierCents / 100).toStringAsFixed(2);
    return '$sign₺$tl';
  }

  factory VariantOption.fromMap(Map<String, dynamic> m) => VariantOption(
        id: m['id'].toString(),
        groupId: m['group_id'].toString(),
        label: m['label'].toString(),
        priceModifierCents: (m['price_modifier_cents'] as num? ?? 0).toInt(),
        isDefault: m['is_default'] == true,
        isAvailable: m['is_available'] != false,
        sortOrder: (m['sort_order'] as num? ?? 0).toInt(),
      );
}

class VariantGroup {
  const VariantGroup({
    required this.id,
    required this.itemId,
    required this.name,
    required this.groupType,
    required this.selection,
    required this.isRequired,
    required this.sortOrder,
    required this.options,
  });

  final String id;
  final String itemId;
  final String name;
  final VariantGroupType groupType;
  final VariantSelection selection;
  final bool isRequired;
  final int sortOrder;
  final List<VariantOption> options;

  factory VariantGroup.fromMap(
    Map<String, dynamic> m,
    List<VariantOption> options,
  ) =>
      VariantGroup(
        id: m['id'].toString(),
        itemId: m['item_id'].toString(),
        name: m['name'].toString(),
        groupType: VariantGroupType.fromCode(m['group_type']?.toString() ?? 'custom'),
        selection: VariantSelection.fromCode(m['selection']?.toString() ?? 'single'),
        isRequired: m['is_required'] == true,
        sortOrder: (m['sort_order'] as num? ?? 0).toInt(),
        options: options,
      );
}
