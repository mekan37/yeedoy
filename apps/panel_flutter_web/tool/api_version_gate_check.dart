import 'dart:io';

final _rpcRegex = RegExp(r"rpc\(\s*'([^']+)'");
final _versionedName = RegExp(r'_v\d+$');

Future<void> main() async {
  final root = Directory('lib');
  if (!await root.exists()) {
    stderr.writeln('lib/ not found');
    exitCode = 66;
    return;
  }

  final bad = <String>[];
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final content = await entity.readAsString();
    for (final match in _rpcRegex.allMatches(content)) {
      final rpcName = match.group(1) ?? '';
      if (rpcName.isEmpty) continue;
      if (_versionedName.hasMatch(rpcName)) continue;
      bad.add('${entity.path}:$rpcName');
    }
  }

  if (bad.isEmpty) {
    stdout.writeln('API_VERSION_GATE: PASS');
    return;
  }

  stdout.writeln('API_VERSION_GATE: BLOCK');
  for (final entry in bad) {
    stdout.writeln('- $entry');
  }
  exitCode = 1;
}
