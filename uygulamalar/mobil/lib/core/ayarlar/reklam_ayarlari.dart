import 'package:flutter/foundation.dart';

class AdConfig {
  const AdConfig._();

  static const nativeAdsDisabled = bool.fromEnvironment(
    'ADMOB_NATIVE_DISABLED',
    defaultValue: true,
  );

  static const appIdAndroid = String.fromEnvironment(
    'ADMOB_APP_ID_ANDROID',
    defaultValue: '',
  );
  static const appIdIos = String.fromEnvironment(
    'ADMOB_APP_ID_IOS',
    defaultValue: '',
  );
  static const nativeUnitIdAndroid = String.fromEnvironment(
    'ADMOB_NATIVE_UNIT_ID_ANDROID',
    defaultValue: 'ca-app-pub-1150074560839161/1470297943',
  );
  static const nativeUnitIdIos = String.fromEnvironment(
    'ADMOB_NATIVE_UNIT_ID_IOS',
    defaultValue: 'ca-app-pub-1150074560839161/1470297943',
  );

  static String get nativeUnitId {
    final configured = switch (defaultTargetPlatform) {
      TargetPlatform.android => nativeUnitIdAndroid.trim(),
      TargetPlatform.iOS => nativeUnitIdIos.trim(),
      _ => '',
    };
    if (configured.isNotEmpty) return configured;
    if (kDebugMode) {
      return switch (defaultTargetPlatform) {
        TargetPlatform.android => 'ca-app-pub-3940256099942544/2247696110',
        TargetPlatform.iOS => 'ca-app-pub-3940256099942544/3986624511',
        _ => '',
      };
    }
    return '';
  }

  static bool get isNativeEnabled =>
      !nativeAdsDisabled && nativeUnitId.isNotEmpty;
}
