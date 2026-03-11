const { defineConfig, devices } = require('../web_next/node_modules/@playwright/test');

const port = Number(process.env.PANEL_SMOKE_PORT ?? 43101);

module.exports = defineConfig({
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
    command: 'npm run build:smoke && npm run serve:smoke',
    port,
    reuseExistingServer: false,
    timeout: 300_000,
  },
});
