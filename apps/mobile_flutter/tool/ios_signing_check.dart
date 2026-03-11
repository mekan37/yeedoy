import 'dart:convert';
import 'dart:io';

enum _FindingLevel { pass, warn, block }

class _Finding {
  const _Finding(this.level, this.code, this.message);

  final _FindingLevel level;
  final String code;
  final String message;
}

const _allowedExportMethods = <String>{
  'app-store',
  'ad-hoc',
  'development',
  'enterprise',
};

void main(List<String> args) {
  final env = Platform.environment;
  final findings = <_Finding>[];
  final firebaseMode =
      (env['IOS_FIREBASE_CONFIG_MODE'] ?? 'flutterfire_options')
          .trim()
          .toLowerCase();
  final exportMethod =
      (env['IOS_EXPORT_METHOD'] ?? 'app-store').trim().toLowerCase();

  _requireTeamIdEnv(
    findings,
    env,
    'IOS_APPLE_TEAM_ID',
    passMessage: 'Apple Team ID is configured.',
    blockMessage: 'IOS_APPLE_TEAM_ID is missing.',
  );
  _requireBase64Env(
    findings,
    env,
    'IOS_DISTRIBUTION_CERTIFICATE_P12_BASE64',
    passMessage: 'Distribution certificate payload is configured.',
    blockMessage: 'IOS_DISTRIBUTION_CERTIFICATE_P12_BASE64 is missing.',
    minDecodedBytes: 64,
  );
  _requirePlainEnv(
    findings,
    env,
    'IOS_DISTRIBUTION_CERTIFICATE_PASSWORD',
    passMessage: 'Distribution certificate password is configured.',
    blockMessage: 'IOS_DISTRIBUTION_CERTIFICATE_PASSWORD is missing.',
  );
  _requireBase64Env(
    findings,
    env,
    'IOS_PROVISIONING_PROFILE_BASE64',
    passMessage: 'Provisioning profile payload is configured.',
    blockMessage: 'IOS_PROVISIONING_PROFILE_BASE64 is missing.',
    minDecodedBytes: 256,
  );

  if (_allowedExportMethods.contains(exportMethod)) {
    findings.add(
      _Finding(
        _FindingLevel.pass,
        'export_method_valid',
        'iOS export method resolved: $exportMethod',
      ),
    );
  } else {
    findings.add(
      _Finding(
        _FindingLevel.block,
        'export_method_invalid',
        'IOS_EXPORT_METHOD must be one of: ${_allowedExportMethods.join(', ')}',
      ),
    );
  }

  if (firebaseMode == 'google_service_info') {
    _requireBase64Env(
      findings,
      env,
      'IOS_GOOGLE_SERVICE_INFO_BASE64',
      passMessage: 'GoogleService-Info payload is configured.',
      blockMessage:
          'IOS_GOOGLE_SERVICE_INFO_BASE64 is required when IOS_FIREBASE_CONFIG_MODE=google_service_info.',
      minDecodedBytes: 128,
    );
  } else if (firebaseMode == 'flutterfire_options') {
    findings.add(
      const _Finding(
        _FindingLevel.pass,
        'firebase_mode_options_only',
        'Firebase config mode uses flutterfire_options; GoogleService-Info.plist secret is optional.',
      ),
    );
  } else {
    findings.add(
      _Finding(
        _FindingLevel.block,
        'firebase_mode_invalid',
        'IOS_FIREBASE_CONFIG_MODE must be flutterfire_options or google_service_info.',
      ),
    );
  }

  final exportOptions = File('ios/ExportOptions.plist');
  findings.add(
    exportOptions.existsSync()
        ? const _Finding(
            _FindingLevel.pass,
            'export_options_present',
            'ios/ExportOptions.plist exists.',
          )
        : const _Finding(
            _FindingLevel.block,
            'export_options_missing',
            'ios/ExportOptions.plist is missing.',
          ),
  );

  final entitlements = File('ios/Runner/Runner.entitlements');
  findings.add(
    entitlements.existsSync()
        ? const _Finding(
            _FindingLevel.pass,
            'runner_entitlements_present',
            'Runner entitlements file exists.',
          )
        : const _Finding(
            _FindingLevel.block,
            'runner_entitlements_missing',
            'Runner entitlements file is missing.',
          ),
  );

  final pbxproj = File('ios/Runner.xcodeproj/project.pbxproj');
  if (pbxproj.existsSync()) {
    final projectText = pbxproj.readAsStringSync();
    findings.add(
      projectText.contains('DEVELOPMENT_TEAM = "\$(APPLE_TEAM_ID)";')
          ? const _Finding(
              _FindingLevel.pass,
              'development_team_wired',
              'Runner build settings read APPLE_TEAM_ID from the environment.',
            )
          : const _Finding(
              _FindingLevel.warn,
              'development_team_not_wired',
              'Runner build settings do not reference APPLE_TEAM_ID yet.',
            ),
    );
  } else {
    findings.add(
      const _Finding(
        _FindingLevel.block,
        'project_missing',
        'ios/Runner.xcodeproj/project.pbxproj is missing.',
      ),
    );
  }

  _printReport(findings);
  if (findings.any((finding) => finding.level == _FindingLevel.block)) {
    exitCode = 1;
  }
}

void _requireTeamIdEnv(
  List<_Finding> findings,
  Map<String, String> env,
  String key, {
  required String passMessage,
  required String blockMessage,
}) {
  final value = env[key]?.trim() ?? '';
  if (value.isEmpty) {
    findings.add(_Finding(_FindingLevel.block, '${key.toLowerCase()}_missing', blockMessage));
    return;
  }
  if (_looksPlaceholder(value)) {
    findings.add(
      _Finding(
        _FindingLevel.block,
        '${key.toLowerCase()}_placeholder',
        '$key looks like a placeholder value.',
      ),
    );
    return;
  }
  if (!RegExp(r'^[A-Z0-9]{10}$').hasMatch(value)) {
    findings.add(
      _Finding(
        _FindingLevel.block,
        '${key.toLowerCase()}_invalid_format',
        '$key must look like a 10-character Apple Team ID.',
      ),
    );
    return;
  }
  findings.add(_Finding(_FindingLevel.pass, '${key.toLowerCase()}_present', passMessage));
}

void _requirePlainEnv(
  List<_Finding> findings,
  Map<String, String> env,
  String key, {
  required String passMessage,
  required String blockMessage,
}) {
  final value = env[key]?.trim() ?? '';
  if (value.isEmpty) {
    findings.add(_Finding(_FindingLevel.block, '${key.toLowerCase()}_missing', blockMessage));
    return;
  }
  if (_looksPlaceholder(value)) {
    findings.add(
      _Finding(
        _FindingLevel.block,
        '${key.toLowerCase()}_placeholder',
        '$key looks like a placeholder value.',
      ),
    );
    return;
  }
  findings.add(_Finding(_FindingLevel.pass, '${key.toLowerCase()}_present', passMessage));
}

void _requireBase64Env(
  List<_Finding> findings,
  Map<String, String> env,
  String key, {
  required String passMessage,
  required String blockMessage,
  required int minDecodedBytes,
}) {
  final value = env[key]?.trim() ?? '';
  if (value.isEmpty) {
    findings.add(_Finding(_FindingLevel.block, '${key.toLowerCase()}_missing', blockMessage));
    return;
  }
  if (_looksPlaceholder(value)) {
    findings.add(
      _Finding(
        _FindingLevel.block,
        '${key.toLowerCase()}_placeholder',
        '$key looks like a placeholder value.',
      ),
    );
    return;
  }
  try {
    final decoded = base64Decode(value);
    if (decoded.length < minDecodedBytes) {
      findings.add(
        _Finding(
          _FindingLevel.block,
          '${key.toLowerCase()}_too_small',
          '$key decoded successfully but payload is unexpectedly small (${decoded.length} bytes).',
        ),
      );
      return;
    }
  } on FormatException {
    findings.add(
      _Finding(
        _FindingLevel.block,
        '${key.toLowerCase()}_invalid_base64',
        '$key is not valid base64.',
      ),
    );
    return;
  }
  findings.add(
    _Finding(_FindingLevel.pass, '${key.toLowerCase()}_present', passMessage),
  );
}

bool _looksPlaceholder(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized.isEmpty ||
      normalized.contains('replace_me') ||
      normalized.contains('replace-with') ||
      normalized.contains('your_') ||
      normalized.contains('example') ||
      normalized.contains('<') ||
      normalized == 'todo' ||
      normalized == 'changeme';
}

void _printReport(List<_Finding> findings) {
  final hasBlock = findings.any((finding) => finding.level == _FindingLevel.block);
  final hasWarn = findings.any((finding) => finding.level == _FindingLevel.warn);
  final status = hasBlock
      ? 'IOS_SIGNING: BLOCK'
      : hasWarn
      ? 'IOS_SIGNING: WARN'
      : 'IOS_SIGNING: PASS';
  stdout.writeln(status);
  for (final finding in findings) {
    stdout.writeln(
      '[${finding.level.name.toUpperCase()}] ${finding.code}: ${finding.message}',
    );
  }
}
