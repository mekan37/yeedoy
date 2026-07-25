import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(process.cwd(), '..', '..');
const mobileTr = path.join(root, 'uygulamalar/mobil/lib/l10n/app_tr.arb');
const mobileEn = path.join(root, 'uygulamalar/mobil/lib/l10n/app_en.arb');

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

const tr = readJson(mobileTr);
const en = readJson(mobileEn);
const trKeys = new Set(Object.keys(tr).filter((k) => !k.startsWith('@')));
const enKeys = new Set(Object.keys(en).filter((k) => !k.startsWith('@')));

const missingInEn = [...trKeys].filter((k) => !enKeys.has(k)).sort();
const missingInTr = [...enKeys].filter((k) => !trKeys.has(k)).sort();

const out = [
  '# Missing l10n Keys Report',
  '',
  `- Missing in EN: ${missingInEn.length}`,
  `- Missing in TR: ${missingInTr.length}`,
  '',
  '## Missing in EN',
  ...missingInEn.map((k) => `- ${k}`),
  '',
  '## Missing in TR',
  ...missingInTr.map((k) => `- ${k}`),
  '',
].join('\n');

const outDir = path.join(root, 'packages/l10n_assets/reports');
fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(path.join(outDir, 'missing_keys_report.md'), out, 'utf8');
console.log('wrote packages/l10n_assets/reports/missing_keys_report.md');
