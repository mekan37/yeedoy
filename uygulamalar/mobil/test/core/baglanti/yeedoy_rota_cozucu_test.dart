import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/core/baglanti/yeedoy_rota_cozucu.dart';

void main() {
  group('resolveYeedoyRouteFromQr', () {
    test('resolves app deep link menu route with qr source', () {
      final route = resolveYeedoyRouteFromQr(
        'yeedoy://menu/22222222-2222-4222-8222-222222222222',
      );
      expect(route, '/menu/22222222-2222-4222-8222-222222222222?src=qr');
    });

    test('resolves business route from https web url', () {
      final route = resolveYeedoyRouteFromQr(
        'https://yeedoy.com/isletme/11111111-1111-4111-8111-111111111111',
      );
      expect(route, '/isletme/11111111-1111-4111-8111-111111111111');
    });

    test('resolves business menu route from app deep link', () {
      final route = resolveYeedoyRouteFromQr(
        'yeedoy://isletme/11111111-1111-4111-8111-111111111111/menu/22222222-2222-4222-8222-222222222222',
      );
      expect(
        route,
        '/isletme/11111111-1111-4111-8111-111111111111/menu/22222222-2222-4222-8222-222222222222',
      );
    });

    test('returns null for non-yeedoy host', () {
      final route = resolveYeedoyRouteFromQr(
        'https://example.com/menu/22222222-2222-4222-8222-222222222222',
      );
      expect(route, isNull);
    });
  });
}

