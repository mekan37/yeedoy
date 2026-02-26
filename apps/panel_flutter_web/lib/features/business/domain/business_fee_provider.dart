import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../src/data/repositories/business_fee_repository.dart';
import 'business_fee_summary.dart';

final businessFeeSummaryProvider =
    FutureProvider.family<BusinessFeeSummary, String>((ref, businessId) async {
  return ref.watch(businessFeeRepositoryProvider).getFeeSummary(businessId);
});
