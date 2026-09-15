import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/app/router.dart';

// B43/B55 (mimari denetim): oturum süresi dolduğunda kullanıcı açıklamasız
// login ekranına düşüyordu (gönüllü çıkıştan ayırt edilemiyordu). Asıl
// redirect() closure'ı GoRouterState/BuildContext gerektirdiği için doğrudan
// test edilemiyor — karar mantığı computeLoginRedirectTarget'a çıkarıldı
// (bkz. router.dart), bu test onu kilitliyor.
void main() {
  group('computeLoginRedirectTarget (B55)', () {
    test(
      'logged-in -> logged-out geçişinde, gönüllü çıkış TÜKETİLMEDİYSE reason=expired ekler',
      () {
        final target = computeLoginRedirectTarget(
          currentUri: '/profile',
          wasLoggedIn: true,
          consumedVoluntarySignOut: false,
        );
        expect(target, '/login?redirect=%2Fprofile&reason=expired');
      },
    );

    test(
      'logged-in -> logged-out geçişinde, gönüllü çıkış TÜKETİLDİYSE reason eklemez',
      () {
        final target = computeLoginRedirectTarget(
          currentUri: '/profile',
          wasLoggedIn: true,
          consumedVoluntarySignOut: true,
        );
        expect(target, '/login?redirect=%2Fprofile');
        expect(target, isNot(contains('reason=')));
      },
    );

    test(
      'zaten oturumsuzken korumalı bir sayfaya gelmek (geçiş değil) reason eklemez',
      () {
        // wasLoggedIn:false -> bu bir "süre doldu" değil, hiç giriş yapmamış
        // birinin korumalı sayfaya gelmesi.
        final target = computeLoginRedirectTarget(
          currentUri: '/favorites',
          wasLoggedIn: false,
          consumedVoluntarySignOut: false,
        );
        expect(target, '/login?redirect=%2Ffavorites');
        expect(target, isNot(contains('reason=')));
      },
    );

    test('redirect hedefi URI-encode edilir', () {
      final target = computeLoginRedirectTarget(
        currentUri: '/profile?tab=alerts&x=1',
        wasLoggedIn: true,
        consumedVoluntarySignOut: true,
      );
      expect(target, contains(Uri.encodeComponent('/profile?tab=alerts&x=1')));
    });
  });
}
