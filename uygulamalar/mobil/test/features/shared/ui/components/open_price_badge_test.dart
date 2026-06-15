import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/shared/ui/components/open_price_badge.dart';

void main() {
  group('priceLevelSymbol', () {
    test('returns ₺ for budget priceLevel regardless of cents', () {
      expect(priceLevelSymbol('budget', 99999), '₺');
    });

    test('returns ₺₺ for mid priceLevel', () {
      expect(priceLevelSymbol('mid', null), '₺₺');
    });

    test('returns ₺₺₺ for premium priceLevel', () {
      expect(priceLevelSymbol('premium', 1000), '₺₺₺');
    });

    test('falls back to cents thresholds when priceLevel is null', () {
      expect(priceLevelSymbol(null, 15000), '₺');
      expect(priceLevelSymbol(null, 30000), '₺₺');
      expect(priceLevelSymbol(null, 50000), '₺₺₺');
    });

    test('returns null when priceLevel and cents are both absent', () {
      expect(priceLevelSymbol(null, null), isNull);
      expect(priceLevelSymbol(null, 0), isNull);
    });

    test('falls back to cents when priceLevel is unrecognised', () {
      expect(priceLevelSymbol('unknown', 15000), '₺');
    });
  });
}
