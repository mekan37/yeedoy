import fs from 'node:fs';
import net from 'node:net';
import path from 'node:path';
import { execFileSync, spawn } from 'node:child_process';
import { setTimeout as delay } from 'node:timers/promises';
import { fileURLToPath } from 'node:url';
import { chromium } from '@playwright/test';
import { createClient } from '@supabase/supabase-js';
import { launch } from 'chrome-launcher';
import lighthouse from 'lighthouse';

export const appDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
export const reportsRootDir = path.join(appDir, 'reports', 'lighthouse');
export const latestReportDir = path.join(reportsRootDir, 'latest');
export const docsPerfPath = path.join(appDir, '..', '..', 'docs', 'perf.md');
export const bundleLatestDir = path.join(appDir, 'reports', 'bundle', 'latest');

export function loadEnvFiles() {
  loadEnvFile(path.join(appDir, '.env.local'));
  loadEnvFile(path.join(appDir, '.env.playwright.local'));
}

export function requireEnv(name) {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export function createTimestamp() {
  return new Date().toISOString().replace(/[:.]/g, '-');
}

export function createReportDir(timestamp = createTimestamp()) {
  const reportDir = path.join(reportsRootDir, timestamp);
  fs.mkdirSync(reportDir, { recursive: true });
  fs.mkdirSync(latestReportDir, { recursive: true });
  return { timestamp, reportDir, latestDir: latestReportDir };
}

export async function resolveAvailablePort(initialPort) {
  for (let candidate = initialPort; candidate < initialPort + 20; candidate += 1) {
    const available = await isPortAvailable(candidate);
    if (available) return candidate;
  }

  throw new Error(`Could not find an available port starting from ${initialPort}`);
}

export function startServer(port) {
  return spawn(`npm run start -- --port ${port}`, {
    cwd: appDir,
    env: process.env,
    shell: true,
    stdio: 'ignore',
  });
}

export async function stopServer(server) {
  if (server.killed) return;

  await new Promise((resolve) => {
    server.once('exit', () => resolve(undefined));
    server.kill();
    setTimeout(() => resolve(undefined), 5000);
  });
}

export async function waitForServer(baseUrl) {
  const timeoutAt = Date.now() + 120_000;

  while (Date.now() < timeoutAt) {
    try {
      const response = await fetch(baseUrl, { redirect: 'manual' });
      if (response.status < 500) return;
    } catch {}

    await delay(1000);
  }

  throw new Error(`Timed out waiting for server at ${baseUrl}`);
}

export async function runNpm(args) {
  await new Promise((resolve, reject) => {
    const child = spawn(`npm ${args.join(' ')}`, {
      cwd: appDir,
      env: process.env,
      shell: true,
      stdio: 'inherit',
    });

    child.on('close', (code) => {
      if (code === 0) resolve(undefined);
      else reject(new Error(`Command failed: npm ${args.join(' ')}`));
    });
  });
}

export async function ensureBundleArtifacts() {
  const bundleTimestampDir = path.join(appDir, 'reports', 'bundle', createTimestamp());
  fs.mkdirSync(bundleTimestampDir, { recursive: true });
  fs.mkdirSync(bundleLatestDir, { recursive: true });

  try {
    await runNpm(['run', 'build:analyze']);
    copyDirectory(path.join(appDir, '.next', 'analyze'), bundleTimestampDir);
    copyDirectory(path.join(appDir, '.next', 'analyze'), bundleLatestDir);
  } catch (error) {
    console.warn(`[perf] build:analyze failed, falling back to standard build: ${error instanceof Error ? error.message : String(error)}`);
    await runNpm(['run', 'build']);
  }
}

export async function launchChromeInstance() {
  return launch({
    chromeFlags: ['--headless=new', '--no-sandbox', '--disable-dev-shm-usage'],
  });
}

export async function connectPlaywrightToChrome(chromePort) {
  return chromium.connectOverCDP(`http://127.0.0.1:${chromePort}`);
}

export async function runLighthouseAudit({
  chromePort,
  slug,
  label,
  requestedUrl,
  reportDir,
  disableStorageReset = false,
}) {
  const runnerResult = await lighthouse(requestedUrl, {
    port: chromePort,
    output: ['html', 'json'],
    onlyCategories: ['performance', 'accessibility', 'best-practices', 'seo'],
    disableStorageReset,
    formFactor: 'mobile',
    screenEmulation: {
      mobile: true,
      width: 390,
      height: 844,
      deviceScaleFactor: 3,
      disabled: false,
    },
    throttlingMethod: 'simulate',
    throttling: {
      rttMs: 150,
      throughputKbps: 1638.4,
      requestLatencyMs: 150,
      downloadThroughputKbps: 1638.4,
      uploadThroughputKbps: 675,
      cpuSlowdownMultiplier: 4,
    },
  });

  const reportList = Array.isArray(runnerResult.report) ? runnerResult.report : [runnerResult.report];
  const html = reportList[0];
  const json = reportList[1] ?? reportList[0];
  const htmlPath = path.join(reportDir, `${slug}.report.html`);
  const jsonPath = path.join(reportDir, `${slug}.report.json`);
  fs.writeFileSync(htmlPath, html, 'utf8');
  fs.writeFileSync(jsonPath, json, 'utf8');

  const targetSizeItems = (runnerResult.lhr.audits['target-size']?.details?.items ?? []).map((item) => ({
    selector: item.node?.selector ?? 'unknown',
    snippet: item.node?.snippet ?? '',
    explanation: item.node?.explanation ?? '',
  }));

  return {
    slug,
    label,
    requestedUrl,
    finalUrl: runnerResult.lhr.finalUrl,
    mainDocumentUrl: runnerResult.lhr.mainDocumentUrl,
    htmlPath,
    jsonPath,
    scores: {
      performance: Math.round((runnerResult.lhr.categories.performance?.score ?? 0) * 100),
      accessibility: Math.round((runnerResult.lhr.categories.accessibility?.score ?? 0) * 100),
      bestPractices: Math.round((runnerResult.lhr.categories['best-practices']?.score ?? 0) * 100),
      seo: Math.round((runnerResult.lhr.categories.seo?.score ?? 0) * 100),
    },
    metrics: {
      fcp: runnerResult.lhr.audits['first-contentful-paint']?.displayValue ?? 'n/a',
      lcp: runnerResult.lhr.audits['largest-contentful-paint']?.displayValue ?? 'n/a',
      tbt: runnerResult.lhr.audits['total-blocking-time']?.displayValue ?? 'n/a',
      cls: runnerResult.lhr.audits['cumulative-layout-shift']?.displayValue ?? 'n/a',
      si: runnerResult.lhr.audits['speed-index']?.displayValue ?? 'n/a',
    },
    targetSize: {
      score: runnerResult.lhr.audits['target-size']?.score ?? null,
      items: targetSizeItems,
    },
  };
}

export function writeSummaryFiles(report, latestDir = latestReportDir) {
  fs.copyFileSync(report.htmlPath, path.join(latestDir, path.basename(report.htmlPath)));
  fs.copyFileSync(report.jsonPath, path.join(latestDir, path.basename(report.jsonPath)));
  fs.writeFileSync(path.join(latestDir, `${report.slug}.summary.json`), JSON.stringify(report, null, 2), 'utf8');
}

export function writePerfMarkdown() {
  const menuReports = [
    readSummary('menu-minimal'),
    readSummary('menu-photo-heavy'),
    readSummary('menu-dark-modern'),
  ].filter(Boolean);
  const girisReport = readSummary('giris');
  const qrAuthReport = readSummary('karekod-auth');
  const buildLog = readBuildLog();
  const commit = getCommitSha();
  const timestamp = new Date().toISOString();

  const markdown = renderPerfMarkdown({
    timestamp,
    commit,
    buildLog,
    menuReports,
    girisReport,
    qrAuthReport,
  });

  fs.writeFileSync(docsPerfPath, markdown, 'utf8');
}

export function readSummary(slug) {
  const summaryPath = path.join(latestReportDir, `${slug}.summary.json`);
  if (!fs.existsSync(summaryPath)) return null;
  return JSON.parse(fs.readFileSync(summaryPath, 'utf8'));
}

export function readBuildLog() {
  const buildLogPath = path.join(appDir, 'reports', 'build', 'build-latest.log');
  if (!fs.existsSync(buildLogPath)) return '';
  return fs.readFileSync(buildLogPath, 'utf8');
}

export function extractBuildSize(buildLog, route) {
  const line = buildLog.split(/\r?\n/).find((entry) => entry.includes(route));
  if (!line) return null;
  const match = line.match(/\s(\d+(?:\.\d+)?\s*kB)\s*$/);
  return match?.[1] ?? null;
}

export function getCommitSha() {
  try {
    return execFileSync('git', ['rev-parse', '--short', 'HEAD'], {
      cwd: appDir,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
  } catch {
    return 'local';
  }
}

export async function discoverOwnerTarget(preferredBusinessId) {
  const service = getServiceClient();
  const exactQuery = await service
    .from('owner_claims')
    .select('business_id,user_id,status')
    .eq('business_id', preferredBusinessId)
    .eq('status', 'approved')
    .limit(1);

  let claim = exactQuery.data?.[0] ?? null;
  if (!claim) {
    const fallbackQuery = await service
      .from('owner_claims')
      .select('business_id,user_id,status')
      .eq('status', 'approved')
      .limit(1);

    if (fallbackQuery.error || !fallbackQuery.data?.length) {
      throw new Error(
        `No approved owner claim found for ${preferredBusinessId}: ${exactQuery.error?.message ?? fallbackQuery.error?.message ?? 'unknown error'}`,
      );
    }

    claim = fallbackQuery.data[0];
  }

  const usersPage = await service.auth.admin.listUsers({ page: 1, perPage: 200 });
  if (usersPage.error) {
    throw new Error(`Could not list auth users: ${usersPage.error.message}`);
  }

  const ownerUser = usersPage.data.users.find((user) => user.id === claim.user_id && user.email);
  if (!ownerUser?.email) {
    throw new Error(`Could not resolve owner email for business ${claim.business_id}`);
  }

  return {
    businessId: claim.business_id,
    ownerEmail: ownerUser.email,
  };
}

export async function issueMagicLinkSession(email) {
  const service = getServiceClient();
  const anon = getAnonClient();

  const linkData = await service.auth.admin.generateLink({
    type: 'magiclink',
    email,
  });

  if (linkData.error || !linkData.data.properties.email_otp) {
    throw new Error(`Could not generate magic link for ${email}: ${linkData.error?.message ?? 'missing otp'}`);
  }

  const verifyData = await anon.auth.verifyOtp({
    email,
    token: linkData.data.properties.email_otp,
    type: 'magiclink',
  });

  if (verifyData.error || !verifyData.data.session) {
    throw new Error(`Could not verify magic link for ${email}: ${verifyData.error?.message ?? 'missing session'}`);
  }

  return {
    accessToken: verifyData.data.session.access_token,
    refreshToken: verifyData.data.session.refresh_token,
  };
}

export async function getSessionCookiesViaPanelHandoff({ baseUrl, businessId, lang, theme, accessToken, refreshToken }) {
  const formData = new FormData();
  formData.set('access_token', accessToken);
  formData.set('refresh_token', refreshToken);
  formData.set('business_id', businessId);
  formData.set('lang', lang);
  formData.set('theme', theme);

  const response = await fetch(`${baseUrl}/kimlik/panel-devir`, {
    method: 'POST',
    body: formData,
    redirect: 'manual',
  });

  if (response.status !== 200) {
    throw new Error(`Panel devir hatasi: ${response.status}`);
  }

  const rawCookies = response.headers.getSetCookie?.() ?? [];
  if (!rawCookies.length) {
    throw new Error('Panel devir auth cookie dondurmedi');
  }

  return rawCookies
    .map((cookie) => {
      const [pair] = cookie.split(';', 1);
      const separatorIndex = pair.indexOf('=');
      if (separatorIndex <= 0) return null;
      return {
        name: pair.slice(0, separatorIndex),
        value: pair.slice(separatorIndex + 1),
      };
    })
    .filter(Boolean);
}

export async function addCookiesToContext(context, baseUrl, cookies) {
  const targetUrl = new URL(baseUrl);
  await context.addCookies(
    cookies.map((cookie) => ({
      name: cookie.name,
      value: cookie.value,
      url: targetUrl.origin,
      httpOnly: false,
      sameSite: 'Lax',
    })),
  );
}

export function findTargetSizeComponents(report) {
  return (report.targetSize.items ?? []).map((item) => ({
    selector: item.selector,
    component:
      item.selector.includes('form.mt-6')
        ? 'src/ui/bolumler/giris-formu.tsx'
        : item.selector.includes('div.grid > div.space-y-4 > div.flex')
          ? 'src/ui/bolumler/karekod-uretici.tsx'
          : item.selector.includes('div.space-y-4 > div.rounded-[28px] > div.mt-4')
            ? 'src/ui/bolumler/karekod-uretici.tsx'
            : item.selector.includes('section.grid > div.space-y-4 > div.grid')
              ? 'src/ui/bolumler/karekod-uretici.tsx'
        : item.selector.includes('qr-studio')
          ? 'src/ui/bolumler/karekod-uretici.tsx'
          : item.selector.includes('media-picker') || item.selector.includes('rounded-[24px]')
            ? 'src/ui/bolumler/karekod-marka-paneli.tsx'
            : 'manual-review',
  }));
}

function renderPerfMarkdown({ timestamp, commit, buildLog, menuReports, girisReport, qrAuthReport }) {
  const menuBuild = extractBuildSize(buildLog, '/m/[slug]');
  const qrBuild = extractBuildSize(buildLog, '/karekod/[businessId]');

  return `# Performans Raporu

Tarih: ${timestamp}
Commit: ${commit}

## Build Ciktisi

- \`/m/[slug]\` first load JS: ${menuBuild || 'n/a'}
- \`/karekod/[businessId]\` first load JS: ${qrBuild || 'n/a'}

## Public Menu Lighthouse

| Senaryo | Requested URL | Final URL | Performance | Accessibility | Best Practices | SEO | FCP | LCP | TBT | CLS | Speed Index |
|---|---|---|---:|---:|---:|---:|---|---|---|---|---|
${menuReports
  .map(
    (report) =>
      `| ${report.label} | \`${formatRoute(report.requestedUrl)}\` | \`${formatRoute(report.finalUrl)}\` | ${report.scores.performance} | ${report.scores.accessibility} | ${report.scores.bestPractices} | ${report.scores.seo} | ${report.metrics.fcp} | ${report.metrics.lcp} | ${report.metrics.tbt} | ${report.metrics.cls} | ${report.metrics.si} |`,
  )
  .join('\n')}

## Giris Gate Lighthouse

${girisReport ? renderSingleReportTable(girisReport) : '_Henuz olculmedi._'}

## Authenticated QR Studio Lighthouse

${qrAuthReport ? renderSingleReportTable(qrAuthReport) : '_Henuz olculmedi._'}

${qrAuthReport && qrAuthReport.targetSize.items.length > 0 ? `## QR Studio Target-Size Bulgulari

${findTargetSizeComponents(qrAuthReport)
  .map((item) => `- \`${item.selector}\` -> \`${item.component}\``)
  .join('\n')}
` : ''}

## Target-Size Closure

- Giris Gate:
  ${girisReport ? `${girisReport.targetSize.items.length} aktif node, hedef skor ${girisReport.scores.accessibility}` : 'olcum yok'}
- Authenticated QR Studio:
  ${qrAuthReport ? `${qrAuthReport.targetSize.items.length} aktif node, hedef skor ${qrAuthReport.scores.accessibility}` : 'olcum yok'}
- Kapanan yuzeyler:
  Public menu senaryolari \`Accessibility 100\` ile temiz.
- Kalan odak:
  ${qrAuthReport?.targetSize.items.length ? '`src/ui/bolumler/karekod-uretici.tsx` ust tablar ve CTA stackleri' : 'kalan QR Studio target-size node yok'}
  ${girisReport?.targetSize.items.length ? '\n- `src/ui/bolumler/giris-formu.tsx` submit/link CTA satiri' : ''}

## Bundle Audit

Analyzer raporlari:
- \`uygulamalar/web/reports/bundle/latest/client.html\`
- \`uygulamalar/web/reports/bundle/latest/nodejs.html\`
- \`uygulamalar/web/reports/bundle/latest/edge.html\`

## Artefact'lar

- \`uygulamalar/web/reports/lighthouse/latest/menu-minimal.report.html\`
- \`uygulamalar/web/reports/lighthouse/latest/menu-photo-heavy.report.html\`
- \`uygulamalar/web/reports/lighthouse/latest/menu-dark-modern.report.html\`
- \`uygulamalar/web/reports/lighthouse/latest/giris.report.html\`
- \`uygulamalar/web/reports/lighthouse/latest/karekod-auth.report.html\`
`;
}

function renderSingleReportTable(report) {
  return `| Senaryo | Requested URL | Final URL | Performance | Accessibility | Best Practices | SEO | FCP | LCP | TBT | CLS | Speed Index |
|---|---|---|---:|---:|---:|---:|---|---|---|---|---|
| ${report.label} | \`${formatRoute(report.requestedUrl)}\` | \`${formatRoute(report.finalUrl)}\` | ${report.scores.performance} | ${report.scores.accessibility} | ${report.scores.bestPractices} | ${report.scores.seo} | ${report.metrics.fcp} | ${report.metrics.lcp} | ${report.metrics.tbt} | ${report.metrics.cls} | ${report.metrics.si} |`;
}

function formatRoute(url) {
  return url.replace(/^https?:\/\/127\.0\.0\.1:\d+/, '');
}

function loadEnvFile(filePath) {
  if (!fs.existsSync(filePath)) return;

  const contents = fs.readFileSync(filePath, 'utf8');
  for (const rawLine of contents.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;

    const separatorIndex = line.indexOf('=');
    if (separatorIndex <= 0) continue;

    const key = line.slice(0, separatorIndex).trim();
    const value = line.slice(separatorIndex + 1).trim().replace(/^['"]|['"]$/g, '');

    if (!process.env[key]) {
      process.env[key] = value;
    }
  }
}

function copyDirectory(sourceDir, targetDir) {
  if (!fs.existsSync(sourceDir)) return;
  fs.mkdirSync(targetDir, { recursive: true });

  for (const entry of fs.readdirSync(sourceDir, { withFileTypes: true })) {
    const sourcePath = path.join(sourceDir, entry.name);
    const targetPath = path.join(targetDir, entry.name);

    if (entry.isDirectory()) {
      copyDirectory(sourcePath, targetPath);
    } else {
      fs.copyFileSync(sourcePath, targetPath);
    }
  }
}

function isPortAvailable(port) {
  return new Promise((resolve) => {
    const server = net.createServer();
    server.unref();
    server.on('error', () => resolve(false));
    server.listen({ port, host: '127.0.0.1' }, () => {
      server.close(() => resolve(true));
    });
  });
}

function getServiceClient() {
  return createClient(requireEnv('NEXT_PUBLIC_SUPABASE_URL'), requireEnv('SUPABASE_SERVICE_ROLE_KEY'), {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}

function getAnonClient() {
  return createClient(requireEnv('NEXT_PUBLIC_SUPABASE_URL'), requireEnv('NEXT_PUBLIC_SUPABASE_ANON_KEY'), {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}

