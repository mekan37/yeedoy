import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/monetization/domain/sponsored_businesses_provider.dart';

void main() {
  test('sponsoredDiscoveryParams builds discovery scoped params', () {
    final params = sponsoredDiscoveryParams(
      city: 'Ankara',
      district: 'Çankaya',
      category: 'Kebap',
      limit: 3,
    );

    expect(params.surface, 'discovery');
    expect(params.city, 'Ankara');
    expect(params.district, 'Çankaya');
    expect(params.category, 'Kebap');
    expect(params.limit, 3);
  });
}
