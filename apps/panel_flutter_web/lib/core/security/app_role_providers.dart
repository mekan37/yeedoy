import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/supabase_provider.dart';

enum AppRole { user, owner, communityMod, admin }

final appRoleProvider = FutureProvider<AppRole>((ref) async {
  final client = ref.read(supabaseProvider);
  final user = client.auth.currentUser;
  if (user == null) return AppRole.user;

  try {
    final raw = await client.rpc('current_user_role_v1');
    final role = raw?.toString().trim().toLowerCase() ?? 'user';
    if (role == 'admin') return AppRole.admin;
    if (role == 'community_mod' ||
        role == 'communitymod' ||
        role == 'moderator') {
      return AppRole.communityMod;
    }
    if (role == 'owner') return AppRole.owner;
    return AppRole.user;
  } catch (_) {
    final fallbackRole =
        (user.appMetadata['role'] ?? user.userMetadata?['role'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
    if (fallbackRole == 'community_mod' ||
        fallbackRole == 'communitymod' ||
        fallbackRole == 'moderator') {
      return AppRole.communityMod;
    }

    // Fallback for older DBs where current_user_role_v1 might not exist yet.
    final isAdminRaw = await client.rpc('is_admin');
    final isAdmin = switch (isAdminRaw) {
      bool b => b,
      Map m => m['is_admin'] == true,
      _ => false,
    };
    if (isAdmin) return AppRole.admin;

    try {
      final rows = await client.rpc(
        'owner_list_my_businesses_v2',
        params: {'p_status': 'approved', 'p_limit': 1, 'p_offset': 0},
      );
      if (rows is List && rows.isNotEmpty) return AppRole.owner;
    } catch (_) {
      final rows = await client.rpc(
        'owner_list_my_businesses_v1',
        params: {'p_status': 'approved', 'p_limit': 1, 'p_offset': 0},
      );
      if (rows is List && rows.isNotEmpty) return AppRole.owner;
    }
    return AppRole.user;
  }
});

final isAdminProvider = FutureProvider<bool>((ref) async {
  final role = await ref.watch(appRoleProvider.future);
  return role == AppRole.admin;
});

final canAccessAdminPanelProvider = FutureProvider<bool>((ref) async {
  final role = await ref.watch(appRoleProvider.future);
  return role == AppRole.admin || role == AppRole.communityMod;
});

final isCommunityModeratorProvider = FutureProvider<bool>((ref) async {
  final role = await ref.watch(appRoleProvider.future);
  return role == AppRole.communityMod;
});

final isOwnerProvider = FutureProvider<bool>((ref) async {
  final role = await ref.watch(appRoleProvider.future);
  return role == AppRole.owner || role == AppRole.admin;
});

final canManageBusinessProvider = FutureProvider.family<bool, String>((
  ref,
  businessId,
) async {
  if (businessId.trim().isEmpty) return false;
  final client = ref.read(supabaseProvider);
  try {
    final raw = await client.rpc(
      'can_manage_business_v1',
      params: {'p_business_id': businessId},
    );
    return raw == true;
  } catch (_) {
    return false;
  }
});
