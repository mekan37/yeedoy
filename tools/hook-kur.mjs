/**
 * Installs local git hooks for the Yeedoy monorepo.
 * Run once: node tools/hook-kur.mjs
 *
 * Hooks installed:
 * - pre-commit: runs hardcoded color check + l10n audit (fast path only)
 */
import { execSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const hooksDir = path.join(repoRoot, '.git', 'hooks');

if (!fs.existsSync(hooksDir)) {
  console.error('No .git/hooks directory found. Run from repo root.');
  process.exit(1);
}

const preCommitScript = `#!/bin/sh
# Yeedoy pre-commit hook (installed by tools/hook-kur.mjs)
set -e

echo "[pre-commit] Running hardcoded color check..."
cd uygulamalar/mobil && dart run tool/hardcoded_color_check.dart && cd ../..

echo "[pre-commit] Running l10n audit..."
node tools/ceviri-denetimi.mjs

echo "[pre-commit] All checks passed."
`;

const hookPath = path.join(hooksDir, 'pre-commit');
fs.writeFileSync(hookPath, preCommitScript, { mode: 0o755 });
console.log(`Installed pre-commit hook at: ${hookPath}`);
console.log('Hooks: hardcoded color check, l10n audit');
