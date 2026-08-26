import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { createServerClient } from '@supabase/ssr';
import { getRequestIdentity, rateLimit, getClientIp } from '@/src/lib/rate-limit';
import { resolveBrandTheme } from '@/src/lib/brand-theme';
import { isBusinessMenuPathKey, isUuid } from '@/src/lib/business-path';
import { resolveLang } from '@/src/lib/i18n';

// ── CSP nonce ──────────────────────────────────────────────────────────────────
// Her istekte taze bir nonce üretilir. Next.js bunu CSP response header'ından
// otomatik ayrıştırıp kendi inline bootstrap/hydration <script>'lerine uygular.
// Kendi ham HTML'ini döndüren route handler'lar (örn. app/auth/panel-handoff)
// nonce'u x-nonce request header'ından okur.
function buildCsp(nonce: string, isEmbed: boolean): string {
  const supabaseHost = (() => {
    try { return new URL(process.env.NEXT_PUBLIC_SUPABASE_URL ?? '').hostname; } catch { return '*.supabase.co'; }
  })();
  const isDev = process.env.NODE_ENV === 'development';

  return [
    "default-src 'self'",
    // 'unsafe-eval' sadece dev'de React Fast Refresh için gerekli.
    `script-src 'self' 'nonce-${nonce}'${isDev ? " 'unsafe-eval'" : ''} https://vercel-scripts.com https://va.vercel-scripts.com`,
    "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
    "font-src 'self' data: https://fonts.gstatic.com",
    "img-src 'self' data: blob: https: http:",
    // MapLibre GL v6 worker'ı same-origin module dosyası olarak yükler
    // (new Worker(url, { type: 'module' })) — 'self' gerekli, blob: eski
    // kod yolları için tutuluyor.
    "worker-src 'self' blob:",
    `connect-src 'self'${isDev ? ' ws://localhost:* ws://127.0.0.1:*' : ''} https://${supabaseHost} wss://${supabaseHost} https://*.supabase.co wss://*.supabase.co https://fonts.googleapis.com https://maps.yeedoy.com https://cdn.jsdelivr.net`,
    "frame-src https://www.openstreetmap.org",
    `frame-ancestors ${isEmbed ? '*' : "'none'"}`,
    "base-uri 'self'",
    "form-action 'self'",
    "upgrade-insecure-requests",
  ].join('; ');
}

// ── Subdomain → panel rewrite ─────────────────────────────────────────────────
// isletme.yeedoy.com  →  /sahip/[path]
// ops.yeedoy.com      →  /yonetici/[path]   (secret subdomain, no public links)
//
// Configured via env vars so the admin hostname never appears in source code:
//   OWNER_HOSTNAMES = "isletme.yeedoy.com,isletme.localhost"
//   ADMIN_HOSTNAME  = "ops.yeedoy.com,ops.localhost"   ← keep secret

function rewriteSubdomainPanel(request: NextRequest, requestHeaders: Headers): NextResponse | null {
  const hostname = request.headers.get('host')?.split(':')[0] ?? '';
  const { pathname } = request.nextUrl;

  const ownerHostnames = (process.env.OWNER_HOSTNAMES ?? '')
    .split(',').map((h) => h.trim()).filter(Boolean);
  const adminHostnames = (process.env.ADMIN_HOSTNAME ?? '')
    .split(',').map((h) => h.trim()).filter(Boolean);

  const isOwnerHost = ownerHostnames.some((h) => hostname === h);
  const isAdminHost = adminHostnames.some((h) => hostname === h);

  if (!isOwnerHost && !isAdminHost) return null;

  const prefix = isOwnerHost ? '/sahip' : '/yonetici';
  // Root → /sahip or /yonetici, sub-paths → /sahip/path or /yonetici/path
  const suffix = pathname === '/' ? '' : pathname;
  const url = request.nextUrl.clone();
  url.pathname = `${prefix}${suffix}`;
  // Use rewrite so URL bar stays as isletme.yeedoy.com/...
  return NextResponse.rewrite(url, { request: { headers: requestHeaders } });
}

// ── Protected panel route guard ───────────────────────────────────────────────
// Turkish-language aliases for the same panels
const YONETICI_PREFIX = '/yonetici';  // canonical Turkish path for the admin panel
const SAHIP_PREFIX = '/sahip';        // owner panel pages (canonical Turkish path)
// /sunucu/yonetici/* routes are NOT rewritten by subdomain logic — guard
// them explicitly at the middleware level.
const SUNUCU_YONETICI_PREFIX = '/sunucu/yonetici';
const LOGIN_PATH = '/giris';
// Owner routes redirect unauthenticated users to the canonical login page.
const OWNER_LOGIN_PATH = '/giris';

async function guardPanelRoute(request: NextRequest, requestHeaders: Headers): Promise<NextResponse | null> {
  const { pathname } = request.nextUrl;
  // Exclude public owner pages from the auth guard
  const OWNER_PUBLIC_PATHS = [OWNER_LOGIN_PATH, '/sahip'];
  const isOwnerRoute =
    pathname.startsWith(SAHIP_PREFIX) && !OWNER_PUBLIC_PATHS.includes(pathname);
  const isAdminRoute = pathname.startsWith(YONETICI_PREFIX);
  // /sunucu/yonetici/* sits outside the panel prefix — guard it with the
  // same admin-role logic.
  const isAdminApiRoute = pathname.startsWith(SUNUCU_YONETICI_PREFIX);

  if (!isOwnerRoute && !isAdminRoute && !isAdminApiRoute) return null;

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!supabaseUrl || !supabaseAnonKey) return null;

  const response = NextResponse.next({ request: { headers: requestHeaders } });

  const supabase = createServerClient(supabaseUrl, supabaseAnonKey, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(cookiesToSet: { name: string; value: string; options?: Record<string, unknown> }[]) {
        cookiesToSet.forEach(({ name, value, options }) => {
          request.cookies.set(name, value);
          response.cookies.set(name, value, options as Parameters<typeof response.cookies.set>[2]);
        });
      },
    },
  });

  let user = null;
  try {
    const { data } = await supabase.auth.getUser();
    user = data.user;
  } catch {
    // Expired / already-used refresh token — treat as unauthenticated.
  }

  if (!user) {
    const loginUrl = request.nextUrl.clone();
    // Owner routes go to the owner-specific login page; admin/api routes use generic login.
    loginUrl.pathname = isOwnerRoute ? OWNER_LOGIN_PATH : LOGIN_PATH;
    loginUrl.searchParams.set('redirect', pathname);
    return NextResponse.redirect(loginUrl);
  }

  // Admin routes require admin role.
  if (isAdminRoute || isAdminApiRoute) {
    const { data: isAdmin, error: adminCheckError } = await supabase.rpc('is_admin');

    if (adminCheckError) {
      console.error(
        '[middleware] is_admin rpc error',
        `code=${adminCheckError.code}`,
        `pathname=${request.nextUrl.pathname}`,
      );
      const forbiddenUrl = request.nextUrl.clone();
      forbiddenUrl.pathname = '/forbidden';
      return NextResponse.redirect(forbiddenUrl);
    }

    if (!isAdmin) {
      const forbiddenUrl = request.nextUrl.clone();
      forbiddenUrl.pathname = '/forbidden';
      return NextResponse.redirect(forbiddenUrl);
    }
  }

  // Owner routes require at least one approved owner_claim.
  if (isOwnerRoute) {
    const { data: isOwner, error: ownerCheckError } = await supabase.rpc('is_owner');

    if (ownerCheckError) {
      console.error(
        '[middleware] is_owner rpc error',
        `code=${ownerCheckError.code}`,
        `pathname=${request.nextUrl.pathname}`,
      );
      const forbiddenUrl = request.nextUrl.clone();
      forbiddenUrl.pathname = '/forbidden';
      return NextResponse.redirect(forbiddenUrl);
    }

    if (!isOwner) {
      const forbiddenUrl = request.nextUrl.clone();
      forbiddenUrl.pathname = '/forbidden';
      return NextResponse.redirect(forbiddenUrl);
    }
  }

  // Prevent search engine indexing of panel routes (not API routes)
  if (!isAdminApiRoute) {
    response.headers.set('X-Robots-Tag', 'noindex, nofollow');
  }
  return response;
}

// ── Custom domain → slug cache (in-memory, per Node.js process instance, ~5 min TTL) ──
// Next.js 16: Proxy always runs on the Node.js runtime (no Edge opt-in), so this
// cache's lifetime/scope now follows Node process lifecycle instead of an Edge isolate.
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

export async function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const hostname = request.headers.get('host')?.split(':')[0] ?? '';

  const nonce = Buffer.from(crypto.randomUUID()).toString('base64');
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set('x-nonce', nonce);
  const isEmbed = pathname.startsWith('/embed/');
  const csp = buildCsp(nonce, isEmbed);

  const applyCsp = (response: NextResponse): NextResponse => {
    response.headers.set('Content-Security-Policy', csp);
    return response;
  };

  // ── Panel subdomain rewrite (isletme.* / ops.*) ───────────────────────────
  // Must run before the custom-domain slug lookup so panel subdomains are not
  // mistakenly treated as business custom domains.
  const subdomainRewrite = rewriteSubdomainPanel(request, requestHeaders);
  if (subdomainRewrite) return applyCsp(subdomainRewrite);

  // ── Custom domain rewrite ─────────────────────────────────────────────────
  // If the request comes in on a custom domain (not yeedoy.com / localhost),
  // look up the business slug and rewrite to /m/[slug] (URL stays unchanged).
  const ownHostnames = (process.env.OWN_HOSTNAMES ?? 'localhost,yeedoy.com').split(',').map((h) => h.trim());
  // Also exclude panel subdomains from custom-domain lookup
  const ownerHostnames = (process.env.OWNER_HOSTNAMES ?? '').split(',').map((h) => h.trim()).filter(Boolean);
  const adminHostnames = (process.env.ADMIN_HOSTNAME ?? '').split(',').map((h) => h.trim()).filter(Boolean);
  const panelHostnames = [...ownerHostnames, ...adminHostnames];
  const isOwnHost =
    ownHostnames.some((h) => hostname === h || hostname.endsWith(`.${h}`)) ||
    panelHostnames.some((h) => hostname === h);

  if (!isOwnHost && hostname && hostname !== '') {
    const slug = await resolveCustomDomainSlug(hostname);
    if (slug) {
      const url = request.nextUrl.clone();
      // Rewrite root and any sub-path to /m/[slug]/...
      const suffix = pathname === '/' ? '' : pathname;
      url.pathname = `/m/${slug}${suffix}`;
      return applyCsp(NextResponse.rewrite(url, { request: { headers: requestHeaders } }));
    }
  }

  const panelGuard = await guardPanelRoute(request, requestHeaders);
  if (panelGuard) return applyCsp(panelGuard);

  const routeGuard = normalizePublicRoute(request);
  if (routeGuard) {
    return applyCsp(routeGuard);
  }

  if (
    !pathname.startsWith('/m/') &&
    !pathname.startsWith('/sunucu/izleme') &&
    !pathname.startsWith('/api/media/upload') &&
    !pathname.startsWith('/api/presentation-settings') &&
    !pathname.startsWith('/qr/') &&
    !pathname.startsWith('/karekod/') &&
    pathname !== '/auth/panel-handoff'
  ) {
    return applyCsp(NextResponse.next({ request: { headers: requestHeaders } }));
  }

  const identity = getRequestIdentity({
    ip: getClientIp(request.headers),
    userAgent: request.headers.get('user-agent'),
  });

  const policy = pathname.startsWith('/sunucu/izleme')
    ? rateLimit(`middleware:track:${identity}`, 60, 60_000)
    : pathname.startsWith('/api/media/upload')
      ? rateLimit(`middleware:media-upload:${identity}`, 20, 60_000)
      : pathname.startsWith('/api/presentation-settings')
        ? rateLimit(`middleware:presentation-settings:${identity}`, 30, 60_000)
    : pathname === '/auth/panel-handoff'
      ? rateLimit(`middleware:panel-handoff:${identity}`, 20, 60_000)
      : rateLimit(`middleware:qr:${identity}`, 20, 60_000);

  if (policy.ok) {
    return applyCsp(NextResponse.next({ request: { headers: requestHeaders } }));
  }

  return applyCsp(NextResponse.json({ error: 'rate_limited' }, { status: 429 }));
}

export const config = {
  matcher: [
    // Custom domain rewrite needs to run on all paths
    '/((?!_next/static|_next/image|favicon.ico).*)',
  ],
};

function normalizePublicRoute(request: NextRequest) {
  const { pathname, searchParams } = request.nextUrl;
  if (
    !pathname.startsWith('/m/') &&
    !pathname.startsWith('/qr/') &&
    !pathname.startsWith('/karekod/')
  ) {
    return null;
  }

  const segments = pathname.split('/').filter(Boolean);
  const businessPath = segments[1] ?? null;
  if (!businessPath) {
    return createNotFoundResponse();
  }

  if (pathname.startsWith('/qr/') || pathname.startsWith('/karekod/')) {
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
