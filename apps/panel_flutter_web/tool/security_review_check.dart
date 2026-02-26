import 'dart:io';

final _directWritePattern = RegExp(
  r"\.from\([^)]*\)\s*\.(insert|update|upsert|delete)\(",
);
final _rpcWritePattern = RegExp(r"\.rpc\(\s*'([^']+)'");

const _criticalRpcPrefixes = <String>[
  'submit_',
  'owner_',
  'admin_',
  'vote_',
  'toggle_',
  'add_',
  'update_',
  'delete_',
];

const _allowlistPathContains = <String>[
  'core/security/write_gatekeeper_client.dart',
  'core/security/admin_api_client.dart',
  'src/features/admin/',
  'supabase/',
];

bool _isAllowedPath(String path) {
  final normalized = path.replaceAll('\\', '/');
  for (final allowed in _allowlistPathContains) {
    if (normalized.contains(allowed)) return true;
  }
  return false;
}

void main(List<String> args) {
  final strict = args.contains('--strict');
  final root = Directory('lib');
  if (!root.existsSync()) {
    stderr.writeln('lib directory not found');
    exitCode = 2;
    return;
  }

  final findings = <String>[];
  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    final path = file.path;
    if (_isAllowedPath(path)) continue;
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_directWritePattern.hasMatch(line)) {
        findings.add('$path:${i + 1} direct_db_write');
      }
      final rpc = _rpcWritePattern.firstMatch(line);
      if (rpc != null) {
        final name = (rpc.group(1) ?? '').toLowerCase();
        final isCritical = _criticalRpcPrefixes.any(name.startsWith);
        if (isCritical) {
          findings.add('$path:${i + 1} critical_rpc:$name');
        }
      }
    }
  }

  if (findings.isEmpty) {
    stdout.writeln('SECURITY_REVIEW: PASS (no critical direct writes found)');
    return;
  }

  stdout.writeln('SECURITY_REVIEW: FINDINGS (${findings.length})');
  for (final item in findings.take(200)) {
    stdout.writeln('- $item');
  }

  if (strict) {
    exitCode = 1;
  }
}
