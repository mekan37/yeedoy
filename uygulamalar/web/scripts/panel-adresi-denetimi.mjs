#!/usr/bin/env node
/**
 * panel-adresi-denetimi.mjs
 *
 * SURUM_ONCESI ortam dogrulamasi: NEXT_PUBLIC_PANEL_URL.
 *
 * Checks:
 *  1. Variable is set and non-empty
 *  2. Value is a parseable, absolute URL
 *  3. Protocol is https (required in production; http allowed only for localhost)
 *  4. No trailing slash (Flutter panel constructs paths by appending directly)
 *
 * Exit code 0 = valid, 1 = invalid (CI will fail the step).
 *
 * Usage:
 *   node scripts/panel-adresi-denetimi.mjs
 *   NEXT_PUBLIC_PANEL_URL=https://panel.example.com node scripts/panel-adresi-denetimi.mjs
 */

const raw = process.env.NEXT_PUBLIC_PANEL_URL?.trim();

let valid = true;

function fail(message) {
  console.error(`[panel-adresi-denetimi] HATA: ${message}`);
  valid = false;
}

function info(message) {
  console.log(`[panel-adresi-denetimi] ${message}`);
}

if (!raw) {
  // Flutter panel uygulaması kaldırıldı (2026-05-04). Devir rotası backward-compat
  // amacıyla korunuyor ancak NEXT_PUBLIC_PANEL_URL artık zorunlu değil.
  info('NEXT_PUBLIC_PANEL_URL ayarlanmamis — devir dogrulama atlanıyor (opsiyonel).');
  process.exit(0);
}

let parsed;
try {
  parsed = new URL(raw);
} catch {
  fail(`"${raw}" gecerli bir URL degil.`);
  process.exit(1);
}

if (parsed.protocol !== 'https:' && parsed.hostname !== 'localhost' && parsed.hostname !== '127.0.0.1') {
  fail(
    `Uretimde protokol "https:" olmali (gelen "${parsed.protocol}"). ` +
      'http yalnizca localhost icin kabul edilir.',
  );
  valid = false;
}

if (raw.endsWith('/')) {
  fail(
    `URL sonunda "/" olmamali (gelen "${raw}"). ` +
      'Flutter panel bu degeri dogrudan ekleyerek yol olusturur.',
  );
  valid = false;
}

if (parsed.pathname !== '/') {
  fail(
    `URL bir origin olmali (yol parcasi olmamali). Gelen yol "${parsed.pathname}". ` +
      'Yalnizca scheme + host kullanin, ornegin https://panel.example.com',
  );
  valid = false;
}

if (!valid) {
  process.exit(1);
}

info(`TAMAM: NEXT_PUBLIC_PANEL_URL="${raw}" (origin: ${parsed.origin})`);
process.exit(0);
