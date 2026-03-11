import fs from 'node:fs';
import path from 'node:path';
import { defineConfig, devices } from '@playwright/test';

const shellEnvKeys = new Set(Object.keys(process.env));

loadEnvFile('.env.local');
loadEnvFile('.env.playwright.local', { overrideLoadedValues: true });

const port = Number(process.env.PLAYWRIGHT_PORT ?? 3200);
const useProductionServer = process.env.PLAYWRIGHT_USE_START === 'true';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'list',
  use: {
    baseURL: `http://127.0.0.1:${port}`,
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  webServer: {
    command: useProductionServer
      ? `npm run build && npm run start -- --port ${port}`
      : `npm run dev -- --port ${port}`,
    port,
    reuseExistingServer: !process.env.CI,
    timeout: useProductionServer ? 240_000 : 120_000,
  },
});

function loadEnvFile(fileName: string, options?: { overrideLoadedValues?: boolean }) {
  const filePath = path.join(process.cwd(), fileName);
  if (!fs.existsSync(filePath)) return;

  const contents = fs.readFileSync(filePath, 'utf8');
  for (const rawLine of contents.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;

    const separatorIndex = line.indexOf('=');
    if (separatorIndex <= 0) continue;

    const key = line.slice(0, separatorIndex).trim();
    if (!key || shellEnvKeys.has(key)) continue;

    const value = line
      .slice(separatorIndex + 1)
      .trim()
      .replace(/^['"]|['"]$/g, '');

    if (options?.overrideLoadedValues || !process.env[key]) {
      process.env[key] = value;
    }
  }
}
