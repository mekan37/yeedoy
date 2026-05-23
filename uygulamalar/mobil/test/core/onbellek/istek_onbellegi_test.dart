import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/core/onbellek/istek_onbellegi.dart';

void main() {
  group('RequestCache', () {
    test('scopes are isolated', () {
      final cache = RequestCache();
      final discovery = cache.scope('discovery');
      final menus = cache.scope('menus');

      discovery.set('k', 'v1');
      menus.set('k', 'v2');

      expect(discovery.getStale<String>('k'), 'v1');
      expect(menus.getStale<String>('k'), 'v2');
    });

    test('scope prefix invalidation removes only scoped keys', () {
      final cache = RequestCache();
      final discovery = cache.scope('discovery');
      final menus = cache.scope('menus');

      discovery.set('a|1', 1);
      discovery.set('a|2', 2);
      menus.set('a|1', 3);

      discovery.invalidatePrefix('a|');

      expect(discovery.getStale<int>('a|1'), isNull);
      expect(discovery.getStale<int>('a|2'), isNull);
      expect(menus.getStale<int>('a|1'), 3);
    });

    test('stableRequestCacheKey is deterministic with map order', () {
      final k1 = stableRequestCacheKey('search', {
        'q': 'kebap',
        'city': 'Ankara',
      });
      final k2 = stableRequestCacheKey('search', {
        'city': 'Ankara',
        'q': 'kebap',
      });
      expect(k1, k2);
    });
  });
}
