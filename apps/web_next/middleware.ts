import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { getRequestIdentity, rateLimit } from '@/src/lib/rate-limit';
import { resolveBrandTheme } from '@/src/lib/brand-theme';
import { isBusinessMenuPathKey, isUuid } from '@/src/lib/business-path';
import { resolveLang } from '@/src/lib/i18n';

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  const routeGuard = normalizePublicRoute(request);
  if (routeGuard) {
    return routeGuard;
  }

  if (
    !pathname.startsWith('/m/') &&
    !pathname.startsWith('/api/track') &&
    !pathname.startsWith('/api/media/upload') &&
    !pathname.startsWith('/api/presentation-settings') &&
    !pathname.startsWith('/qr/') &&
    pathname !== '/auth/panel-handoff'
  ) {
    return NextResponse.next();
  }

  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });

  const policy = pathname.startsWith('/api/track')
    ? rateLimit(`middleware:track:${identity}`, 60, 60_000)
    : pathname.startsWith('/api/media/upload')
      ? rateLimit(`middleware:media-upload:${identity}`, 20, 60_000)
      : pathname.startsWith('/api/presentation-settings')
        ? rateLimit(`middleware:presentation-settings:${identity}`, 30, 60_000)
    : pathname === '/auth/panel-handoff'
      ? rateLimit(`middleware:panel-handoff:${identity}`, 20, 60_000)
      : rateLimit(`middleware:qr:${identity}`, 20, 60_000);

  if (policy.ok) {
    return NextResponse.next();
  }

  return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
}

export const config = {
  matcher: [
    '/m/:path*',
    '/api/track',
    '/api/media/upload',
    '/api/presentation-settings',
    '/qr/:path*',
    '/auth/panel-handoff',
  ],
};

function normalizePublicRoute(request: NextRequest) {
  const { pathname, searchParams } = request.nextUrl;
  if (!pathname.startsWith('/m/') && !pathname.startsWith('/qr/')) {
    return null;
  }

  const segments = pathname.split('/').filter(Boolean);
  const businessPath = segments[1] ?? null;
  if (!businessPath) {
    return createNotFoundResponse();
  }

  if (pathname.startsWith('/qr/')) {
    if (!isUuid(businessPath)) {
      return createNotFoundResponse();
    }
  } else if (!isBusinessMenuPathKey(businessPath)) {
    return createNotFoundResponse();
  }

  if (pathname.startsWith('/m/')) {
    const routeType = segments[2] ?? null;
    const routeId = segments[3] ?? null;
    if ((routeType === 'c' || routeType === 'i') && (!routeId || !isUuid(routeId))) {
      return createNotFoundResponse();
    }
  }

  const rawLang = searchParams.get('lang');
  const rawTheme = searchParams.get('theme');
  const normalizedLang = resolveLang(rawLang);
  const normalizedTheme = resolveBrandTheme(rawTheme);
  const nextParams = new URLSearchParams(searchParams);
  let shouldRedirect = false;

  if (rawLang !== null && rawLang.toLowerCase() !== normalizedLang) {
    nextParams.set('lang', normalizedLang);
    shouldRedirect = true;
  }

  if (rawTheme !== null && rawTheme.toLowerCase() !== normalizedTheme) {
    nextParams.set('theme', normalizedTheme);
    shouldRedirect = true;
  }

  if (!shouldRedirect) {
    return null;
  }

  const url = request.nextUrl.clone();
  url.search = nextParams.toString();
  return NextResponse.redirect(url);
}

function createNotFoundResponse() {
  return new NextResponse(
    `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="robots" content="noindex, nofollow" />
    <title>Menu not found</title>
    <style>
      body {
        margin: 0;
        min-height: 100vh;
        display: grid;
        place-items: center;
        padding: 24px;
        background: linear-gradient(135deg, #7f1d1d, #dc2626);
        font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      }
      main {
        width: min(640px, 100%);
        border-radius: 28px;
        border: 1px solid rgba(17, 24, 39, 0.08);
        background: white;
        padding: 28px;
        box-shadow: 0 24px 80px rgba(17, 24, 39, 0.18);
      }
      p { color: #6b7280; line-height: 1.7; }
      h1 { margin: 12px 0 0; color: #111827; font-size: 2rem; line-height: 1.1; }
    </style>
  </head>
  <body>
    <main>
      <p>404</p>
      <h1>Menu not found</h1>
      <p>This public menu path is invalid or no longer available.</p>
    </main>
  </body>
</html>`,
    {
      status: 404,
      headers: {
        'Content-Type': 'text/html; charset=utf-8',
        'Cache-Control': 'no-store',
      },
    },
  );
}
