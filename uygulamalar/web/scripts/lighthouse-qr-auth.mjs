import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { chromium } from '@playwright/test';
import {
  createReportDir,
  discoverOwnerTarget,
  issueMagicLinkSession,
  loadEnvFiles,
  requireEnv,
  resolveAvailablePort,
  runLighthouseAudit,
  startServer,
  stopServer,
  waitForServer,
  writePerfMarkdown,
  writeSummaryFiles,
} from './lighthouse-shared.mjs';

loadEnvFiles();

const fallbackBusinessId = requireEnv('PLAYWRIGHT_SMOKE_BUSINESS_ID');
const lang = process.env.PLAYWRIGHT_SMOKE_LANG?.trim() || 'tr';
const theme = 'bold';
const preferredPort = Number(process.env.PERF_PORT ?? 3400);
const port = await resolveAvailablePort(preferredPort);
const chromePort = await resolveAvailablePort(port + 30);
const baseUrl = `http://127.0.0.1:${port}`;
const { reportDir } = createReportDir();

const server = startServer(port);

try {
  await waitForServer(baseUrl);

  const ownerTarget = await discoverOwnerTarget(fallbackBusinessId);
  const qrRequestedUrl = `${baseUrl}/karekod/${ownerTarget.businessId}?lang=${lang}&theme=${theme}`;
  const userDataDir = fs.mkdtempSync(path.join(os.tmpdir(), 'yeedoy-qr-lh-'));
  const context = await chromium.launchPersistentContext(userDataDir, {
    headless: true,
    args: [`--remote-debugging-port=${chromePort}`],
  });

  try {
    const page = await context.newPage();

    if (process.env.LH_OWNER_EMAIL?.trim() && process.env.LH_OWNER_PASSWORD?.trim()) {
      await page.goto(
        `${baseUrl}/giris?redirect=${encodeURIComponent(`/karekod/${ownerTarget.businessId}?lang=${lang}&theme=${theme}`)}`,
        { waitUntil: 'networkidle' },
      );
      await page.locator('input[type="email"]').fill(process.env.LH_OWNER_EMAIL.trim());
      await page.locator('input[type="password"]').fill(process.env.LH_OWNER_PASSWORD.trim());
      await page.getByRole('button', { name: 'Giriş Yap' }).click();
    } else {
      const session = await issueMagicLinkSession(ownerTarget.ownerEmail);
      await page.setContent(
        `<form id="handoff" method="post" action="${baseUrl}/auth/panel-handoff">
          <input name="access_token" value="${session.accessToken}" />
          <input name="refresh_token" value="${session.refreshToken}" />
          <input name="business_id" value="${ownerTarget.businessId}" />
          <input name="lang" value="${lang}" />
          <input name="theme" value="${theme}" />
        </form>
        <script>document.getElementById('handoff').submit();</script>`,
        { waitUntil: 'domcontentloaded' },
      );
    }

    await page.waitForURL(`**/karekod/${ownerTarget.businessId}**`, { timeout: 30_000 });
    await page.getByText('QR Studio', { exact: true }).waitFor({ timeout: 30_000 });

    const report = await runLighthouseAudit({
      chromePort,
      slug: 'qr-auth',
      label: '/karekod/:businessId?theme=bold (authenticated)',
      requestedUrl: qrRequestedUrl,
      reportDir,
      disableStorageReset: true,
    });

    if (!report.finalUrl.includes(`/karekod/${ownerTarget.businessId}`)) {
      throw new Error(`Authenticated QR Studio audit resolved to unexpected finalUrl: ${report.finalUrl}`);
    }

    writeSummaryFiles(report);
    writePerfMarkdown();
  } finally {
    await context.close();
    fs.rmSync(userDataDir, { recursive: true, force: true });
  }
} finally {
  await stopServer(server);
}
