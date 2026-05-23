// ignore_for_file: avoid_print
import 'dart:io';

/// Scans Dart source files for hardcoded Color(0x...) usage outside of
/// approved files. Exits with code 1 if violations are found.
///
/// Approved files may contain hardcoded colors for intentional reasons
/// (animations, achievement badge palettes, auth brand colors).
final _approvedPatterns = <RegExp>[
  // Auth pages intentionally use brand hex values
  RegExp(r'lib[/\\]features[/\\]auth[/\\]'),
  // Achievement visuals have unique per-badge colors
  RegExp(r'lib[/\\]features[/\\]shared[/\\]ui[/\\]achievements[/\\]'),
  // Splash page uses transparent gradient animation stops
  RegExp(r'lib[/\\]features[/\\]splash[/\\]'),
  // Meal card badge uses specific chip palette not in AppColors
  RegExp(r'lib[/\\]features[/\\]shared[/\\]ui[/\\]widgets[/\\]meal_card_badge\.dart'),
  // Custom painter white dot uses Colors.white equivalent
  RegExp(r'menu_item_detail_sections\.dart'),
  // Instagram pink is intentional brand color
  RegExp(r'discovery_cards\.dart'),
  // Legal muted color not yet in AppColors
  RegExp(r'legal_required_consent_card\.dart'),
  // Achievements grid unlocked/locked visual
  RegExp(r'achievements_grid\.dart'),
];

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('Run from apps/mobile_flutter directory.');
    exit(2);
  }

  final violations = <String>[];
  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    final relativePath = file.path.replaceAll('\\', '/');
    final isApproved = _approvedPatterns.any((p) => p.hasMatch(relativePath));
    if (isApproved) continue;

    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Skip comment lines
      if (line.trimLeft().startsWith('//')) continue;
      // Check for hardcoded Color(0x...) usage
      if (line.contains('Color(0x') || line.contains('Color(#')) {
        violations.add('${file.path}:${i + 1}: $line');
      }
    }
  }

  if (violations.isEmpty) {
    print('hardcoded_color_check: no violations found.');
    exit(0);
  }

  print('hardcoded_color_check: ${violations.length} violation(s) found.\n');
  print('Use AppColors or AppPalette constants instead of raw Color(0x...) values.\n');
  for (final v in violations) {
    print('  $v');
  }
  exit(1);
}
