// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;

bool isMobileWeb() {
  final ua = html.window.navigator.userAgent.toLowerCase();
  return ua.contains('mobi') ||
      ua.contains('android') ||
      ua.contains('iphone') ||
      ua.contains('ipad');
}

void openUrl(String url) {
  html.window.location.assign(url);
}

void openAppLinkWithFallback({
  required String appUrl,
  required String fallbackUrl,
  Duration delay = const Duration(milliseconds: 1200),
}) {
  var didHide = false;
  void handleVisibility(_) {
    if (html.document.hidden == true) {
      didHide = true;
    }
  }

  html.document.addEventListener('visibilitychange', handleVisibility);
  html.window.location.assign(appUrl);

  Timer(delay, () {
    html.document.removeEventListener('visibilitychange', handleVisibility);
    if (!didHide) {
      html.window.location.assign(fallbackUrl);
    }
  });
}
