import 'dart:io';

enum _FindingLevel { pass, warn, block }

class _Finding {
  const _Finding(this.level, this.code, this.message);

  final _FindingLevel level;
  final String code;
  final String message;
}

Future<void> main() async {
  final findings = <_Finding>[];
  final iosDir = Directory('ios');

  if (!iosDir.existsSync()) {
    _printReport(
      <_Finding>[
        const _Finding(
          _FindingLevel.block,
          'ios_dir_missing',
          'ios directory is missing.',
        ),
      ],
    );
    exitCode = 1;
    return;
  }

  final workspace = Directory('ios/Runner.xcworkspace');
  final pbxproj = File('ios/Runner.xcodeproj/project.pbxproj');
  final infoPlist = File('ios/Runner/Info.plist');
  final podfile = File('ios/Podfile');
  final scheme = File(
    'ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme',
  );
  final googleServiceInfo = File('ios/Runner/GoogleService-Info.plist');
  final exportOptions = File('ios/ExportOptions.plist');

  findings.add(
    workspace.existsSync()
        ? const _Finding(
            _FindingLevel.pass,
            'workspace_present',
            'Runner workspace exists.',
          )
        : const _Finding(
            _FindingLevel.block,
            'workspace_missing',
            'Runner.xcworkspace is missing.',
          ),
  );
  findings.add(
    pbxproj.existsSync()
        ? const _Finding(
            _FindingLevel.pass,
            'project_present',
            'Runner project exists.',
          )
        : const _Finding(
            _FindingLevel.block,
            'project_missing',
            'Runner.xcodeproj/project.pbxproj is missing.',
          ),
  );
  findings.add(
    infoPlist.existsSync()
        ? const _Finding(
            _FindingLevel.pass,
            'info_plist_present',
            'Runner Info.plist exists.',
          )
        : const _Finding(
            _FindingLevel.block,
            'info_plist_missing',
            'Runner Info.plist is missing.',
          ),
  );
  findings.add(
    scheme.existsSync()
        ? const _Finding(
            _FindingLevel.pass,
            'scheme_present',
            'Shared Runner scheme exists.',
          )
        : const _Finding(
            _FindingLevel.block,
            'scheme_missing',
            'Shared Runner scheme is missing.',
          ),
  );
  findings.add(
    podfile.existsSync()
        ? const _Finding(
            _FindingLevel.pass,
            'podfile_present',
            'Podfile exists.',
          )
        : const _Finding(
            _FindingLevel.block,
            'podfile_missing',
            'Podfile is missing. iOS dependency resolution is not reproducible in CI yet.',
          ),
  );

  if (pbxproj.existsSync()) {
    final projectText = await pbxproj.readAsString();
    final bundleIdMatch = RegExp(
      r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);',
    ).firstMatch(projectText);
    final bundleId = bundleIdMatch?.group(1)?.trim() ?? '';
    findings.add(
      bundleId.isNotEmpty
          ? _Finding(
              _FindingLevel.pass,
              'bundle_id_present',
              'Bundle identifier resolved: $bundleId',
            )
          : const _Finding(
              _FindingLevel.block,
              'bundle_id_missing',
              'Bundle identifier could not be resolved from project.pbxproj.',
            ),
    );
    findings.add(
      projectText.contains('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;')
          ? const _Finding(
              _FindingLevel.pass,
              'entitlements_wired',
              'Runner entitlements are wired into Xcode build settings.',
            )
          : const _Finding(
              _FindingLevel.block,
              'entitlements_not_wired',
              'Runner entitlements file is not referenced by Xcode build settings.',
            ),
    );
  }

  if (infoPlist.existsSync()) {
    final infoPlistText = await infoPlist.readAsString();
    findings.add(
      infoPlistText.contains('<string>remote-notification</string>')
          ? const _Finding(
              _FindingLevel.pass,
              'background_remote_notification_present',
              'Info.plist declares remote-notification background mode.',
            )
          : const _Finding(
              _FindingLevel.warn,
              'background_remote_notification_missing',
              'Info.plist does not declare remote-notification background mode. Background push delivery should be verified.',
            ),
    );
  }

  final entitlements = iosDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.entitlements'))
      .toList(growable: false);
  if (entitlements.isEmpty) {
    findings.add(
      const _Finding(
        _FindingLevel.block,
        'entitlements_missing',
        'No entitlements file found. Push capabilities and associated domains cannot be verified.',
      ),
    );
  } else {
    findings.add(
      _Finding(
        _FindingLevel.pass,
        'entitlements_present',
        'Entitlements file found: ${entitlements.map((file) => file.path).join(', ')}',
      ),
    );
    final entitlementsText = await entitlements.first.readAsString();
    findings.add(
      entitlementsText.contains('aps-environment')
          ? const _Finding(
              _FindingLevel.pass,
              'aps_environment_present',
              'APNs entitlement is configured.',
            )
          : const _Finding(
              _FindingLevel.block,
              'aps_environment_missing',
              'APNs entitlement is missing. Push notification readiness is blocked.',
            ),
    );
    findings.add(
      entitlementsText.contains('com.apple.developer.associated-domains')
          ? const _Finding(
              _FindingLevel.pass,
              'associated_domains_present',
              'Associated Domains entitlement is configured.',
            )
          : const _Finding(
              _FindingLevel.warn,
              'associated_domains_missing',
              'Associated Domains entitlement is missing. Universal link readiness should be confirmed.',
            ),
    );
  }

  findings.add(
    googleServiceInfo.existsSync()
        ? const _Finding(
            _FindingLevel.pass,
            'google_service_info_present',
            'GoogleService-Info.plist exists.',
          )
        : const _Finding(
            _FindingLevel.warn,
            'google_service_info_missing',
            'GoogleService-Info.plist is missing from the repo. Confirm whether FlutterFire options-only bootstrap is the intended release path.',
          ),
  );
  findings.add(
    exportOptions.existsSync()
        ? const _Finding(
            _FindingLevel.pass,
            'export_options_present',
            'ExportOptions.plist exists.',
          )
        : const _Finding(
            _FindingLevel.warn,
            'export_options_missing',
            'ExportOptions.plist is missing. TestFlight/App Store export should be documented elsewhere.',
          ),
  );

  _printReport(findings);
  if (findings.any((finding) => finding.level == _FindingLevel.block)) {
    exitCode = 1;
  }
}

void _printReport(List<_Finding> findings) {
  final hasBlock = findings.any((finding) => finding.level == _FindingLevel.block);
  final hasWarn = findings.any((finding) => finding.level == _FindingLevel.warn);
  final status = hasBlock
      ? 'IOS_READINESS: BLOCK'
      : hasWarn
      ? 'IOS_READINESS: WARN'
      : 'IOS_READINESS: PASS';
  stdout.writeln(status);
  for (final finding in findings) {
    stdout.writeln(
      '[${finding.level.name.toUpperCase()}] ${finding.code}: ${finding.message}',
    );
  }
}
