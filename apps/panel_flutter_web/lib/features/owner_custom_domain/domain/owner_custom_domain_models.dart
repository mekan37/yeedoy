import 'package:flutter/foundation.dart';

@immutable
class CustomDomainInfo {
  const CustomDomainInfo({
    required this.domain,
    required this.dnsTxtToken,
    this.verifiedAt,
    required this.isActive,
  });

  final String domain;
  final String dnsTxtToken;
  final DateTime? verifiedAt;
  final bool isActive;

  bool get isVerified => verifiedAt != null;

  factory CustomDomainInfo.fromMap(Map<String, dynamic> m) => CustomDomainInfo(
        domain: m['domain'] as String,
        dnsTxtToken: m['dns_txt_token'] as String,
        verifiedAt: m['verified_at'] != null
            ? DateTime.parse(m['verified_at'] as String)
            : null,
        isActive: m['is_active'] as bool? ?? false,
      );
}

@immutable
class CustomDomainState {
  const CustomDomainState({
    this.info,
    this.isLoading = false,
    this.isSaving = false,
    this.isVerifying = false,
    this.error,
    this.message,
  });

  final CustomDomainInfo? info;
  final bool isLoading;
  final bool isSaving;
  final bool isVerifying;
  final Object? error;
  final String? message;

  CustomDomainState copyWith({
    CustomDomainInfo? Function()? info,
    bool? isLoading,
    bool? isSaving,
    bool? isVerifying,
    Object? Function()? error,
    String? Function()? message,
  }) =>
      CustomDomainState(
        info: info != null ? info() : this.info,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        isVerifying: isVerifying ?? this.isVerifying,
        error: error != null ? error() : this.error,
        message: message != null ? message() : this.message,
      );
}
