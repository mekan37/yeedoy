import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/menus/data/ocr_price_extractor.dart';

void main() {
  group('parsePriceCents', () {
    test('parses integer values', () {
      expect(parsePriceCents('49'), 4900);
    });

    test('parses decimal values with dot', () {
      expect(parsePriceCents('49.5'), 4950);
    });

    test('parses decimal values with comma', () {
      expect(parsePriceCents('49,75'), 4975);
    });

    test('returns null for invalid or non-positive values', () {
      expect(parsePriceCents('0'), isNull);
      expect(parsePriceCents('-5'), isNull);
      expect(parsePriceCents('abc'), isNull);
    });
  });
}


