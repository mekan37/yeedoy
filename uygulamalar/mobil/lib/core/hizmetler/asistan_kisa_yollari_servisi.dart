import 'dart:io';

import 'package:flutter/services.dart';

/// Donates NSUserActivity records to Siri (iOS) so the OS learns
/// the user's patterns and can suggest shortcuts.
///
/// On Android the shortcuts are static (declared in app_shortcuts.xml),
/// so no runtime donation is needed.
class AssistantShortcutsService {
  static const _channel =
      MethodChannel('com.yeedoy.uygulama/assistant_shortcuts');

  /// Call once when the discover / home feed is shown.
  static Future<void> donateDiscoverActivity() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('donateActivity', {
        'activityType': 'com.yeedoy.app.openDiscover',
        'title': 'Restoran Keşfet',
        'userInfo': <String, String>{},
      });
    } on MissingPluginException {
      // Not wired up yet — ignore silently.
    } catch (_) {
      // Non-critical; never crash the app for a donation failure.
    }
  }

  /// Call when the user taps the cheap/price-sorted view.
  static Future<void> donateNearbyCheapActivity() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('donateActivity', {
        'activityType': 'com.yeedoy.app.findNearbyCheap',
        'title': 'Ucuz Yemek Bul',
        'userInfo': <String, String>{'sort': 'price_asc'},
      });
    } on MissingPluginException {
      // Not wired up yet — ignore silently.
    } catch (_) {}
  }
}
