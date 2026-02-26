import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/auth_providers.dart';
import '../data/suggestions_repo.dart';
import 'suggestion.dart';

final mySuggestionsProvider = FutureProvider<List<BusinessSuggestion>>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return [];
  return ref.read(suggestionsRepoProvider).listMySuggestions();
});
