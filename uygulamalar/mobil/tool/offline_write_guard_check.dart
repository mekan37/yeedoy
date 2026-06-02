import 'dart:io';

final _writeRpcPrefixes = <String>[
  'create_',
  'submit_',
  'set_',
  'toggle_',
  'upsert_',
  'accept_',
  'close_',
  'mark_',
  'delete_',
  'restore_',
  'vote_',
  'owner_update_',
  'bump_',
  'ensure_',
];

final _rpcRegistry = <String, _WriteClassification>{
  'accept_group_offer_v1': const _WriteClassification(
    strategy: 'direct_rpc_reviewed',
    requiresIdempotency: false,
    note: 'Offer lifecycle write; not queued today.',
  ),
  'bump_food_catalog_popularity_v1': const _WriteClassification(
    strategy: 'low_risk_side_effect',
    requiresIdempotency: false,
    note: 'Popularity bump is additive and low risk.',
  ),
  'close_group_request_v1': const _WriteClassification(
    strategy: 'direct_rpc_reviewed',
    requiresIdempotency: false,
    note: 'Request lifecycle write; not queued today.',
  ),
  'create_group_request_v1': const _WriteClassification(
    strategy: 'direct_rpc_reviewed',
    requiresIdempotency: false,
    note: 'Community creation flow; future queueing can be added if needed.',
  ),
  'create_price_alert_v1': const _WriteClassification(
    strategy: 'legacy_fallback',
    requiresIdempotency: false,
    note: 'Legacy fallback behind v2 idempotent path.',
  ),
  'create_price_alert_v2': const _WriteClassification(
    strategy: 'idempotent_rpc',
    requiresIdempotency: true,
    note: 'Explicit idempotency key required.',
  ),
  'ensure_my_profile_v1': const _WriteClassification(
    strategy: 'profile_bootstrap',
    requiresIdempotency: false,
    note: 'Profile bootstrap side effect.',
  ),
  'mark_all_notifications_read_v1': const _WriteClassification(
    strategy: 'desired_state_rpc',
    requiresIdempotency: false,
    note: 'Bulk mark-read is safe to repeat.',
  ),
  'mark_notification_read_v1': const _WriteClassification(
    strategy: 'desired_state_rpc',
    requiresIdempotency: false,
    note: 'Mark-read is safe to repeat.',
  ),
  'owner_update_business_amenities_v1': const _WriteClassification(
    strategy: 'owner_write_reviewed',
    requiresIdempotency: false,
    note: 'Owner/admin managed write; not part of mobile consumer queue.',
  ),
  'restore_notification_v1': const _WriteClassification(
    strategy: 'desired_state_rpc',
    requiresIdempotency: false,
    note: 'Restore action is safe to repeat.',
  ),
  'set_favorite_v2': const _WriteClassification(
    strategy: 'idempotent_rpc',
    requiresIdempotency: true,
    note: 'Desired-state favorite write.',
  ),
  'set_follow_v2': const _WriteClassification(
    strategy: 'idempotent_rpc',
    requiresIdempotency: true,
    note: 'Desired-state follow write.',
  ),
  'set_group_offer_vote_v2': const _WriteClassification(
    strategy: 'idempotent_rpc',
    requiresIdempotency: true,
    note: 'Desired-state group offer vote.',
  ),
  'set_menu_item_photo_vote_v2': const _WriteClassification(
    strategy: 'idempotent_rpc',
    requiresIdempotency: true,
    note: 'Desired-state photo vote.',
  ),
  'set_menu_item_price_vote_v2': const _WriteClassification(
    strategy: 'idempotent_rpc',
    requiresIdempotency: true,
    note: 'Desired-state price vote.',
  ),
  'submit_business_suggestion_v2': const _WriteClassification(
    strategy: 'idempotent_rpc',
    requiresIdempotency: true,
    note: 'Queued + idempotent business suggestion write.',
  ),
  'submit_group_offer_v1': const _WriteClassification(
    strategy: 'direct_rpc_reviewed',
    requiresIdempotency: false,
    note: 'Offer creation flow; review if moved to offline queue.',
  ),
  'submit_menu_item_price_suggestion_v2': const _WriteClassification(
    strategy: 'legacy_fallback',
    requiresIdempotency: false,
    note: 'Legacy fallback for older projects.',
  ),
  'submit_menu_item_price_suggestion_v5': const _WriteClassification(
    strategy: 'idempotent_rpc',
    requiresIdempotency: true,
    note: 'Queued + idempotent price suggestion write.',
  ),
  'submit_menu_item_suggestion_v1': const _WriteClassification(
    strategy: 'legacy_fallback',
    requiresIdempotency: false,
    note: 'Legacy fallback for older projects.',
  ),
  'submit_menu_item_suggestion_v2': const _WriteClassification(
    strategy: 'idempotent_rpc',
    requiresIdempotency: true,
    note: 'Queued + idempotent menu suggestion write.',
  ),
  'submit_presence_v1': const _WriteClassification(
    strategy: 'legacy_fallback',
    requiresIdempotency: false,
    note: 'Legacy fallback behind v2 idempotent path.',
  ),
  'submit_presence_v2': const _WriteClassification(
    strategy: 'idempotent_rpc',
    requiresIdempotency: true,
    note: 'Time-windowed presence write.',
  ),
  'submit_report_v2': const _WriteClassification(
    strategy: 'idempotent_rpc',
    requiresIdempotency: true,
    note: 'Queued + idempotent report write.',
  ),
  'submit_review_v2': const _WriteClassification(
    strategy: 'idempotent_rpc',
    requiresIdempotency: true,
    note: 'Queued + idempotent review write.',
  ),
  'toggle_follow_v1': const _WriteClassification(
    strategy: 'legacy_fallback',
    requiresIdempotency: false,
    note: 'Legacy fallback behind desired-state v2.',
  ),
  'upsert_my_diet_profile_v1': const _WriteClassification(
    strategy: 'profile_state_write',
    requiresIdempotency: false,
    note: 'User-owned profile preference write.',
  ),
  'upsert_user_location_prefs_v1': const _WriteClassification(
    strategy: 'profile_state_write',
    requiresIdempotency: false,
    note: 'User-owned location preference upsert; safe to repeat.',
  ),
  'vote_group_offer_v1': const _WriteClassification(
    strategy: 'legacy_fallback',
    requiresIdempotency: false,
    note: 'Legacy fallback behind desired-state v2.',
  ),
  'toggle_favorite_v1': const _WriteClassification(
    strategy: 'legacy_fallback',
    requiresIdempotency: false,
    note: 'Legacy toggle; desired-state path preferred.',
  ),
  'upsert_collection_share_v1': const _WriteClassification(
    strategy: 'direct_rpc_reviewed',
    requiresIdempotency: false,
    note: 'Collection share upsert; reviewed for idempotency.',
  ),
  'toggle_collection_follow_v1': const _WriteClassification(
    strategy: 'direct_rpc_reviewed',
    requiresIdempotency: false,
    note: 'Collection follow toggle; not queued today.',
  ),
  'bump_collection_engagement_v1': const _WriteClassification(
    strategy: 'low_risk_side_effect',
    requiresIdempotency: false,
    note: 'Engagement counter bump; additive and low risk.',
  ),
  'submit_review_v3': const _WriteClassification(
    strategy: 'idempotent_rpc',
    requiresIdempotency: true,
    note: 'Queued + idempotent review write v3.',
  ),
  'submit_table_feedback_v1': const _WriteClassification(
    strategy: 'direct_rpc_reviewed',
    requiresIdempotency: false,
    note: 'In-restaurant table feedback; one-off write.',
  ),
  'submit_menu_item_price_suggestion_v3': const _WriteClassification(
    strategy: 'legacy_fallback',
    requiresIdempotency: false,
    note: 'Legacy fallback; v5 is the idempotent path.',
  ),
  'submit_receipt_submission_v1': const _WriteClassification(
    strategy: 'direct_rpc_reviewed',
    requiresIdempotency: false,
    note: 'Receipt/OCR submission; reviewed for replay safety.',
  ),
  'vote_menu_item_price_v1': const _WriteClassification(
    strategy: 'legacy_fallback',
    requiresIdempotency: false,
    note: 'Legacy price vote; desired-state v2 preferred.',
  ),
  'upsert_collab_vote_v1': const _WriteClassification(
    strategy: 'desired_state_rpc',
    requiresIdempotency: false,
    note: 'Collab list vote upsert; desired-state write, safe to repeat.',
  ),
  'submit_table_order_v1': const _WriteClassification(
    strategy: 'direct_rpc_reviewed',
    requiresIdempotency: false,
    note: 'In-restaurant table order submit; reviewed for replay safety.',
  ),
  'vote_menu_item_photo_v1': const _WriteClassification(
    strategy: 'legacy_fallback',
    requiresIdempotency: false,
    note: 'Legacy photo vote; desired-state v2 preferred.',
  ),
};

final _directWriteRegistry = <String, _DirectWriteClassification>{
  'embeds': const _DirectWriteClassification(
    note: 'Owner/admin managed content write.',
  ),
  'favorites': const _DirectWriteClassification(
    note: 'Legacy fallback behind set_favorite_v2.',
  ),
  'group_offer_votes': const _DirectWriteClassification(
    note: 'Legacy fallback behind set_group_offer_vote_v2.',
  ),
  'menu_item_photo_votes': const _DirectWriteClassification(
    note: 'Legacy fallback behind set_menu_item_photo_vote_v2.',
  ),
  'menu_item_price_votes': const _DirectWriteClassification(
    note: 'Legacy fallback behind set_menu_item_price_vote_v2.',
  ),
  'price_alerts': const _DirectWriteClassification(
    note: 'Alert delete/update path; review with price_alert RPC changes.',
  ),
  'temp_uploads': const _DirectWriteClassification(
    note: 'Temp upload staging write.',
  ),
  'user_follows': const _DirectWriteClassification(
    note: 'Legacy fallback behind set_follow_v2.',
  ),
  'user_profiles': const _DirectWriteClassification(
    note: 'User-owned profile upsert.',
  ),
  'user_policy_acceptances': const _DirectWriteClassification(
    note: 'Legal consent write; KVKK required, one-off per policy version.',
  ),
  'privacy_requests': const _DirectWriteClassification(
    note: 'KVKK privacy request insert; one-off, not queued.',
  ),
  'account_deletion_requests': const _DirectWriteClassification(
    note: 'Account deletion request insert; one-off, not queued.',
  ),
  'business_ownership_claims': const _DirectWriteClassification(
    note: 'Business claim insert; one-off owner flow, not queued.',
  ),
  'collab_lists': const _DirectWriteClassification(
    note: 'Collab list create/delete; user-initiated, not queued.',
  ),
  'collab_list_items': const _DirectWriteClassification(
    note: 'Collab list item insert/delete; user-initiated, not queued.',
  ),
  'collab_list_members': const _DirectWriteClassification(
    note: 'Collab list member delete; user-initiated, not queued.',
  ),
  'collab_list_votes': const _DirectWriteClassification(
    note: 'Collab list vote delete; user-initiated, not queued.',
  ),
  'temp': const _DirectWriteClassification(
    note: 'Temp upload staging in storage bucket; not a DB table write.',
  ),
};

final _rpcPattern = RegExp(r"\.rpc\(\s*'([A-Za-z0-9_]+)'", multiLine: true);
final _directWritePattern = RegExp(
  r"\.from\(\s*'([A-Za-z0-9_]+)'\s*\)(?:[\s\S]{0,240}?)\.(insert|upsert|update|delete)\(",
  multiLine: true,
);

Future<void> main() async {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln('OFFLINE_WRITE_GUARD: BLOCK');
    stderr.writeln('- lib directory not found');
    exitCode = 1;
    return;
  }

  final findings = <String>[];
  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList(growable: false);

  for (final file in files) {
    final content = await file.readAsString();

    for (final match in _rpcPattern.allMatches(content)) {
      final rpcName = match.group(1);
      if (rpcName == null || !_looksLikeWriteRpc(rpcName)) {
        continue;
      }
      final classification = _rpcRegistry[rpcName];
      if (classification == null) {
        findings.add(
          '${file.path}: unclassified write rpc `$rpcName`; add it to offline_write_guard_check.dart before merge.',
        );
        continue;
      }
      if (classification.requiresIdempotency &&
          !_fileCarriesIdempotencySignals(content)) {
        findings.add(
          '${file.path}: `$rpcName` is classified as idempotent but idempotency markers were not found.',
        );
      }
    }

    for (final match in _directWritePattern.allMatches(content)) {
      final table = match.group(1);
      final op = match.group(2);
      if (table == null || op == null) continue;
      if (_directWriteRegistry[table] == null) {
        findings.add(
          '${file.path}: unclassified direct `$op` write on `$table`; review replay/idempotency implications before merge.',
        );
      }
    }
  }

  if (findings.isEmpty) {
    stdout.writeln('OFFLINE_WRITE_GUARD: PASS');
    stdout.writeln(
      'Checked ${files.length} Dart files, ${_rpcRegistry.length} RPC write contracts, ${_directWriteRegistry.length} direct-write classifications.',
    );
    return;
  }

  stdout.writeln('OFFLINE_WRITE_GUARD: BLOCK');
  for (final finding in findings) {
    stdout.writeln('- $finding');
  }
  exitCode = 1;
}

bool _looksLikeWriteRpc(String rpcName) {
  return _writeRpcPrefixes.any(rpcName.startsWith);
}

bool _fileCarriesIdempotencySignals(String content) {
  return content.contains('buildMutationIdempotencyToken(') ||
      content.contains('p_idempotency_key') ||
      content.contains('idempotency_key');
}

class _WriteClassification {
  const _WriteClassification({
    required this.strategy,
    required this.requiresIdempotency,
    required this.note,
  });

  final String strategy;
  final bool requiresIdempotency;
  final String note;
}

class _DirectWriteClassification {
  const _DirectWriteClassification({required this.note});

  final String note;
}
