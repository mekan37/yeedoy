import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/network/supabase_provider.dart';
import 'legal_models.dart';

final legalRepositoryProvider = Provider<LegalRepository>((ref) {
  return LegalRepository(ref.watch(supabaseProvider));
});

class LegalRepository {
  LegalRepository(this._supabase);

  final SupabaseClient _supabase;

  static const _openPrivacyStatuses = <String>['submitted', 'in_review'];
  static const _openAccountDeletionStatuses = <String>[
    'requested',
    'in_review',
  ];

  Future<PolicyAcceptanceSnapshot?> loadAcceptanceSnapshot() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return null;

    final versionRows = await _supabase
        .from('policy_versions')
        .select('id,policy_type,version_label,published_at')
        .eq('is_active', true)
        .inFilter('policy_type', PolicyAcceptanceSnapshot.requiredTypes);
    final versions = (versionRows as List? ?? const [])
        .whereType<Map>()
        .map((row) => PolicyVersionRecord.fromMap(row.cast<String, dynamic>()))
        .toList();
    final activeVersions = <String, PolicyVersionRecord>{
      for (final version in versions) version.policyType: version,
    };
    final hasAllRequiredPolicies = PolicyAcceptanceSnapshot.requiredTypes.every(
      activeVersions.containsKey,
    );
    if (!hasAllRequiredPolicies) {
      throw Exception('legal_policy_versions_missing');
    }

    final acceptedVersionIds = <String>{};
    if (versions.isNotEmpty) {
      final acceptedRows = await _supabase
          .from('user_policy_acceptances')
          .select('policy_version_id')
          .eq('user_id', uid)
          .inFilter(
            'policy_version_id',
            versions.map((version) => version.id).toList(),
          );
      for (final row in (acceptedRows as List? ?? const []).whereType<Map>()) {
        final id = (row['policy_version_id'] ?? '').toString();
        if (id.isNotEmpty) acceptedVersionIds.add(id);
      }
    }

    return PolicyAcceptanceSnapshot(
      activeVersions: activeVersions,
      acceptedVersionIds: acceptedVersionIds,
    );
  }

  Future<void> acceptPolicyVersions(
    List<PolicyVersionRecord> versions, {
    String sourceApp = 'mobile_flutter',
  }) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null || versions.isEmpty) return;

    final uniqueVersions = <String, PolicyVersionRecord>{
      for (final version in versions) version.id: version,
    }.values.toList();
    final now = DateTime.now().toUtc().toIso8601String();
    await _supabase.from('user_policy_acceptances').upsert(
      uniqueVersions
          .map(
            (version) => <String, dynamic>{
              'user_id': uid,
              'policy_version_id': version.id,
              'accepted_at': now,
              'source_app': sourceApp,
              'user_agent': _buildUserAgent(),
            },
          )
          .toList(),
      onConflict: 'user_id,policy_version_id',
      ignoreDuplicates: true,
    );
  }

  Future<LegalRequestOverview?> loadRequestOverview() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return null;

    final privacyRequest = await _loadLatestOpenRequest(
      table: 'privacy_requests',
      userId: uid,
      statusColumn: 'status',
      openStatuses: _openPrivacyStatuses,
      timestampColumn: 'submitted_at',
    );
    final accountDeletionRequest = await _loadLatestOpenRequest(
      table: 'account_deletion_requests',
      userId: uid,
      statusColumn: 'status',
      openStatuses: _openAccountDeletionStatuses,
      timestampColumn: 'requested_at',
    );

    return LegalRequestOverview(
      privacyRequest: privacyRequest,
      accountDeletionRequest: accountDeletionRequest,
    );
  }

  Future<void> submitPrivacyRequest({
    required String requestType,
    required String details,
  }) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('auth_required');
    }

    await _ensureNoOpenRequest(
      table: 'privacy_requests',
      userId: uid,
      openStatuses: _openPrivacyStatuses,
      duplicateError: 'privacy_request_already_open',
    );
    await _supabase.from('privacy_requests').insert(<String, dynamic>{
      'user_id': uid,
      'request_type': requestType,
      'status': 'submitted',
      'details': details.trim(),
      'submitted_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> submitAccountDeletionRequest({required String reason}) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('auth_required');
    }

    await _ensureNoOpenRequest(
      table: 'account_deletion_requests',
      userId: uid,
      openStatuses: _openAccountDeletionStatuses,
      duplicateError: 'account_deletion_request_already_open',
    );
    await _supabase.from('account_deletion_requests').insert(<String, dynamic>{
      'user_id': uid,
      'reason': reason.trim(),
      'status': 'requested',
      'requested_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> _ensureNoOpenRequest({
    required String table,
    required String userId,
    required List<String> openStatuses,
    required String duplicateError,
  }) async {
    final rows = await _supabase
        .from(table)
        .select('id')
        .eq('user_id', userId)
        .inFilter('status', openStatuses)
        .limit(1);
    final hasOpenRequest = (rows as List? ?? const []).isNotEmpty;
    if (hasOpenRequest) {
      throw Exception(duplicateError);
    }
  }

  Future<LegalRequestRecord?> _loadLatestOpenRequest({
    required String table,
    required String userId,
    required String statusColumn,
    required List<String> openStatuses,
    required String timestampColumn,
  }) async {
    final rows = await _supabase
        .from(table)
        .select('id,status,$timestampColumn')
        .eq('user_id', userId)
        .inFilter(statusColumn, openStatuses)
        .order(timestampColumn, ascending: false)
        .limit(1);
    for (final row in (rows as List? ?? const []).whereType<Map>()) {
      return LegalRequestRecord.fromMap(
        row.cast<String, dynamic>(),
        timestampKey: timestampColumn,
      );
    }
    return null;
  }

  String _buildUserAgent() {
    final platform = defaultTargetPlatform.name;
    return 'yeedoy-mobile/$platform';
  }
}
