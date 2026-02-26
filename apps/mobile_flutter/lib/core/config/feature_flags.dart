import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/feature_flags_prefs.dart';

class FeatureFlags {
  const FeatureFlags._();

  static const bool enablePhotoFeed = false;
  static const bool enableLabs = true;
}

class FeatureFlagDef {
  const FeatureFlagDef({
    required this.flag,
    required this.label,
    required this.description,
    required this.defaultValue,
  });

  final String flag;
  final String label;
  final String description;
  final bool defaultValue;
}

const featureFlagDefs = <FeatureFlagDef>[
  FeatureFlagDef(
    flag: 'enablePhotoFeed',
    label: 'Photo Feed',
    description: 'Fotograf akisini ac/kapat.',
    defaultValue: FeatureFlags.enablePhotoFeed,
  ),
  FeatureFlagDef(
    flag: 'enableLabs',
    label: 'Labs',
    description: 'Deneysel ozellikleri ac/kapat.',
    defaultValue: FeatureFlags.enableLabs,
  ),
];

class FeatureFlagsState {
  const FeatureFlagsState({required this.localFlags});

  final Map<String, bool> localFlags;

  factory FeatureFlagsState.empty() =>
      const FeatureFlagsState(localFlags: <String, bool>{});
}

final featureFlagsProvider = NotifierProvider<FeatureFlagsController, FeatureFlagsState>(
  FeatureFlagsController.new,
);

class FeatureFlagsController extends Notifier<FeatureFlagsState> {
  @override
  FeatureFlagsState build() {
    Future.microtask(_loadFromPrefs);
    return FeatureFlagsState.empty();
  }

  Future<void> _loadFromPrefs() async {
    final flags = await FeatureFlagsPrefs.readAll();
    state = FeatureFlagsState(localFlags: flags);
  }

  Future<void> setFlag(String key, bool value) async {
    final next = Map<String, bool>.from(state.localFlags)..[key] = value;
    state = FeatureFlagsState(localFlags: next);
    await FeatureFlagsPrefs.setFlag(key, value);
  }
}
