import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/core/config/feature_flags.dart';
import 'package:yeedoy/features/menus/ui/public_menu_share_page.dart';

void main() {
  group('shouldLogQrAutoCheckin', () {
    test('is disabled by default for QR menu opens', () {
      final flags = FeatureFlagsState.empty();

      expect(
        shouldLogQrAutoCheckin(
          flags: flags,
          source: 'qr',
          businessId: '11111111-1111-4111-8111-111111111111',
        ),
        isFalse,
      );
    });

    test('requires enabled flag, qr source, and a business id', () {
      const flags = FeatureFlagsState(
        localFlags: {'enableQrAutoCheckin': true},
      );

      expect(
        shouldLogQrAutoCheckin(
          flags: flags,
          source: 'qr',
          businessId: '11111111-1111-4111-8111-111111111111',
        ),
        isTrue,
      );
      expect(
        shouldLogQrAutoCheckin(
          flags: flags,
          source: 'share',
          businessId: '11111111-1111-4111-8111-111111111111',
        ),
        isFalse,
      );
      expect(
        shouldLogQrAutoCheckin(flags: flags, source: 'qr', businessId: ''),
        isFalse,
      );
    });
  });
}
