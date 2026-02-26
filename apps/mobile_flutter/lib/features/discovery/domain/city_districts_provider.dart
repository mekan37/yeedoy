import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/discovery_repository.dart';

final cityDistrictsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(discoveryRepositoryProvider).getCityDistricts();
});

