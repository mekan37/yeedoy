import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/owner_claim_repository.dart';

enum OwnerClaimStatus { idle, loading, success, error }

class OwnerClaimState {
  const OwnerClaimState({
    required this.status,
    this.errorCode,
    this.message,
  });

  final OwnerClaimStatus status;
  final String? errorCode;
  final String? message;

  factory OwnerClaimState.idle() => const OwnerClaimState(status: OwnerClaimStatus.idle);

  OwnerClaimState copyWith({
    OwnerClaimStatus? status,
    String? errorCode,
    String? message,
  }) {
    return OwnerClaimState(
      status: status ?? this.status,
      errorCode: errorCode,
      message: message,
    );
  }
}

final ownerClaimControllerProvider =
    NotifierProvider.family<OwnerClaimController, OwnerClaimState, String>(
        OwnerClaimController.new);

class OwnerClaimController extends Notifier<OwnerClaimState> {
  OwnerClaimController(this.businessId);
  final String businessId;

  @override
  OwnerClaimState build() => OwnerClaimState.idle();

  Future<OwnerClaimResult> submit({
    required String fullName,
    required String phone,
    String? evidenceUrl,
    String? note,
  }) async {
    state = state.copyWith(status: OwnerClaimStatus.loading, errorCode: null, message: null);

    try {
      final repo = ref.read(ownerClaimRepositoryProvider);
      final res = await repo.submitClaim(
        businessId: businessId,
        fullName: fullName,
        phone: phone,
        evidenceUrl: evidenceUrl,
        note: note,
      );
      if (res.ok) {
        state = state.copyWith(status: OwnerClaimStatus.success);
        return res;
      }
      state = state.copyWith(
        status: OwnerClaimStatus.error,
        errorCode: res.error,
        message: res.error,
      );
      return res;
    } catch (e) {
      state = state.copyWith(status: OwnerClaimStatus.error, message: e.toString());
      return const OwnerClaimResult(ok: false, error: 'unknown');
    }
  }
}
