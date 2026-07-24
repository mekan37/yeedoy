import { z } from 'zod';
import { NextResponse } from 'next/server';
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
import { appConfig } from '@/src/lib/ayarlar';
import { getRequestIdentity, rateLimit, getClientIp } from '@/src/lib/oran-siniri';
import { sanitizeInternalRedirect } from '@/src/lib/guvenli-yonlendirme';

const panelHandoffSchema = z.object({
  access_token: z.string().min(20),
  refresh_token: z.string().min(1),
  business_id: z.string().uuid(),
  lang: z.string().optional(),
  theme: z.string().optional(),
});

export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: getClientIp(request.headers),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`panel-devir:${identity}`, 20, 60_000);

  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const origin = request.headers.get('origin');
  const panelUrl = appConfig.panelUrl();
  if (panelUrl && origin) {
    const expectedOrigin = new URL(panelUrl).origin;
    if (origin !== expectedOrigin) {
      return NextResponse.json({ error: 'invalid_origin' }, { status: 403 });
    }
  }

  const formData = await request.formData();
  const parsed = panelHandoffSchema.safeParse({
    access_token: formData.get('access_token'),
    refresh_token: formData.get('refresh_token'),
    business_id: formData.get('business_id'),
    lang: formData.get('lang'),
    theme: formData.get('theme'),
  });

  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });
  }

  const cookieStore = await cookies();
  const destination = sanitizeInternalRedirect(
    `/karekod/${parsed.data.business_id}?lang=${parsed.data.lang || 'tr'}&theme=${parsed.data.theme || 'bold'}`,
    '/',
  );
  const response = NextResponse.redirect(new URL(destination, appConfig.siteUrl()));
  const supabase = createServerClient(appConfig.supabaseUrl(), appConfig.supabaseAnonKey(), {
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },
      setAll(
        cookiesToSet: Array<{
          name: string;
          value: string;
          options?: Record<string, unknown>;
        }>,
      ) {
        cookiesToSet.forEach(({ name, value, options }) => {
          response.cookies.set(name, value, options);
        });
      },
    },
  });

  const { error } = await supabase.auth.setSession({
    access_token: parsed.data.access_token,
    refresh_token: parsed.data.refresh_token,
  });

  if (error) {
    return createPanelHandoffErrorResponse({
      request,
      status: 401,
      error: 'auth_failed',
      destination,
    });
  }

  const refreshValidation = await supabase.auth.refreshSession({
    refresh_token: parsed.data.refresh_token,
  });

  if (refreshValidation.error || !refreshValidation.data.session?.user) {
    return createPanelHandoffErrorResponse({
      request,
      status: 401,
      error: 'auth_failed',
      destination,
    });
  }

  return createPanelHandoffSuccessResponse({ request, response, destination });
}

function createPanelHandoffSuccessResponse(input: {
  request: Request;
  response: NextResponse;
  destination: string;
}) {
  if (!prefersHtmlResponse(input.request)) {
    return NextResponse.json(
      { ok: true, redirectTo: input.destination },
      {
        status: 200,
        headers: cloneCookiesAsHeaders(input.response),
      },
    );
  }

  const html = renderRedirectHtml({
    title: 'Karekod tasarim kitine yonlendiriliyor',
    message: 'Sahip oturumunuz hazir. Simdi karekod tasarim kitine yonlendiriliyorsunuz.',
    destination: input.destination,
    ctaLabel: 'Karekod tasarim kitini ac',
  });

  const headers = new Headers(input.response.headers);
  headers.set('Cache-Control', 'no-store');
  headers.set('Content-Type', 'text/html; charset=utf-8');
  headers.delete('Location');
  return new NextResponse(html, {
    status: 200,
    headers,
  });
}

function createPanelHandoffErrorResponse(input: {
  request: Request;
  status: 401;
  error: 'auth_failed';
  destination: string;
}) {
  const loginUrl = `/giris?redirect=${encodeURIComponent(input.destination)}`;

  if (!prefersHtmlResponse(input.request)) {
    return NextResponse.json(
      {
        error: input.error,
        loginUrl,
      },
      { status: input.status },
    );
  }

  const html = renderRedirectHtml({
    title: 'Sahip oturumu geri yuklenemedi',
    message: 'Panel oturumunuz dogrulanamadi. Giris sayfasini acip ayni karekod tasarim kiti yoluna devam edin.',
    destination: loginUrl,
    ctaLabel: 'Open login',
    autoRedirect: false,
  });

  return new NextResponse(html, {
    status: input.status,
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-store',
    },
  });
}

function prefersHtmlResponse(request: Request) {
  const accept = request.headers.get('accept') || '';
  return accept.includes('text/html') || accept.includes('*/*');
}

function cloneCookiesAsHeaders(response: NextResponse) {
  const headers = new Headers({
    'Cache-Control': 'no-store',
  });

  for (const header of response.headers.entries()) {
    if (header[0].toLowerCase() === 'set-cookie') {
      headers.append(header[0], header[1]);
    }
  }

  return headers;
}

function renderRedirectHtml(input: {
  title: string;
  message: string;
  destination: string;
  ctaLabel: string;
  autoRedirect?: boolean;
}) {
  const escapedDestination = escapeHtml(input.destination);
  const escapedTitle = escapeHtml(input.title);
  const escapedMessage = escapeHtml(input.message);
  const escapedCta = escapeHtml(input.ctaLabel);
  const shouldRedirect = input.autoRedirect !== false;

  return `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="robots" content="noindex, nofollow" />
    <title>${escapedTitle}</title>
    ${shouldRedirect ? `<meta http-equiv="refresh" content="0;url=${escapedDestination}" />` : ''}
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
        width: min(560px, 100%);
        background: var(--card);
        border: 1px solid var(--border);
        border-radius: 28px;
        padding: 28px;
        box-shadow: 0 24px 80px rgba(17, 24, 39, 0.18);
      }
      p {
        margin: 0;
        color: var(--muted);
        line-height: 1.7;
      }
      h1 {
        margin: 12px 0 0;
        color: var(--text);
        font-size: 2rem;
        line-height: 1.1;
      }
      a {
        display: inline-flex;
        margin-top: 18px;
        padding: 12px 18px;
        border-radius: 16px;
        background: var(--primary);
        color: white;
        text-decoration: none;
        font-weight: 800;
      }
      code {
        display: block;
        margin-top: 18px;
        padding: 12px 14px;
        border-radius: 18px;
        background: var(--bg);
        color: var(--text);
        word-break: break-word;
      }
    </style>
  </head>
  <body>
    <main>
      <p>Sahip devir</p>
      <h1>${escapedTitle}</h1>
      <p>${escapedMessage}</p>
      <a href="${escapedDestination}">${escapedCta}</a>
      <code>${escapedDestination}</code>
      ${
        shouldRedirect
          ? `<script>window.location.replace(${JSON.stringify(input.destination)});</script>`
          : ''
      }
    </main>
  </body>
</html>`;
}

function escapeHtml(value: string) {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

