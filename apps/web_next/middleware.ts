import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { getRequestIdentity, rateLimit } from '@/src/lib/rate-limit';
import { resolveBrandTheme } from '@/src/lib/brand-theme';
import { isBusinessMenuPathKey, isUuid } from '@/src/lib/business-path';
import { resolveLang } from '@/src/lib/i18n';

// ── Custom domain → slug cache (in-memory, per Edge runtime instance, ~5 min TTL) ──
const _domainCache = new Map<string, { slug: string; expiresAt: number }>();
const _DOMAIN_TTL_MS = 5 * 60 * 1_000;

async function resolveCustomDomainSlug(hostname: string): Promise<string | null> {
  const now = Date.now();
  const cached = _domainCache.get(hostname);
  if (cached && cached.expiresAt > now) return cached.slug;

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!supabaseUrl || !supabaseAnonKey) return null;

  try {
    const url = `${supabaseUrl}/rest/v1/rpc/get_slug_for_domain_v1`;
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseAnonKey,
        'Authorization': `Bearer ${supabaseAnonKey}`,
      },
      body: JSON.stringify({ p_domain: hostname }),
    });
    if (!res.ok) return null;
    const slug = await res.json() as string | null;
    if (slug) {
      _domainCache.set(hostname, { slug, expiresAt: now + _DOMAIN_TTL_MS });
    }
    return slug ?? null;
  } catch {
    return null;
  }
}

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const hostname = request.headers.get('host')?.split(':')[0] ?? '';

  // ── Custom domain rewrite ─────────────────────────────────────────────────
  // If the request comes in on a custom domain (not yeedoy.com / localhost),
  // look up the business slug and rewrite to /m/[slug] (URL stays unchanged).
  const ownHostnames = (process.env.OWN_HOSTNAMES ?? 'localhost,yeedoy.com').split(',').map((h) => h.trim());
  const isOwnHost = ownHostnames.some((h) => hostname === h || hostname.endsWith(`.${h}`));

  if (!isOwnHost && hostname && hostname !== '') {
    const slug = await resolveCustomDomainSlug(hostname);
    if (slug) {
      const url = request.nextUrl.clone();
      // Rewrite root and any sub-path to /m/[slug]/...
      const suffix = pathname === '/' ? '' : pathname;
      url.pathname = `/m/${slug}${suffix}`;
      return NextResponse.rewrite(url);
    }
  }

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
    // Custom domain rewrite needs to run on all paths
    '/((?!_next/static|_next/image|favicon.ico).*)',
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
