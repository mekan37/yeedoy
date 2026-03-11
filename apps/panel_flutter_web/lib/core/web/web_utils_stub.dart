bool isMobileWeb() => false;

void openUrl(String url) {}

void submitPostRedirect(
  String url,
  Map<String, String> fields, {
  String? target,
}) {}

void openAppLinkWithFallback({
  required String appUrl,
  required String fallbackUrl,
  Duration delay = const Duration(milliseconds: 1200),
}) {}
