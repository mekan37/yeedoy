import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../data/compare_repository.dart';
import 'compare_controller.dart';

export '../data/compare_repository.dart' show CompareBusiness;

final compareBusinessesProvider = FutureProvider.autoDispose<List<CompareBusiness>>((ref) async {
  final ids = ref.watch(compareControllerProvider);
  if (ids.isEmpty) return const [];

  final repository = ref.watch(compareRepositoryProvider);
  try {
    return await repository.getCompareBusinesses(ids);
  } catch (e) {
    throw Exception(AppErrorMapper.message(e));
  }
});
