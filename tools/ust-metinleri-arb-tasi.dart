import 'dart:convert';
import 'dart:io';

const _topN = 30;

const _preferredKeys = <String, String>{
  'Kaydet': 'save',
  'Ä°ptal': 'cancel',
  'Iptal': 'cancel',
  'Profil AyarlarÄ±': 'profileSettings',
  'Profil Ayarlari': 'profileSettings',
  'KeÅŸfet': 'discover',
  'Kesfet': 'discover',
  'Favoriler': 'favorites',
  'Profil': 'profile',
  'Ayarlar': 'settings',
};

class ReplaceStats {
  int totalReplaced = 0;
  final Map<String, int> replacedByPattern = <String, int>{};
  final Map<String, int> skippedByReason = <String, int>{};
  final List<String> skippedSamples = <String>[];

  void replaced(String pattern) {
    totalReplaced++;
    replacedByPattern[pattern] = (replacedByPattern[pattern] ?? 0) + 1;
  }

  void skipped(String reason, String sample) {
    skippedByReason[reason] = (skippedByReason[reason] ?? 0) + 1;
    if (skippedSamples.length < 60) {
      skippedSamples.add('$reason: $sample');
    }
  }
}

void main() async {
  final reportFile = File('candidate_strings_report.md');
  final trFile = File('lib/l10n/app_tr.arb');
  final enFile = File('lib/l10n/app_en.arb');

  if (!reportFile.existsSync() || !trFile.existsSync() || !enFile.existsSync()) {
    stderr.writeln('Required files are missing.');
    exitCode = 1;
    return;
  }

  final topStrings = _parseTopStrings(reportFile.readAsStringSync(), _topN);
  if (topStrings.isEmpty) {
    stderr.writeln('No strings parsed from candidate_strings_report.md.');
    exitCode = 1;
    return;
  }

  final trMap = _readJsonMap(trFile);
  final enMap = _readJsonMap(enFile);
  final usedKeys = <String>{
    ...trMap.keys.where((k) => !k.startsWith('@')),
    ...enMap.keys.where((k) => !k.startsWith('@')),
  };

  final stringToKey = <String, String>{};
  final addedKeys = <String, String>{};

  for (final s in topStrings) {
    if (_shouldSkipLiteralForArb(s)) continue;
    final existing = _findExistingKeyForValue(trMap, s);
    if (existing != null) {
      stringToKey[s] = existing;
      continue;
    }
    final base = _buildKey(s);
    final key = _dedupeKey(base, usedKeys);
    usedKeys.add(key);
    trMap[key] = s;
    enMap[key] = 'TODO_EN: $s';
    stringToKey[s] = key;
    addedKeys[key] = s;
  }

  _writeJsonMap(trFile, trMap);
  _writeJsonMap(enFile, enMap);

  final replaceStats = ReplaceStats();
  final replacedFiles = await _replaceInDartFiles(stringToKey, replaceStats);

  final report = StringBuffer()
    ..writeln('# Migrate Top Strings To ARB Report')
    ..writeln()
    ..writeln('- Generated: ${DateTime.now().toIso8601String()}')
    ..writeln('- Parsed top strings: ${topStrings.length}')
    ..writeln('- Added keys: ${addedKeys.length}')
    ..writeln('- Replaced occurrences: ${replaceStats.totalReplaced}')
    ..writeln('- Files touched: ${replacedFiles.length}')
    ..writeln()
    ..writeln('## Added Keys')
    ..writeln()
    ..writeln('| Key | TR Value |')
    ..writeln('|---|---|');
  for (final entry in addedKeys.entries) {
    report.writeln('| ${entry.key} | ${entry.value.replaceAll('|', r'\|')} |');
  }

  report
    ..writeln()
    ..writeln('## Replaced Occurrences By Pattern')
    ..writeln()
    ..writeln('| Pattern | Count |')
    ..writeln('|---|---:|');
  for (final entry in replaceStats.replacedByPattern.entries) {
    report.writeln('| ${entry.key} | ${entry.value} |');
  }

  report
    ..writeln()
    ..writeln('## Skipped Occurrences')
    ..writeln()
    ..writeln('| Reason | Count |')
    ..writeln('|---|---:|');
  for (final entry in replaceStats.skippedByReason.entries) {
    report.writeln('| ${entry.key} | ${entry.value} |');
  }

  report
    ..writeln()
    ..writeln('## Skipped Samples')
    ..writeln();
  for (final sample in replaceStats.skippedSamples) {
    report.writeln('- $sample');
  }

  final migrateReport = File('tools/migrate_report.md');
  migrateReport.writeAsStringSync(report.toString());

  stdout.writeln('Added keys: ${addedKeys.length}');
  stdout.writeln('Replaced occurrences: ${replaceStats.totalReplaced}');
  stdout.writeln('Report: ${migrateReport.path}');
}

List<String> _parseTopStrings(String markdown, int limit) {
  final lines = const LineSplitter().convert(markdown);
  final result = <String>[];
  var inSection = false;
  for (final line in lines) {
    if (line.startsWith('## 1) Top 50')) {
      inSection = true;
      continue;
    }
    if (!inSection) continue;
    if (line.startsWith('## 2)')) break;
    if (!line.startsWith('|')) continue;
    if (line.contains('| # |') || line.contains('|---|')) continue;

    final cols = _splitMdRow(line);
    if (cols.length < 4) continue;
    final rank = int.tryParse(cols[0].trim());
    if (rank == null || rank > limit) continue;
    final value = cols[1].trim();
    if (value.isEmpty) continue;
    result.add(value.replaceAll(r'\|', '|'));
  }
  return result;
}

List<String> _splitMdRow(String line) {
  final trimmed = line.trim();
  var body = trimmed;
  if (body.startsWith('|')) body = body.substring(1);
  if (body.endsWith('|')) body = body.substring(0, body.length - 1);
  return body.split('|').map((e) => e.trim()).toList();
}

Map<String, dynamic> _readJsonMap(File file) {
  final raw = file.readAsStringSync();
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw StateError('${file.path} is not a JSON object');
  }
  return Map<String, dynamic>.from(decoded);
}

void _writeJsonMap(File file, Map<String, dynamic> map) {
  final encoder = const JsonEncoder.withIndent('  ');
  file.writeAsStringSync('${encoder.convert(map)}\n');
}

String? _findExistingKeyForValue(Map<String, dynamic> arb, String value) {
  for (final entry in arb.entries) {
    if (entry.key.startsWith('@')) continue;
    if (entry.value == value) return entry.key;
  }
  return null;
}

String _dedupeKey(String base, Set<String> used) {
  if (!used.contains(base)) return base;
  var i = 2;
  while (used.contains('${base}_$i')) {
    i++;
  }
  return '${base}_$i';
}

String _buildKey(String source) {
  final preferred = _preferredKeys[source];
  if (preferred != null) return preferred;

  final normalized = _turkishToAscii(source)
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
  if (normalized.isEmpty) return 'text';
  final parts = normalized.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'text';
  final first = parts.first;
  final rest = parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  var key = '$first$rest';
  if (RegExp(r'^[0-9]').hasMatch(key)) {
    key = 'text$key';
  }
  return key;
}

String _turkishToAscii(String s) {
  const map = <String, String>{
    'ÅŸ': 's',
    'Å': 's',
    'Ä±': 'i',
    'Ä°': 'i',
    'ÄŸ': 'g',
    'Ä': 'g',
    'Ã¼': 'u',
    'Ãœ': 'u',
    'Ã¶': 'o',
    'Ã–': 'o',
    'Ã§': 'c',
    'Ã‡': 'c',
  };
  final buffer = StringBuffer();
  for (final rune in s.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(map[ch] ?? ch);
  }
  return buffer.toString();
}

bool _shouldSkipLiteralForArb(String s) {
  if (s.trim().isEmpty) return true;
  if (s.contains(r'$') || s.contains('{') || s.contains('}')) return true;
  if (s.length > 180) return true;
  return false;
}

Future<List<String>> _replaceInDartFiles(
  Map<String, String> stringToKey,
  ReplaceStats stats,
) async {
  final touched = <String>[];
  final lib = Directory('lib');
  final files = await lib
      .list(recursive: true, followLinks: false)
      .where((e) => e is File && e.path.endsWith('.dart'))
      .cast<File>()
      .toList();

  for (final file in files) {
    final path = file.path.replaceAll('\\', '/');
    if (path.contains('/l10n/')) continue;

    var content = await file.readAsString();
    final original = content;

    if (!content.contains('BuildContext context')) {
      for (final s in stringToKey.keys) {
        if (content.contains("'$s'") || content.contains('"$s"')) {
          stats.skipped('no_context', '$path -> $s');
        }
      }
      continue;
    }

    var localReplaced = 0;
    for (final entry in stringToKey.entries) {
      final literal = entry.key;
      final key = entry.value;
      if (literal.length > 80) {
        stats.skipped('too_long_for_replace', '$path -> $literal');
        continue;
      }
      if (_looksLikeUrlOrPath(literal)) {
        stats.skipped('url_or_path', '$path -> $literal');
        continue;
      }

      final replaceResult = _replaceSafe(content, literal, key, stats, path);
      content = replaceResult.$1;
      localReplaced += replaceResult.$2;
    }

    if (localReplaced <= 0) continue;

    if (!content.contains('AppLocalizations.of(context)')) {
      final buildRegex = RegExp(r'Widget\s+build\s*\(\s*BuildContext\s+context\s*\)\s*\{');
      final m = buildRegex.firstMatch(content);
      if (m == null) {
        stats.skipped('no_build_scope', path);
        continue;
      }
      final insertAt = m.end;
      content =
          '${content.substring(0, insertAt)}\n    final t = AppLocalizations.of(context);${content.substring(insertAt)}';
    }

    if (!content.contains('AppLocalizations') &&
        !content.contains("core/i18n/app_localizations.dart")) {
      final importLine = "import 'package:yeedoy/l10n/app_localizations.dart';\n";
      final imports =
          RegExp(r'''^import\s+['"].+['"];\s*$''', multiLine: true)
              .allMatches(content)
              .toList();
      if (imports.isNotEmpty) {
        final last = imports.last;
        content = '${content.substring(0, last.end)}\n$importLine${content.substring(last.end)}';
      } else {
        content = '$importLine\n$content';
      }
    }

    if (content != original) {
      await file.writeAsString(content);
      touched.add(path);
    }
  }

  return touched;
}

bool _looksLikeUrlOrPath(String s) {
  final l = s.toLowerCase();
  return l.contains('http://') ||
      l.contains('https://') ||
      l.contains('assets/') ||
      l.contains('package:') ||
      l.endsWith('.png') ||
      l.endsWith('.jpg') ||
      l.endsWith('.jpeg') ||
      l.endsWith('.svg') ||
      l.endsWith('.dart');
}

(String, int) _replaceSafe(
  String input,
  String literal,
  String key,
  ReplaceStats stats,
  String path,
) {
  var output = input;
  var replaced = 0;

  String esc(String s) => RegExp.escape(s);

  String replaceWithCount(String src, RegExp reg, String Function(Match) repl, String patternName) {
    return src.replaceAllMapped(reg, (m) {
      final lineStart = src.lastIndexOf('\n', m.start);
      final lineEnd = src.indexOf('\n', m.start);
      final lStart = lineStart == -1 ? 0 : lineStart + 1;
      final lEnd = lineEnd == -1 ? src.length : lineEnd;
      final line = src.substring(lStart, lEnd);
      if (line.contains('const ')) {
        stats.skipped('const_context', '$path -> $literal');
        return m.group(0)!;
      }
      replaced++;
      stats.replaced(patternName);
      return repl(m);
    });
  }

  final textRegex = RegExp("Text\\(\\s*'${esc(literal)}'\\s*\\)");
  output = replaceWithCount(
    output,
    textRegex,
    (_) => 'Text(t.$key)',
    'Text(literal)',
  );
  final textRegexD = RegExp('Text\\(\\s*"${esc(literal)}"\\s*\\)');
  output = replaceWithCount(
    output,
    textRegexD,
    (_) => 'Text(t.$key)',
    'Text(literal)',
  );

  final namedFields = <String>[
    'title',
    'labelText',
    'hintText',
    'helperText',
    'tooltip',
  ];
  for (final field in namedFields) {
    final r1 = RegExp("$field\\s*:\\s*'${esc(literal)}'");
    output = replaceWithCount(
      output,
      r1,
      (_) => '$field: t.$key',
      '$field literal',
    );
    final r2 = RegExp('$field\\s*:\\s*"${esc(literal)}"');
    output = replaceWithCount(
      output,
      r2,
      (_) => '$field: t.$key',
      '$field literal',
    );
  }

  final sb1 = RegExp("SnackBar\\(\\s*content\\s*:\\s*Text\\(\\s*'${esc(literal)}'\\s*\\)\\s*\\)");
  output = replaceWithCount(
    output,
    sb1,
    (_) => 'SnackBar(content: Text(t.$key))',
    'SnackBar(Text(literal))',
  );
  final sb2 = RegExp('SnackBar\\(\\s*content\\s*:\\s*Text\\(\\s*"${esc(literal)}"\\s*\\)\\s*\\)');
  output = replaceWithCount(
    output,
    sb2,
    (_) => 'SnackBar(content: Text(t.$key))',
    'SnackBar(Text(literal))',
  );

  return (output, replaced);
}

