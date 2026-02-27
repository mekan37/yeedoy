import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminNewItemsState {
  const AdminNewItemsState({
    required this.reportsNew,
    required this.claimsNew,
    required this.suggestionsNew,
    required this.priceSuggestionsNew,
    required this.suspendedClaimsNew,
  });

  final int reportsNew;
  final int claimsNew;
  final int suggestionsNew;
  final int priceSuggestionsNew;
  final int suspendedClaimsNew;

  factory AdminNewItemsState.initial() => const AdminNewItemsState(
        reportsNew: 0,
        claimsNew: 0,
        suggestionsNew: 0,
        priceSuggestionsNew: 0,
        suspendedClaimsNew: 0,
      );

  AdminNewItemsState copyWith({
    int? reportsNew,
    int? claimsNew,
    int? suggestionsNew,
    int? priceSuggestionsNew,
    int? suspendedClaimsNew,
  }) {
    return AdminNewItemsState(
      reportsNew: reportsNew ?? this.reportsNew,
      claimsNew: claimsNew ?? this.claimsNew,
      suggestionsNew: suggestionsNew ?? this.suggestionsNew,
      priceSuggestionsNew: priceSuggestionsNew ?? this.priceSuggestionsNew,
      suspendedClaimsNew: suspendedClaimsNew ?? this.suspendedClaimsNew,
    );
  }
}

final adminNewItemsProvider =
    NotifierProvider<AdminNewItemsController, AdminNewItemsState>(
        AdminNewItemsController.new);

class AdminNewItemsController extends Notifier<AdminNewItemsState> {
  @override
  AdminNewItemsState build() => AdminNewItemsState.initial();

  void incReports() {
    state = state.copyWith(reportsNew: state.reportsNew + 1);
  }

  void incClaims() {
    state = state.copyWith(claimsNew: state.claimsNew + 1);
  }

  void incSuggestions() {
    state = state.copyWith(suggestionsNew: state.suggestionsNew + 1);
  }

  void incSuspendedClaims() {
    state = state.copyWith(suspendedClaimsNew: state.suspendedClaimsNew + 1);
  }

  void incPriceSuggestions() {
    state = state.copyWith(priceSuggestionsNew: state.priceSuggestionsNew + 1);
  }

  void clearReports() {
    state = state.copyWith(reportsNew: 0);
  }

  void clearClaims() {
    state = state.copyWith(claimsNew: 0);
  }

  void clearSuggestions() {
    state = state.copyWith(suggestionsNew: 0);
  }

  void clearPriceSuggestions() {
    state = state.copyWith(priceSuggestionsNew: 0);
  }

  void clearSuspendedClaims() {
    state = state.copyWith(suspendedClaimsNew: 0);
  }

  void clearAll() {
    state = AdminNewItemsState.initial();
  }
}
