import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yeedoy/features/profile/domain/favorite_collections_count_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns 0 when no collections are saved', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final count = await container.read(
      myFavoriteCollectionsCountProvider.future,
    );

    expect(count, 0);
  });

  test('returns the number of saved favorite collections', () async {
    SharedPreferences.setMockInitialValues({
      'favorite_collections_v1': jsonEncode([
        {
          'id': 'col-1',
          'name': 'Kahvaltı Mekanları',
          'business_ids': ['biz-1', 'biz-2'],
          'created_at': '2026-01-01T00:00:00.000Z',
        },
        {
          'id': 'col-2',
          'name': 'Akşam Yemeği',
          'business_ids': ['biz-3'],
          'created_at': '2026-01-02T00:00:00.000Z',
        },
      ]),
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final count = await container.read(
      myFavoriteCollectionsCountProvider.future,
    );

    expect(count, 2);
  });
}
