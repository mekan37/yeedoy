import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/core/security/route_sanitizer.dart';

void main() {
  group('sanitizeInternalRedirect', () {
    test('guvenli internal pathleri kabul eder', () {
      final encoded = Uri.encodeComponent('/owner/menus?businessId=abc');
      expect(sanitizeInternalRedirect(encoded), '/owner/menus?businessId=abc');
    });

    test('harici url, login ve bozuk pathleri reddeder', () {
      expect(
        sanitizeInternalRedirect(Uri.encodeComponent('https://evil.com')),
        isNull,
      );
      expect(sanitizeInternalRedirect(Uri.encodeComponent('//evil.com')), isNull);
      expect(sanitizeInternalRedirect(Uri.encodeComponent('/login')), isNull);
      expect(sanitizeInternalRedirect('%%%broken%%%'), isNull);
    });
  });

  group('sanitizeUuid', () {
    test('gecerli uuid dondurur, gecersiz girdiyi null yapar', () {
      const valid = '8f14e45f-ea53-4123-a789-0be0c0ffee12';
      expect(sanitizeUuid(valid), valid);
      expect(sanitizeUuid('not-uuid'), isNull);
      expect(sanitizeUuid(''), isNull);
    });
  });
}
