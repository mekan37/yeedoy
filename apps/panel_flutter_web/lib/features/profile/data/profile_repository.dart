import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';
import 'profile_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseProvider));
});

class ProfileRepository {
  ProfileRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<Profile?> getMyProfile() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return null;

    try {
      final row = await _supabase
          .from('user_profiles')
          .select('user_id,display_name')
          .eq('user_id', uid)
          .single();
      final data = (row as Map).cast<String, dynamic>();
      final displayName = (data['display_name'] ?? '').toString().trim();
      final parts = displayName
          .split(RegExp(r'\s+'))
          .where((e) => e.isNotEmpty)
          .toList();
      final firstName = parts.isNotEmpty ? parts.first : '';
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      return Profile(
        id: (data['user_id'] ?? uid).toString(),
        firstName: firstName,
        lastName: lastName,
        displayName: displayName.isEmpty ? null : displayName,
      );
    } on PostgrestException catch (e) {
      // No row found => return null, anything else rethrow.
      if (e.code == 'PGRST116' ||
          (e.message).toLowerCase().contains('0 rows')) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> upsertMyProfile(Profile p) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('auth_required');
    }

    final normalizedLinks = <String, String>{};
    for (final entry in p.socialLinks.entries) {
      final key = entry.key.trim();
      if (key.isEmpty) continue;
      final normalized = normalizeSocialUrl(entry.value);
      if (normalized == null || normalized.isEmpty) continue;
      normalizedLinks[key] = normalized;
    }

    final profile = p.copyWith(id: uid, socialLinks: normalizedLinks);
    final displayName =
        (profile.displayName ?? '${profile.firstName} ${profile.lastName}')
            .trim();
    await _supabase.from('user_profiles').upsert({
      'user_id': uid,
      'display_name': displayName.isEmpty ? 'Kullanici' : displayName,
    }, onConflict: 'user_id');
  }
}

String? normalizeSocialUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  Uri? uri = Uri.tryParse(trimmed);
  if (uri == null) return null;
  if (uri.scheme.isEmpty) {
    uri = Uri.tryParse('https://$trimmed');
    if (uri == null) return null;
  }
  if (uri.host.isEmpty) return null;

  final host = uri.host.toLowerCase();
  const allowedBestEffort = <String>{
    'instagram.com',
    'www.instagram.com',
    'youtube.com',
    'www.youtube.com',
    'youtu.be',
    'facebook.com',
    'www.facebook.com',
    'fb.watch',
  };

  // Best-effort allow list: do not hard reject unknown hosts.
  if (!allowedBestEffort.contains(host)) {
    return uri.toString();
  }
  return uri.toString();
}
