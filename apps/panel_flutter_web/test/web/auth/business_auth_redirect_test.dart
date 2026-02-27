import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/core/security/app_role_providers.dart';
import 'package:yeedoy/features/auth/domain/business_auth_redirect.dart';

void main() {
  group('businessHomeForRole', () {
    test('rol bazli varsayilan panel ana yolunu verir', () {
      expect(businessHomeForRole(AppRole.admin), '/admin');
      expect(businessHomeForRole(AppRole.communityMod), '/admin');
      expect(businessHomeForRole(AppRole.owner), '/owner');
      expect(businessHomeForRole(AppRole.user), '/');
    });
  });

  group('resolveBusinessPostLoginPath', () {
    test('redirect yoksa role ana sayfasina doner', () {
      expect(
        resolveBusinessPostLoginPath(role: AppRole.owner, encodedRedirect: null),
        '/owner',
      );
    });

    test('owner icin owner deep-link kabul edilir', () {
      final encoded = Uri.encodeComponent('/owner/menus?businessId=abc');
      expect(
        resolveBusinessPostLoginPath(
          role: AppRole.owner,
          encodedRedirect: encoded,
        ),
        '/owner/menus?businessId=abc',
      );
    });

    test('owner icin admin deep-link reddedilir', () {
      final encoded = Uri.encodeComponent('/admin/reports');
      expect(
        resolveBusinessPostLoginPath(
          role: AppRole.owner,
          encodedRedirect: encoded,
        ),
        '/owner',
      );
    });

    test('community mod izinli admin deep-linke gidebilir', () {
      final encoded = Uri.encodeComponent('/admin/reports');
      expect(
        resolveBusinessPostLoginPath(
          role: AppRole.communityMod,
          encodedRedirect: encoded,
        ),
        '/admin/reports',
      );
    });

    test('community mod izin disi admin deep-linke gidemez', () {
      final encoded = Uri.encodeComponent('/admin/price-suggestions');
      expect(
        resolveBusinessPostLoginPath(
          role: AppRole.communityMod,
          encodedRedirect: encoded,
        ),
        '/admin',
      );
    });

    test('harici veya gecersiz redirect reddedilir', () {
      expect(
        resolveBusinessPostLoginPath(
          role: AppRole.admin,
          encodedRedirect: Uri.encodeComponent('https://evil.com'),
        ),
        '/admin',
      );
      expect(
        resolveBusinessPostLoginPath(
          role: AppRole.admin,
          encodedRedirect: '%%%broken%%%',
        ),
        '/admin',
      );
    });
  });
}
