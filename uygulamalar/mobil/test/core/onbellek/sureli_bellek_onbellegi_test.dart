import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/core/onbellek/sureli_bellek_onbellegi.dart';

void main() {
  group('TtlMemoryCache', () {
    test('returns null for missing key', () {
      final cache = TtlMemoryCache();
      expect(
        cache.getFresh<String>('a', ttl: const Duration(minutes: 1)),
        isNull,
      );
    });

    test('returns fresh value within ttl', () {
      final cache = TtlMemoryCache();
      cache.set('k', 'v');
      expect(
        cache.getFresh<String>('k', ttl: const Duration(minutes: 1)),
        equals('v'),
      );
    });

    test('returns stale null for wrong type on getFresh', () {
      final cache = TtlMemoryCache();
      cache.set('k', 42);
      expect(
        cache.getFresh<String>('k', ttl: const Duration(minutes: 1)),
        isNull,
      );
    });

    test('returns stale value for matching type', () async {
      final cache = TtlMemoryCache();
      cache.set('k', 12);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      expect(cache.getStale<int>('k'), equals(12));
    });

    test('returns null for wrong type on getStale', () {
      final cache = TtlMemoryCache();
      cache.set('k', 'v');
      expect(cache.getStale<int>('k'), isNull);
    });

    test('expires value when ttl passed', () async {
      final cache = TtlMemoryCache();
      cache.set('k', 'v');
      await Future<void>.delayed(const Duration(milliseconds: 3));
      expect(
        cache.getFresh<String>('k', ttl: const Duration(milliseconds: 1)),
        isNull,
      );
      expect(cache.getStale<String>('k'), equals('v'));
    });

    test('invalidate removes one key', () {
      final cache = TtlMemoryCache();
      cache.set('a', 1);
      cache.set('b', 2);
      cache.invalidate('a');
      expect(cache.getStale<int>('a'), isNull);
      expect(cache.getStale<int>('b'), equals(2));
    });

    test('invalidatePrefix removes matching keys only', () {
      final cache = TtlMemoryCache();
      cache.set('menu|1', 1);
      cache.set('menu|2', 2);
      cache.set('business|1', 3);
      cache.invalidatePrefix('menu|');
      expect(cache.getStale<int>('menu|1'), isNull);
      expect(cache.getStale<int>('menu|2'), isNull);
      expect(cache.getStale<int>('business|1'), equals(3));
    });

    test('set overwrites existing value', () {
      final cache = TtlMemoryCache();
      cache.set('k', 1);
      cache.set('k', 2);
      expect(cache.getStale<int>('k'), equals(2));
    });

    test('prefix invalidation with no matches is safe', () {
      final cache = TtlMemoryCache();
      cache.set('k', 'v');
      cache.invalidatePrefix('x|');
      expect(cache.getStale<String>('k'), equals('v'));
    });
  });
}

