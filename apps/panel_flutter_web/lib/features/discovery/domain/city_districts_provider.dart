import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/discovery_repo.dart';

final cityDistrictsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(discoveryRepoProvider).getCityDistricts();
});
