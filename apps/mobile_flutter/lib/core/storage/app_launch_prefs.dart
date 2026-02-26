import 'package:shared_preferences/shared_preferences.dart';

class AppLaunchPrefs {
  const AppLaunchPrefs._();

  static const _seenOnboardingKey = 'seen_onboarding_v1';

  static Future<bool> seenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenOnboardingKey) ?? false;
  }

  static Future<void> setSeenOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenOnboardingKey, value);
  }
}
