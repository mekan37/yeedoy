import 'dart:collection';

import 'package:flutter/foundation.dart';

class LegalPolicyType {
  const LegalPolicyType._();

  static const terms = 'terms';
  static const privacy = 'privacy';
  static const cookies = 'cookies';
  static const community = 'community';
  static const business = 'business';
  static const copyright = 'copyright';
  static const ai = 'ai';
  static const dmca = 'dmca';
  static const dsa = 'dsa';
  static const dataSafety = 'data-safety';
  static const trustSafety = 'trust-safety';
  static const security = 'security';
  static const lawEnforcement = 'law-enforcement';
  static const deleteAccount = 'delete-account';

  static const requiredAcceptanceTypes = <String>[terms, privacy];
}

@immutable
class PolicyVersionRecord {
  const PolicyVersionRecord({
    required this.id,
    required this.policyType,
    required this.versionLabel,
    required this.publishedAt,
  });

  final String id;
  final String policyType;
  final String versionLabel;
  final DateTime publishedAt;

  factory PolicyVersionRecord.fromMap(Map<String, dynamic> map) {
    return PolicyVersionRecord(
      id: (map['id'] ?? '').toString(),
      policyType: (map['policy_type'] ?? '').toString(),
      versionLabel: (map['version_label'] ?? '').toString(),
      publishedAt:
          DateTime.tryParse((map['published_at'] ?? '').toString()) ??
          DateTime(2026, 3, 10),
    );
  }
}

@immutable
class PolicyAcceptanceSnapshot {
  factory PolicyAcceptanceSnapshot({
    required Map<String, PolicyVersionRecord> activeVersions,
    required Set<String> acceptedVersionIds,
  }) {
    return PolicyAcceptanceSnapshot._(
      activeVersions: UnmodifiableMapView<String, PolicyVersionRecord>(
        activeVersions,
      ),
      acceptedVersionIds: Set<String>.unmodifiable(acceptedVersionIds),
    );
  }

  const PolicyAcceptanceSnapshot._({
    required this.activeVersions,
    required this.acceptedVersionIds,
  });

  final Map<String, PolicyVersionRecord> activeVersions;
  final Set<String> acceptedVersionIds;

  static const List<String> requiredTypes =
      LegalPolicyType.requiredAcceptanceTypes;

  bool get requiresMandatoryAcceptance =>
      pendingRequiredVersions.isNotEmpty && activeVersions.isNotEmpty;

  List<PolicyVersionRecord> get pendingRequiredVersions {
    final result = <PolicyVersionRecord>[];
    for (final type in requiredTypes) {
      final version = activeVersions[type];
      if (version == null) continue;
      if (!acceptedVersionIds.contains(version.id)) {
        result.add(version);
      }
    }
    return List<PolicyVersionRecord>.unmodifiable(result);
  }
}

@immutable
class LegalRequestRecord {
  const LegalRequestRecord({
    required this.id,
    required this.status,
    required this.submittedAt,
  });

  final String id;
  final String status;
  final DateTime submittedAt;

  factory LegalRequestRecord.fromMap(
    Map<String, dynamic> map, {
    required String timestampKey,
  }) {
    return LegalRequestRecord(
      id: (map['id'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      submittedAt:
          DateTime.tryParse((map[timestampKey] ?? '').toString()) ??
          DateTime(2026, 3, 10),
    );
  }
}

@immutable
class LegalRequestOverview {
  const LegalRequestOverview({
    this.privacyRequest,
    this.accountDeletionRequest,
  });

  final LegalRequestRecord? privacyRequest;
  final LegalRequestRecord? accountDeletionRequest;

  bool get hasOpenPrivacyRequest => privacyRequest != null;
  bool get hasOpenAccountDeletionRequest => accountDeletionRequest != null;
}
