#!/usr/bin/env node
/**
 * sync-l10n.mjs
 *
 * Syncs shared localization keys from common_en.arb / common_tr.arb into
 * both app ARB files.
 *
 * Usage (from monorepo root):
 *   node packages/l10n_assets/scripts/sync-l10n.mjs
 *
 * Or via package script (from packages/l10n_assets/):
 *   npm run sync-l10n
 */

import { readFileSync, writeFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Resolve paths relative to this script's location (packages/l10n_assets/scripts/)
const pkg = resolve(__dirname, '..');
const root = resolve(pkg, '../..');

const COMMON_EN = resolve(pkg, 'common_en.arb');
const COMMON_TR = resolve(pkg, 'common_tr.arb');

const TARGETS = [
  { path: resolve(root, 'apps/mobile_flutter/lib/l10n/app_en.arb'), locale: 'en', label: 'mobile/en' },
  { path: resolve(root, 'apps/mobile_flutter/lib/l10n/app_tr.arb'), locale: 'tr', label: 'mobile/tr' },
  { path: resolve(root, 'apps/panel_flutter_web/lib/l10n/app_en.arb'), locale: 'en', label: 'panel/en' },
  { path: resolve(root, 'apps/panel_flutter_web/lib/l10n/app_tr.arb'), locale: 'tr', label: 'panel/tr' },
];

// ── helpers ───────────────────────────────────────────────────────────────────

function readArb(filePath) {
  try {
    return JSON.parse(readFileSync(filePath, 'utf8'));
  } catch (err) {
    console.error(`ERROR: Could not read or parse ${filePath}`);
    console.error(`       ${err.message}`);
    process.exit(1);
  }
}

/**
 * Returns all content keys (non-@ and non-@@) from an ARB object.
 */
function contentKeys(arb) {
  return Object.keys(arb).filter(k => !k.startsWith('@'));
}

/**
 * Merge common keys (and their @metadata) into a target ARB object.
 * Returns { merged, synced, overwritten }.
 */
function mergeCommonIntoTarget(common, target) {
  const synced = [];
  const overwritten = [];

  const keys = contentKeys(common);

  for (const key of keys) {
    const commonVal = common[key];
    const targetVal = target[key];

    if (targetVal !== undefined && targetVal !== commonVal) {
      overwritten.push({ key, was: targetVal, now: commonVal });
    }

    target[key] = commonVal;
    synced.push(key);

    // Sync @metadata if present in common
    const metaKey = '@' + key;
    if (common[metaKey] !== undefined) {
      target[metaKey] = common[metaKey];
    }
  }

  return { synced, overwritten };
}

/**
 * Re-order keys in a target ARB so that:
 *  1. @@locale comes first
 *  2. All other entries follow in their original order (preserving app-specific keys)
 * The function does NOT reorder beyond keeping @@locale at the top.
 */
function stabilizeOrder(arb) {
  const result = {};
  if (arb['@@locale'] !== undefined) result['@@locale'] = arb['@@locale'];
  for (const [k, v] of Object.entries(arb)) {
    if (k !== '@@locale') result[k] = v;
  }
  return result;
}

// ── main ──────────────────────────────────────────────────────────────────────

console.log('');
console.log('sync-l10n: Reading common ARB sources...');

const commonEn = readArb(COMMON_EN);
const commonTr = readArb(COMMON_TR);

const commonEnKeys = contentKeys(commonEn);
const commonTrKeys = contentKeys(commonTr);

console.log(`  common_en.arb  →  ${commonEnKeys.length} keys`);
console.log(`  common_tr.arb  →  ${commonTrKeys.length} keys`);
console.log('');

let totalSynced = 0;
let totalOverwritten = 0;

for (const target of TARGETS) {
  const common = target.locale === 'en' ? commonEn : commonTr;
  const arb = readArb(target.path);

  const { synced, overwritten } = mergeCommonIntoTarget(common, arb);
  const stable = stabilizeOrder(arb);

  writeFileSync(target.path, JSON.stringify(stable, null, 2) + '\n', 'utf8');

  totalSynced += synced.length;
  totalOverwritten += overwritten.length;

  console.log(`  [${target.label}]  synced ${synced.length} keys`);

  if (overwritten.length > 0) {
    console.log(`    OVERWRITTEN (${overwritten.length} values differed):`);
    for (const diff of overwritten) {
      console.log(`      "${diff.key}"`);
      console.log(`        was: ${JSON.stringify(diff.was)}`);
      console.log(`        now: ${JSON.stringify(diff.now)}`);
    }
  }
}

console.log('');
console.log(`sync-l10n: Done.`);
console.log(`  Total keys synced : ${totalSynced} (across ${TARGETS.length} files)`);
console.log(`  Values overwritten: ${totalOverwritten}`);
console.log('');
console.log('Next steps:');
console.log('  1. Review any overwritten values above.');
console.log('  2. Run flutter gen-l10n inside each app if translations changed.');
console.log('  3. To edit a shared key, always edit common_en.arb / common_tr.arb,');
console.log('     then re-run this script — never edit app ARB files directly for shared keys.');
console.log('');
