import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/owner_custom_domain_repository.dart';
import 'owner_custom_domain_models.dart';

final ownerCustomDomainControllerProvider = NotifierProvider.family<
    OwnerCustomDomainController, CustomDomainState, String>(
  OwnerCustomDomainController.new,
);

class OwnerCustomDomainController extends Notifier<CustomDomainState> {
  OwnerCustomDomainController(this._businessId);
  final String _businessId;

  @override
  CustomDomainState build() {
    Future.microtask(_load);
    return const CustomDomainState(isLoading: true);
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final info = await _repo.fetchDomain(_businessId);
      state = state.copyWith(isLoading: false, info: () => info);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: () => e);
    }
  }

  Future<void> refresh() => _load();

  Future<String?> saveDomain(String domain) async {
    state = state.copyWith(
        isSaving: true, error: () => null, message: () => null);
    try {
      final info = await _repo.upsertDomain(
          businessId: _businessId, domain: domain);
      state = state.copyWith(
        isSaving: false,
        info: () => info,
        message: () => 'Domain kaydedildi. DNS TXT kaydını ekleyip doğrulayın.',
      );
      return null;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: () => e);
      return e.toString();
    }
  }

  Future<String?> verifyDomain() async {
    final domain = state.info?.domain;
    if (domain == null) return 'Domain bulunamadı.';
    state = state.copyWith(
        isVerifying: true, error: () => null, message: () => null);
    try {
      final verified = await _repo.verifyDomain(
          businessId: _businessId, domain: domain);
      if (verified) {
        state = state.copyWith(isVerifying: false,
            message: () => 'Domain başarıyla doğrulandı!');
        await _load();
      } else {
        state = state.copyWith(
          isVerifying: false,
          error: () => Exception('DNS TXT kaydı bulunamadı. '
              'Kaydı ekledikten sonra tekrar deneyin (yayılma 5-30 dk sürebilir).'),
        );
      }
      return null;
    } catch (e) {
      state = state.copyWith(isVerifying: false, error: () => e);
      return e.toString();
    }
  }

  Future<String?> deleteDomain() async {
    state = state.copyWith(
        isSaving: true, error: () => null, message: () => null);
    try {
      await _repo.deleteDomain(_businessId);
      state = state.copyWith(
        isSaving: false,
        info: () => null,
        message: () => 'Özel domain kaldırıldı.',
      );
      return null;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: () => e);
      return e.toString();
    }
  }

  OwnerCustomDomainRepository get _repo =>
      ref.read(ownerCustomDomainRepositoryProvider);
}
