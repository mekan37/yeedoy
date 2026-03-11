import { NextResponse } from 'next/server';
import { sanitizeInternalRedirect } from '@/src/lib/safe-redirect';

export function GET(request: Request) {
  const url = new URL(request.url);
  const fallbackTarget = sanitizeInternalRedirect(url.searchParams.get('from'), '/');
  const html = `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="robots" content="noindex, nofollow" />
    <title>Forbidden</title>
    <style>
      :root {
        color-scheme: light;
        --bg: #f7f2ef;
        --card: #ffffff;
        --border: rgba(17, 24, 39, 0.08);
        --text: #111827;
        --muted: #6b7280;
        --primary: #7f1d1d;
      }
      * { box-sizing: border-box; }
      body {
        margin: 0;
        min-height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 24px;
        background:
          radial-gradient(circle at top left, rgba(255,255,255,0.72), transparent 34%),
          linear-gradient(135deg, #7f1d1d, #dc2626);
        font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      }
      main {
        width: min(640px, 100%);
        background: var(--card);
        border: 1px solid var(--border);
        border-radius: 28px;
        padding: 28px;
        box-shadow: 0 24px 80px rgba(17, 24, 39, 0.18);
      }
      p { margin: 0; color: var(--muted); line-height: 1.7; }
      h1 { margin: 12px 0 0; color: var(--text); font-size: 2rem; line-height: 1.1; }
      .actions { display: flex; flex-wrap: wrap; gap: 12px; margin-top: 18px; }
      a {
        display: inline-flex;
        padding: 12px 18px;
        border-radius: 16px;
        text-decoration: none;
        font-weight: 800;
      }
      .primary { background: var(--primary); color: white; }
      .ghost { border: 1px solid var(--border); color: var(--text); background: var(--bg); }
    </style>
  </head>
  <body>
    <main>
      <p>403</p>
      <h1>You do not have access to this QR Studio</h1>
      <p>This business can only be opened by its owner or an admin account with management access.</p>
      <div class="actions">
        <a class="primary" href="${escapeHtml(fallbackTarget)}">Go back</a>
        <a class="ghost" href="/login?redirect=${encodeURIComponent(fallbackTarget)}">Open login</a>
      </div>
    </main>
  </body>
</html>`;

  return new NextResponse(html, {
    status: 403,
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-store',
    },
  });
}

function escapeHtml(value: string) {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}
