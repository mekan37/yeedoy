import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/core/assets/category_assets.dart';

void main() {
  group('CategoryAssets', () {
    test('resolves production Turkish business categories', () {
      expect(
        CategoryAssets.resolve('Kafe'),
        'assets/images/categories/cafe.webp',
      );
      expect(
        CategoryAssets.resolve('Restoran'),
        'assets/images/categories/restoran.webp',
      );
      expect(
        CategoryAssets.resolve('Tatlıcı'),
        'assets/images/categories/tatlici.webp',
      );
      expect(
        CategoryAssets.resolve('Kahvaltı'),
        'assets/images/categories/kahvalti.webp',
      );
      expect(
        CategoryAssets.resolve('Mekan'),
        'assets/images/categories/mekan.webp',
      );
    });

    test('resolves fish and meat variants to the combined category asset', () {
      expect(
        CategoryAssets.resolve('Balık / Et'),
        'assets/images/categories/balik-et.webp',
      );
      expect(
        CategoryAssets.resolve('balik'),
        'assets/images/categories/balik-et.webp',
      );
      expect(
        CategoryAssets.resolve('et'),
        'assets/images/categories/balik-et.webp',
      );
    });

    test('resolves aliases and unknown values safely', () {
      expect(
        CategoryAssets.resolve(' Cafe '),
        'assets/images/categories/cafe.webp',
      );
      expect(
        CategoryAssets.resolve('restaurant'),
        'assets/images/categories/restoran.webp',
      );
      expect(CategoryAssets.resolve('Oto Servis'), CategoryAssets.defaultAsset);
      expect(CategoryAssets.resolve(null), CategoryAssets.defaultAsset);
    });
  });
}
