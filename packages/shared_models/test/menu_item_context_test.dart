import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy_shared_models/yeedoy_shared_models.dart';

void main() {
  group('MenuItemContext.fromMap', () {
    test('parses a fully populated map with snake_case keys', () {
      final context = MenuItemContext.fromMap({
        'ok': true,
        'menu_id': 'menu-1',
        'business_id': 'biz-1',
        'allergens': ['gluten', 'süt'],
        'calories_min': 350,
        'portion_size': '350 g',
        'ingredients': ['un', 'süt', 'yumurta'],
      });

      expect(context.ok, isTrue);
      expect(context.menuId, 'menu-1');
      expect(context.businessId, 'biz-1');
      expect(context.allergens, ['gluten', 'süt']);
      expect(context.caloriesMin, 350);
      expect(context.portionSize, '350 g');
      expect(context.ingredients, ['un', 'süt', 'yumurta']);
    });

    test('falls back to camelCase keys when snake_case is absent', () {
      final context = MenuItemContext.fromMap({
        'ok': false,
        'menuId': 'menu-2',
        'businessId': 'biz-2',
      });

      expect(context.menuId, 'menu-2');
      expect(context.businessId, 'biz-2');
    });

    test('applies defaults for missing optional fields', () {
      final context = MenuItemContext.fromMap({
        'ok': true,
        'menu_id': 'menu-3',
        'business_id': 'biz-3',
      });

      expect(context.allergens, isEmpty);
      expect(context.caloriesMin, isNull);
      expect(context.portionSize, isNull);
      expect(context.ingredients, isEmpty);
    });

    test('ok defaults to false when boolean-like value is unparseable', () {
      final context = MenuItemContext.fromMap({
        'menu_id': 'menu-4',
        'business_id': 'biz-4',
      });

      expect(context.ok, isFalse);
    });
  });

  group('copyWith', () {
    test('overrides only provided fields', () {
      final original = MenuItemContext(
        ok: true,
        menuId: 'menu-1',
        businessId: 'biz-1',
        allergens: const ['gluten'],
      );

      final updated = original.copyWith(portionSize: '200 g');

      expect(updated.ok, original.ok);
      expect(updated.menuId, original.menuId);
      expect(updated.allergens, original.allergens);
      expect(updated.portionSize, '200 g');
    });
  });

  group('equality', () {
    test('two contexts with identical fields are equal', () {
      MenuItemContext build() => MenuItemContext(
            ok: true,
            menuId: 'menu-1',
            businessId: 'biz-1',
            allergens: const ['gluten'],
            ingredients: const ['un'],
          );

      expect(build(), build());
      expect(build().hashCode, build().hashCode);
    });

    test('contexts with different allergen lists are not equal', () {
      final a = MenuItemContext(
        ok: true,
        menuId: 'menu-1',
        businessId: 'biz-1',
        allergens: const ['gluten'],
      );
      final b = a.copyWith(allergens: const ['süt']);

      expect(a, isNot(b));
    });
  });
}
