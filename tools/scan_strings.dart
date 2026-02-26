import 'dart:io';

final _literalRegex = RegExp(
  r'''([rR]?)(\'(?:\\.|[^\'\\\n])*\'|"(?:\\.|[^"\\\n])*")''',
);

final _multiSpaceRegex = RegExp(r'\s+');
final _hexRegex = RegExp(r'^#?[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$');

const _uiTokens = <String>[
  'Text(',
  'title:',
  'label:',
  'hintText:',
  'helperText:',
  'SnackBar(',
  'AppBar(',
  'ElevatedButton(',
  'FilledButton(',
  'OutlinedButton(',
  'TextButton(',
  'tooltip:',
  'semanticLabel:',
];

class Hit {
  Hit(this.value);

  final String value;
  int count = 0;
  final Set<String> samples = <String>{};
}

void main() async {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln('lib/ klasoru bulunamadi.');
    exitCode = 1;
    return;
  }

  final hits = <String, Hit>{};
  final perFileCount = <String, int>{};
  final skipped = <String, int>{
    'non_ui_context': 0,
    'interpolated': 0,
    'too_short': 0,
    'url_or_asset_or_import': 0,
    'path_like_or_hex': 0,
    'empty_or_blank': 0,
  };

  final files = await libDir
      .list(recursive: true, followLinks: false)
      .where((e) => e is File && e.path.endsWith('.dart'))
      .cast<File>()
      .toList();
  files.sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final relPath = _toRelative(file.path);
    final lines = await file.readAsLines();
    var fileHitCount = 0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('import ') ||
          trimmed.startsWith('export ') ||
          trimmed.startsWith('part ')) {
        continue;
      }

      final hasUiContext = _hasUiContext(lines, i);

      for (final m in _literalRegex.allMatches(line)) {
        var rawToken = m.group(2);
        if (rawToken == null || rawToken.length < 2) continue;

        final isRaw = (m.group(1) ?? '').toLowerCase() == 'r';
        if (isRaw) {
          rawToken = rawToken.substring(1);
        }

        final quote = rawToken[0];
        if ((quote != "'" && quote != '"') || rawToken[rawToken.length - 1] != quote) {
          continue;
        }

        var value = rawToken.substring(1, rawToken.length - 1);
        if (!isRaw) {
          value = value
              .replaceAll(r"\'", "'")
              .replaceAll(r'\"', '"')
              .replaceAll(r'\n', ' ')
              .replaceAll(r'\t', ' ');
        }

        if (!hasUiContext) {
          skipped['non_ui_context'] = skipped['non_ui_context']! + 1;
          continue;
        }
        if (value.contains(r'$')) {
          skipped['interpolated'] = skipped['interpolated']! + 1;
          continue;
        }

        final normalized = _normalize(value);
        if (normalized.isEmpty) {
          skipped['empty_or_blank'] = skipped['empty_or_blank']! + 1;
          continue;
        }

        if (normalized.length <= 2 && normalized.toUpperCase() != 'OK') {
          skipped['too_short'] = skipped['too_short']! + 1;
          continue;
        }

        if (_looksLikeUrlAssetOrImport(normalized)) {
          skipped['url_or_asset_or_import'] = skipped['url_or_asset_or_import']! + 1;
          continue;
        }
        if (_looksLikePathOrHex(normalized)) {
          skipped['path_like_or_hex'] = skipped['path_like_or_hex']! + 1;
          continue;
        }

        final hit = hits.putIfAbsent(normalized, () => Hit(normalized));
        hit.count++;
        if (hit.samples.length < 8) {
          hit.samples.add('$relPath:${i + 1}');
        }
        fileHitCount++;
      }
    }

    if (fileHitCount > 0) {
      perFileCount[relPath] = fileHitCount;
    }
  }

  final sortedHits = hits.values.toList()
    ..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      return a.value.compareTo(b.value);
    });

  final sortedFiles = perFileCount.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final buffer = StringBuffer()
    ..writeln('# Candidate UI Strings Report')
    ..writeln()
    ..writeln('- Generated: ${DateTime.now().toIso8601String()}')
    ..writeln('- Scanned files: ${files.length}')
    ..writeln('- Unique candidate strings: ${hits.length}')
    ..writeln()
    ..writeln('## 1) Top 50 Most Frequent Strings')
    ..writeln()
    ..writeln('| # | String | Count | Sample Locations |')
    ..writeln('|---|---|---:|---|');

  final top = sortedHits.take(50).toList();
  for (var i = 0; i < top.length; i++) {
    final hit = top[i];
    final samples = hit.samples.join('<br>');
    final safeString = hit.value.replaceAll('|', r'\|');
    buffer.writeln('| ${i + 1} | $safeString | ${hit.count} | $samples |');
  }

  buffer
    ..writeln()
    ..writeln('## 2) Per-file Summary')
    ..writeln()
    ..writeln('| File | Candidate Count |')
    ..writeln('|---|---:|');
  for (final entry in sortedFiles) {
    buffer.writeln('| ${entry.key} | ${entry.value} |');
  }

  buffer
    ..writeln()
    ..writeln('## 3) Skipped Patterns Summary')
    ..writeln()
    ..writeln('| Pattern | Count |')
    ..writeln('|---|---:|');
  for (final entry in skipped.entries) {
    buffer.writeln('| ${entry.key} | ${entry.value} |');
  }

  final report = File('candidate_strings_report.md');
  await report.writeAsString(buffer.toString());
  stdout.writeln('Report generated: ${report.path}');
}

bool _hasUiContext(List<String> lines, int index) {
  final start = index > 0 ? index - 1 : index;
  final end = index + 1 < lines.length ? index + 1 : index;
  final window = lines.sublist(start, end + 1).join('\n');
  for (final token in _uiTokens) {
    if (window.contains(token)) return true;
  }
  return false;
}

String _normalize(String input) {
  return input.trim().replaceAll(_multiSpaceRegex, ' ');
}

bool _looksLikeUrlAssetOrImport(String s) {
  final lower = s.toLowerCase();
  return lower.contains('http://') ||
      lower.contains('https://') ||
      lower.contains('package:') ||
      lower.contains('assets/') ||
      lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.svg') ||
      lower.endsWith('.webp');
}

bool _looksLikePathOrHex(String s) {
  final lower = s.toLowerCase();
  if (_hexRegex.hasMatch(s)) return true;
  if ((lower.startsWith('/') || lower.startsWith('./') || lower.startsWith('../')) &&
      !s.contains(' ')) {
    return true;
  }
  if ((lower.contains('\\') || lower.contains('/')) && !s.contains(' ')) {
    return true;
  }
  if (lower.endsWith('.dart') || lower.endsWith('.json') || lower.endsWith('.yaml')) {
    return true;
  }
  return false;
}

String _toRelative(String path) {
  final normalized = path.replaceAll('\\', '/');
  const marker = '/lib/';
  final idx = normalized.lastIndexOf(marker);
  if (idx == -1) return normalized;
  return normalized.substring(idx + 1);
}
