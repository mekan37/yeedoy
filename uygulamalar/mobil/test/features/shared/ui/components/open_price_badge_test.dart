import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/shared/ui/components/open_price_badge.dart';

void main() {
  group('priceLevelSymbol', () {
    // When a positive `cents` (median/average menu price) is supplied, it
    // always wins over `priceLevel` and renders an approximate amount like
    // "~₺85" — see the doc comment on priceLevelSymbol().
    test('returns an approximate amount when cents is positive, even with a priceLevel', () {
      expect(priceLevelSymbol('budget', 99999), '~₺1000');
    });

    test('returns ₺₺ for mid priceLevel when cents is absent', () {
      expect(priceLevelSymbol('mid', null), '₺₺');
    });

    test('returns an approximate amount when cents is positive, regardless of premium priceLevel', () {
      expect(priceLevelSymbol('premium', 1000), '~₺10');
    });

    test('falls back to cents-derived approximate amount when priceLevel is null', () {
      expect(priceLevelSymbol(null, 15000), '~₺150');
      expect(priceLevelSymbol(null, 30000), '~₺300');
      expect(priceLevelSymbol(null, 50000), '~₺500');
    });

    test('returns null when priceLevel and cents are both absent', () {
      expect(priceLevelSymbol(null, null), isNull);
      expect(priceLevelSymbol(null, 0), isNull);
    });

    test('falls back to cents-derived approximate amount when priceLevel is unrecognised', () {
      expect(priceLevelSymbol('unknown', 15000), '~₺150');
    });

    test('falls back to priceLevel tier symbol when cents is null or non-positive', () {
      expect(priceLevelSymbol('budget', null), '₺');
      expect(priceLevelSymbol('premium', 0), '₺₺₺');
    });

    test('returns null when priceLevel is unrecognised and cents is absent', () {
      expect(priceLevelSymbol('unknown', null), isNull);
    });
  });
}
