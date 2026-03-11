import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/foundation.dart';

enum AppImageCacheProfile { compact, balanced, aggressive }

class AppImageCachePolicy {
  const AppImageCachePolicy({
    required this.maxObjects,
    required this.stalePeriod,
  });

  final int maxObjects;
  final Duration stalePeriod;
}

class AppImageCacheManager {
  AppImageCacheManager._();

  static const String _profileDefine = String.fromEnvironment(
    'IMAGE_CACHE_PROFILE',
    defaultValue: '',
  );

  static AppImageCacheProfile get currentProfile =>
      _resolveProfile(_profileDefine);

  static AppImageCachePolicy get currentPolicy =>
      policyForProfile(currentProfile);

  static AppImageCacheProfile _resolveProfile(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'compact':
        return AppImageCacheProfile.compact;
      case 'aggressive':
        return AppImageCacheProfile.aggressive;
      case 'balanced':
        return AppImageCacheProfile.balanced;
      default:
        if (kIsWeb) return AppImageCacheProfile.compact;
        return switch (defaultTargetPlatform) {
          TargetPlatform.android ||
          TargetPlatform.iOS => AppImageCacheProfile.balanced,
          TargetPlatform.macOS ||
          TargetPlatform.windows ||
          TargetPlatform.linux => AppImageCacheProfile.compact,
          _ => AppImageCacheProfile.balanced,
        };
    }
  }

  static AppImageCachePolicy policyForProfile(AppImageCacheProfile profile) {
    return switch (profile) {
      AppImageCacheProfile.compact => const AppImageCachePolicy(
        maxObjects: 220,
        stalePeriod: Duration(days: 10),
      ),
      AppImageCacheProfile.balanced => const AppImageCachePolicy(
        maxObjects: 400,
        stalePeriod: Duration(days: 14),
      ),
      AppImageCacheProfile.aggressive => const AppImageCachePolicy(
        maxObjects: 650,
        stalePeriod: Duration(days: 21),
      ),
    };
  }

  static final CacheManager instance = CacheManager(
    Config(
      'yeedoy_image_cache_v1',
      stalePeriod: currentPolicy.stalePeriod,
      maxNrOfCacheObjects: currentPolicy.maxObjects,
    ),
  );
}
