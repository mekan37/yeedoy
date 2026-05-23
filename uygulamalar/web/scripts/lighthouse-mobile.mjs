import {
  createReportDir,
  ensureBundleArtifacts,
  launchChromeInstance,
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

const businessId = requireEnv('PLAYWRIGHT_SMOKE_BUSINESS_ID');
const lang = process.env.PLAYWRIGHT_SMOKE_LANG?.trim() || 'tr';
const preferredPort = Number(process.env.PERF_PORT ?? 3400);
const port = await resolveAvailablePort(preferredPort);
const baseUrl = `http://127.0.0.1:${port}`;
const { reportDir } = createReportDir();

await ensureBundleArtifacts();

const server = startServer(port);

try {
  await waitForServer(baseUrl);

  const scenarios = [
    {
      slug: 'menu-minimal',
      label: '/m/:businessId?theme=minimal',
      requestedUrl: `${baseUrl}/m/${businessId}?lang=${lang}&theme=minimal`,
    },
    {
      slug: 'menu-photo-heavy',
      label: '/m/:businessId?theme=photo-heavy',
      requestedUrl: `${baseUrl}/m/${businessId}?lang=${lang}&theme=photo-heavy`,
    },
    {
      slug: 'menu-dark-modern',
      label: '/m/:businessId?theme=dark-modern',
      requestedUrl: `${baseUrl}/m/${businessId}?lang=${lang}&theme=dark-modern`,
    },
    {
      slug: 'login',
      label: '/login?redirect=/qr/:businessId',
      requestedUrl: `${baseUrl}/login?redirect=${encodeURIComponent(`/qr/${businessId}?lang=${lang}&theme=bold`)}`,
    },
  ];

  for (const scenario of scenarios) {
    const chrome = await launchChromeInstance();
    try {
      const report = await runLighthouseAudit({
        chromePort: chrome.port,
        slug: scenario.slug,
        label: scenario.label,
        requestedUrl: scenario.requestedUrl,
        reportDir,
      });
      writeSummaryFiles(report);
    } finally {
      await chrome.kill();
    }
  }

  writePerfMarkdown();
} finally {
  await stopServer(server);
}
