import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/core/security/app_role_providers.dart';
import 'package:yeedoy/features/admin/domain/admin_permissions.dart';

void main() {
  group('canAccessAdminRoute', () {
    test('admin tum admin rotalarina erisir', () {
      expect(canAccessAdminRoute(AppRole.admin, '/admin'), isTrue);
      expect(canAccessAdminRoute(AppRole.admin, '/admin/reports'), isTrue);
      expect(canAccessAdminRoute(AppRole.admin, '/admin/incidents'), isTrue);
    });

    test('community mod sadece izinli rotalara erisir', () {
      expect(canAccessAdminRoute(AppRole.communityMod, '/admin'), isTrue);
      expect(canAccessAdminRoute(AppRole.communityMod, '/admin/reports'), isTrue);
      expect(
        canAccessAdminRoute(AppRole.communityMod, '/admin/appeals/42'),
        isTrue,
      );
      expect(
        canAccessAdminRoute(AppRole.communityMod, '/admin/price-suggestions'),
        isFalse,
      );
    });

    test('owner ve user admin rotalarina erisemez', () {
      expect(canAccessAdminRoute(AppRole.owner, '/admin'), isFalse);
      expect(canAccessAdminRoute(AppRole.user, '/admin/reports'), isFalse);
    });
  });

  group('canWriteAdminQueue', () {
    test('admin ve community mod yazabilir', () {
      expect(canWriteAdminQueue(AppRole.admin), isTrue);
      expect(canWriteAdminQueue(AppRole.communityMod), isTrue);
    });

    test('owner ve user yazamaz', () {
      expect(canWriteAdminQueue(AppRole.owner), isFalse);
      expect(canWriteAdminQueue(AppRole.user), isFalse);
    });
  });
}
