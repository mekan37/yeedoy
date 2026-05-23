import 'dart:io';

enum _FindingLevel { pass, warn, block }

class _Finding {
  const _Finding(this.level, this.code, this.message);

  final _FindingLevel level;
  final String code;
  final String message;
}

void main() {
  final env = Platform.environment;
  final findings = <_Finding>[];

  final exportMethod = (env['IOS_EXPORT_METHOD'] ?? 'app-store').trim().toLowerCase();
  final expectedPushEnvironment =
      exportMethod == 'development' ? 'development' : 'production';
  final teamId = (env['IOS_APPLE_TEAM_ID'] ?? '').trim();
  final profilePlistPath = (env['IOS_PROVISIONING_PROFILE_PLIST_PATH'] ?? '').trim();
  final exportOptionsPath = (env['IOS_EXPORT_OPTIONS_PLIST_PATH'] ?? '').trim();
  final firebaseMode =
      (env['IOS_FIREBASE_CONFIG_MODE'] ?? 'flutterfire_options').trim().toLowerCase();

  final pbxproj = File('ios/Runner.xcodeproj/project.pbxproj');
  final entitlements = File('ios/Runner/Runner.entitlements');
  final googleServiceInfo = File('ios/Runner/GoogleService-Info.plist');

  final bundleId = pbxproj.existsSync()
      ? _matchGroup(
          pbxproj.readAsStringSync(),
          RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);'),
        )
      : '';

  if (bundleId.isEmpty) {
    findings.add(
      const _Finding(
        _FindingLevel.block,
        'bundle_id_missing',
        'Bundle identifier could not be resolved from ios/Runner.xcodeproj/project.pbxproj.',
      ),
    );
  } else {
    findings.add(
      _Finding(
        _FindingLevel.pass,
        'bundle_id_present',
        'Bundle identifier resolved: $bundleId',
      ),
    );
  }

  if (teamId.isEmpty) {
    findings.add(
      const _Finding(
        _FindingLevel.block,
        'team_id_missing',
        'IOS_APPLE_TEAM_ID is missing for asset validation.',
      ),
    );
  } else {
    findings.add(
      _Finding(
        _FindingLevel.pass,
        'team_id_present',
        'Apple Team ID resolved: $teamId',
      ),
    );
  }

  if (entitlements.existsSync()) {
    final entitlementsText = entitlements.readAsStringSync();
    final apsEnvironment = _plistStringValue(entitlementsText, 'aps-environment');
    if (apsEnvironment == expectedPushEnvironment) {
      findings.add(
        _Finding(
          _FindingLevel.pass,
          'entitlements_push_environment_match',
          'Runner.entitlements aps-environment matches expected $expectedPushEnvironment.',
        ),
      );
    } else {
      findings.add(
        _Finding(
          _FindingLevel.block,
          'entitlements_push_environment_mismatch',
          'Runner.entitlements aps-environment is "${apsEnvironment.isEmpty ? 'missing' : apsEnvironment}" but expected $expectedPushEnvironment for export method $exportMethod.',
        ),
      );
    }
  } else {
    findings.add(
      const _Finding(
        _FindingLevel.block,
        'entitlements_missing',
        'ios/Runner/Runner.entitlements is missing.',
      ),
    );
  }

  if (profilePlistPath.isEmpty) {
    findings.add(
      const _Finding(
        _FindingLevel.block,
        'profile_plist_path_missing',
        'IOS_PROVISIONING_PROFILE_PLIST_PATH is missing.',
      ),
    );
  } else {
    final profilePlist = File(profilePlistPath);
    if (!profilePlist.existsSync()) {
      findings.add(
        _Finding(
          _FindingLevel.block,
          'profile_plist_missing',
          'Provisioning profile plist does not exist: $profilePlistPath',
        ),
      );
    } else {
      final profileText = profilePlist.readAsStringSync();
      final teamIdentifiers = _plistArrayValues(profileText, 'TeamIdentifier');
      if (teamId.isNotEmpty && teamIdentifiers.contains(teamId)) {
        findings.add(
          _Finding(
            _FindingLevel.pass,
            'profile_team_id_match',
            'Provisioning profile includes team identifier $teamId.',
          ),
        );
      } else {
        findings.add(
          _Finding(
            _FindingLevel.block,
            'profile_team_id_mismatch',
            'Provisioning profile team identifiers ${teamIdentifiers.join(', ')} do not include $teamId.',
          ),
        );
      }

      final applicationIdentifier = _plistStringValue(
        profileText,
        'application-identifier',
      );
      final expectedApplicationIdentifier =
          teamId.isNotEmpty && bundleId.isNotEmpty ? '$teamId.$bundleId' : '';
      if (expectedApplicationIdentifier.isNotEmpty &&
          applicationIdentifier == expectedApplicationIdentifier) {
        findings.add(
          _Finding(
            _FindingLevel.pass,
            'profile_bundle_match',
            'Provisioning profile application-identifier matches $expectedApplicationIdentifier.',
          ),
        );
      } else {
        findings.add(
          _Finding(
            _FindingLevel.block,
            'profile_bundle_mismatch',
            'Provisioning profile application-identifier is "${applicationIdentifier.isEmpty ? 'missing' : applicationIdentifier}" but expected $expectedApplicationIdentifier.',
          ),
        );
      }

      final profilePushEnvironment = _plistStringValue(profileText, 'aps-environment');
      if (profilePushEnvironment == expectedPushEnvironment) {
        findings.add(
          _Finding(
            _FindingLevel.pass,
            'profile_push_environment_match',
            'Provisioning profile aps-environment matches expected $expectedPushEnvironment.',
          ),
        );
      } else {
        findings.add(
          _Finding(
            _FindingLevel.block,
            'profile_push_environment_mismatch',
            'Provisioning profile aps-environment is "${profilePushEnvironment.isEmpty ? 'missing' : profilePushEnvironment}" but expected $expectedPushEnvironment for export method $exportMethod.',
          ),
        );
      }
    }
  }

  if (exportOptionsPath.isEmpty) {
    findings.add(
      const _Finding(
        _FindingLevel.block,
        'export_options_path_missing',
        'IOS_EXPORT_OPTIONS_PLIST_PATH is missing.',
      ),
    );
  } else {
    final exportOptions = File(exportOptionsPath);
    if (!exportOptions.existsSync()) {
      findings.add(
        _Finding(
          _FindingLevel.block,
          'export_options_missing',
          'Export options plist does not exist: $exportOptionsPath',
        ),
      );
    } else {
      final exportText = exportOptions.readAsStringSync();
      final method = _plistStringValue(exportText, 'method');
      final exportTeamId = _plistStringValue(exportText, 'teamID');
      if (method == exportMethod) {
        findings.add(
          _Finding(
            _FindingLevel.pass,
            'export_method_match',
            'Export options method matches $exportMethod.',
          ),
        );
      } else {
        findings.add(
          _Finding(
            _FindingLevel.block,
            'export_method_mismatch',
            'Export options method is "${method.isEmpty ? 'missing' : method}" but expected $exportMethod.',
          ),
        );
      }
      if (teamId.isNotEmpty && exportTeamId == teamId) {
        findings.add(
          _Finding(
            _FindingLevel.pass,
            'export_team_id_match',
            'Export options teamID matches $teamId.',
          ),
        );
      } else {
        findings.add(
          _Finding(
            _FindingLevel.block,
            'export_team_id_mismatch',
            'Export options teamID is "${exportTeamId.isEmpty ? 'missing' : exportTeamId}" but expected $teamId.',
          ),
        );
      }
    }
  }

  if (firebaseMode == 'google_service_info') {
    findings.add(
      googleServiceInfo.existsSync()
          ? const _Finding(
              _FindingLevel.pass,
              'google_service_info_present',
              'GoogleService-Info.plist exists for google_service_info mode.',
            )
          : const _Finding(
              _FindingLevel.block,
              'google_service_info_missing',
              'GoogleService-Info.plist is missing for google_service_info mode.',
            ),
    );
  } else {
    findings.add(
      const _Finding(
        _FindingLevel.pass,
        'google_service_info_optional',
        'GoogleService-Info.plist is optional for flutterfire_options mode.',
      ),
    );
  }

  _printReport(findings);
  if (findings.any((finding) => finding.level == _FindingLevel.block)) {
    exitCode = 1;
  }
}

String _matchGroup(String source, RegExp pattern) {
  return pattern.firstMatch(source)?.group(1)?.trim() ?? '';
}

String _plistStringValue(String xml, String key) {
  final match = RegExp(
    '<key>$key</key>\\s*<string>([^<]+)</string>',
    dotAll: true,
  ).firstMatch(xml);
  return match?.group(1)?.trim() ?? '';
}

List<String> _plistArrayValues(String xml, String key) {
  final arrayMatch = RegExp(
    '<key>$key</key>\\s*<array>(.*?)</array>',
    dotAll: true,
  ).firstMatch(xml);
  if (arrayMatch == null) return const <String>[];
  return RegExp(r'<string>([^<]+)</string>', dotAll: true)
      .allMatches(arrayMatch.group(1) ?? '')
      .map((match) => match.group(1)?.trim() ?? '')
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}

void _printReport(List<_Finding> findings) {
  final hasBlock = findings.any((finding) => finding.level == _FindingLevel.block);
  final hasWarn = findings.any((finding) => finding.level == _FindingLevel.warn);
  final status = hasBlock
      ? 'IOS_SIGNING_ASSETS: BLOCK'
      : hasWarn
      ? 'IOS_SIGNING_ASSETS: WARN'
      : 'IOS_SIGNING_ASSETS: PASS';
  stdout.writeln(status);
  for (final finding in findings) {
    stdout.writeln(
      '[${finding.level.name.toUpperCase()}] ${finding.code}: ${finding.message}',
    );
  }
}
