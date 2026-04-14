#!/usr/bin/env node
/**
 * validate-panel-url.mjs
 *
 * Pre-release environment validation for NEXT_PUBLIC_PANEL_URL.
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
 *   node scripts/validate-panel-url.mjs
 *   NEXT_PUBLIC_PANEL_URL=https://panel.example.com node scripts/validate-panel-url.mjs
 */

const raw = process.env.NEXT_PUBLIC_PANEL_URL?.trim();

let valid = true;

function fail(message) {
  console.error(`[validate-panel-url] FAIL: ${message}`);
  valid = false;
}

function info(message) {
  console.log(`[validate-panel-url] ${message}`);
}

if (!raw) {
  fail('NEXT_PUBLIC_PANEL_URL is not set or empty.');
  fail(
    'This variable is required for the panel → QR Studio handoff login flow.',
  );
  process.exit(1);
}

let parsed;
try {
  parsed = new URL(raw);
} catch {
  fail(`"${raw}" is not a valid URL.`);
  process.exit(1);
}

if (parsed.protocol !== 'https:' && parsed.hostname !== 'localhost' && parsed.hostname !== '127.0.0.1') {
  fail(
    `Protocol must be "https:" in production (got "${parsed.protocol}"). ` +
      'http is only allowed for localhost.',
  );
  valid = false;
}

if (raw.endsWith('/')) {
  fail(
    `URL must not end with a trailing slash (got "${raw}"). ` +
      'The Flutter panel constructs paths by appending directly to this value.',
  );
  valid = false;
}

if (parsed.pathname !== '/') {
  fail(
    `URL must be an origin (no path component). Got path "${parsed.pathname}". ` +
      'Use just the scheme + host, e.g. https://panel.example.com',
  );
  valid = false;
}

if (!valid) {
  process.exit(1);
}

info(`OK: NEXT_PUBLIC_PANEL_URL="${raw}" (origin: ${parsed.origin})`);
process.exit(0);
