import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/kesif_deposu.dart';

final cityDistrictsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(discoveryRepositoryProvider).fetchCityDistricts();
});


