import '../../../core/security/app_role_providers.dart';
import '../../../core/security/route_sanitizer.dart';
import '../../admin/domain/admin_permissions.dart';

bool _isOwnerRoute(String path) => path == '/owner' || path.startsWith('/owner/');
bool _isAdminRoute(String path) => path == '/admin' || path.startsWith('/admin/');

String businessHomeForRole(AppRole role) {
  return switch (role) {
    AppRole.admin || AppRole.communityMod => '/admin',
    AppRole.owner => '/owner',
    AppRole.user => '/',
  };
}

String resolveBusinessPostLoginPath({
  required AppRole role,
  String? encodedRedirect,
}) {
  final redirect = sanitizeInternalRedirect(encodedRedirect);
  if (redirect == null) return businessHomeForRole(role);

  if (_isAdminRoute(redirect)) {
    return canAccessAdminRoute(role, redirect)
        ? redirect
        : businessHomeForRole(role);
  }

  if (_isOwnerRoute(redirect)) {
    final isOwnerOrAdmin = role == AppRole.owner || role == AppRole.admin;
    return isOwnerOrAdmin ? redirect : businessHomeForRole(role);
  }

  return businessHomeForRole(role);
}
