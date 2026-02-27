import '../../../core/security/app_role_providers.dart';

const Set<String> _communityModAllowedExactRoutes = <String>{'/admin'};

const Set<String> _communityModAllowedPrefixRoutes = <String>{
  '/admin/reports',
  '/admin/appeals',
};

bool canAccessAdminRoute(AppRole role, String path) {
  if (role == AppRole.admin) return true;
  if (role == AppRole.communityMod) {
    if (_communityModAllowedExactRoutes.contains(path)) return true;
    for (final route in _communityModAllowedPrefixRoutes) {
      if (path == route || path.startsWith('$route/')) return true;
    }
  }
  return false;
}

bool canWriteAdminQueue(AppRole role) {
  return role == AppRole.admin || role == AppRole.communityMod;
}
