import fs from 'node:fs';
import path from 'node:path';

const repoRoot = process.cwd();
const arbFiles = [
  'apps/mobile_flutter/lib/l10n/app_en.arb',
  'apps/mobile_flutter/lib/l10n/app_tr.arb',
  'apps/panel_flutter_web/lib/l10n/app_en.arb',
  'apps/panel_flutter_web/lib/l10n/app_tr.arb',
];

const dartFiles = [
  'apps/mobile_flutter/lib/l10n/app_localizations_en.dart',
  'apps/mobile_flutter/lib/l10n/app_localizations_tr.dart',
  'apps/panel_flutter_web/lib/l10n/app_localizations_en.dart',
  'apps/panel_flutter_web/lib/l10n/app_localizations_tr.dart',
];

const issues = [];

for (const relPath of arbFiles) {
  const absPath = path.join(repoRoot, relPath);
  const raw = fs.readFileSync(absPath, 'utf8');
  const json = JSON.parse(raw);

  for (const [key, value] of Object.entries(json)) {
    if (typeof value === 'string' && value.includes('TODO_EN:')) {
      issues.push(`${relPath} -> key "${key}" contains TODO_EN placeholder`);
    }

    if (key.startsWith('@') && value && typeof value === 'object') {
      const description = value.description;
      if (typeof description === 'string' && description.trim().startsWith('TODO:')) {
        issues.push(`${relPath} -> metadata "${key}" has TODO description`);
      }
    }
  }
}

for (const relPath of dartFiles) {
  const absPath = path.join(repoRoot, relPath);
  const raw = fs.readFileSync(absPath, 'utf8');
  const lines = raw.split(/\r?\n/);
  for (let i = 0; i < lines.length; i += 1) {
    if (lines[i].includes('TODO_EN:')) {
      issues.push(`${relPath}:${i + 1} contains TODO_EN placeholder`);
    }
  }
}

if (issues.length > 0) {
  console.error(`l10n audit failed with ${issues.length} issue(s):`);
  for (const issue of issues) {
    console.error(`- ${issue}`);
  }
  process.exit(1);
}

console.log('l10n audit passed');
