# CSP script-src Nonce Sertleştirmesi Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Production CSP'sinin `script-src` yönergesinden `'unsafe-inline'`'ı kaldırıp per-request kriptografik nonce ile değiştirmek — SecurityHeaders.com ve MDN HTTP Observatory'nin işaretlediği güvenlik bulgusunu kapatmak.

**Architecture:** Nonce, `uygulamalar/web/proxy.ts` içinde her istekte `crypto.randomUUID()` ile üretilir; hem `x-nonce` request header'ına (downstream route handler'ların okuması için) hem CSP response header'ındaki `script-src`'ye (`'nonce-{değer}'`) yazılır. Next.js, CSP header'ından nonce'u otomatik ayrıştırıp kendi hydration/runtime script'lerine uygular. `next.config.mjs`'nin statik `headers()`'ından `Content-Security-Policy` satırı tamamen kaldırılır (artık `proxy.ts` üretiyor). **JSON-LD `<script type="application/ld+json">` etiketlerine dokunulmuyor** — bu bir spec revizyonu: lokal tarayıcı testiyle doğrulandı ki `application/ld+json` tipi bir script CSP `script-src` denetimine hiç girmiyor (tarayıcı bunu JS olarak yürütmüyor), o yüzden nonce eklemeye gerek yok. Bu sayede JSON-LD içeren 7 sayfa (hepsi ISR/`revalidate` ile statik üretiliyor) `headers()` okumak zorunda kalmıyor ve Frankfurt migrasyonuyla kazanılan performans korunuyor. Nonce'a gerçekten ihtiyaç duyan tek yer, ham HTML döndüren ve tipsiz (gerçek JS) `<script>` içeren iki route handler: `app/auth/panel-handoff/route.ts` ve `app/kimlik/panel-devir/route.ts`.

**Tech Stack:** Next.js 16.2.11 (Turbopack), TypeScript, Node.js runtime proxy (`proxy.ts`), Vitest.

---

## Spec Revizyonu Notu (brainstorming sonrası bulgu)

Onaylanan tasarım dokümanı (`docs/superpowers/specs/2026-08-26-csp-nonce-script-src-design.md`) 8 sayfadaki JSON-LD script'lerine `nonce={nonce}` eklemeyi öngörüyordu. Bu plan yazılırken şu bulgular ortaya çıktı ve kapsamı revize etti:

1. **JSON-LD nonce gerektirmiyor.** Lokal bir test sayfasıyla doğrulandı: `<script type="application/ld+json">` (tipsiz/JS olmayan) hiçbir CSP `script-src` ihlaline yol açmıyor, nonce olsun olmasın. Tarayıcı bu elementi script yürütme bağlamı olarak görmüyor (CSP spesifikasyonu `script-src`'yi yalnızca JS-tipi `<script>` elementlerine uyguluyor).
2. **8 sayfanın hepsi ISR/statik** (`export const revalidate = 120..3600`, çoğu `generateStaticParams` ile). Nonce'u okumak için bu sayfalarda `headers()` çağırmak gerekseydi, Next.js bu sayfaları zorla per-request dynamic render'a düşürürdü — bu da bu oturumda Supabase bölge migrasyonuyla kazanılan TTFB iyileştirmesini geçersiz kılan ciddi bir performans regresyonu olurdu.
3. **`app/auth/panel-handoff/route.ts` ve `app/kimlik/panel-devir/route.ts`** grep'te belirsiz kalmıştı — okundu ve ikisinin de ham HTML string'i içinde tipsiz (gerçek JS) `<script>window.location.replace(...)</script>` içerdiği doğrulandı. Bunlar nonce olmadan CSP tarafından bloklanacak — bu iki dosya plana eklendi.

Sonuç: JSON-LD sayfalarına dokunulmuyor (kapsamdan çıkarıldı), 2 route handler eklendi. Toplam değişen dosya sayısı 8'den 4'e düştü.

---

## Task 1: `proxy.ts` — nonce üretimi + dinamik CSP

**Files:**
- Modify: `uygulamalar/web/proxy.ts` (tüm dosya — aşağıdaki gibi yeniden yazılacak)

- [ ] **Step 1: `proxy.ts`'in tamamını aşağıdaki içerikle değiştir**

```ts
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
```

Bu, dosyanın mevcut mantığının **tamamını korur** (subdomain rewrite, custom-domain rewrite, panel guard, rate limit, 404 sayfası) — tek eklenen şey nonce üretimi, `requestHeaders`'ın `rewriteSubdomainPanel`/`guardPanelRoute`/her `NextResponse.next()` çağrısına aktarılması, ve her dönüş noktasının `applyCsp(...)` ile sarılması.

- [ ] **Step 2: Typecheck çalıştır**

Run: `pnpm run typecheck` (uygulamalar/web içinde)
Expected: 0 hata. (`Buffer` ve `crypto` Node.js runtime globalleri — proxy.ts zaten "Next.js 16: Proxy always runs on the Node.js runtime" yorumuyla bunu belgeliyor, ekstra import gerekmez.)

- [ ] **Step 3: Lint çalıştır**

Run: `pnpm run lint`
Expected: 0 hata.

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/web/proxy.ts
git commit -m "feat(web): CSP script-src nonce üretimi proxy.ts'e eklendi"
```

---

## Task 2: `next.config.mjs` — statik CSP kaldırılması

**Files:**
- Modify: `uygulamalar/web/next.config.mjs:179-276` (mevcut `headers()` fonksiyonu)

- [ ] **Step 1: `headers()` fonksiyonunun içeriğini aşağıdakiyle değiştir**

Mevcut (satır 179-276):

```js
  async headers() {
    const supabaseHost = (() => {
      try { return new URL(process.env.NEXT_PUBLIC_SUPABASE_URL ?? '').hostname; } catch { return '*.supabase.co'; }
    })();

    const isDev = process.env.NODE_ENV === 'development';

    const ContentSecurityPolicy = [
      "default-src 'self'",
      // 'unsafe-eval' is required by Next.js React Fast Refresh in development only.
      // Production builds do not use eval and this directive is omitted there.
      `script-src 'self' 'unsafe-inline'${isDev ? " 'unsafe-eval'" : ''} https://vercel-scripts.com https://va.vercel-scripts.com`,
      "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
      "font-src 'self' data: https://fonts.gstatic.com",
      "img-src 'self' data: blob: https: http:",
      // MapLibre GL v6 loads its WebGL worker as a same-origin module file
      // (new Worker(url, { type: 'module' })) rather than a blob: URL like
      // v5 did — 'self' is required, blob: kept for other/older code paths.
      "worker-src 'self' blob:",
      // In development, also allow the local WebSocket HMR connection.
      `connect-src 'self'${isDev ? ' ws://localhost:* ws://127.0.0.1:*' : ''} https://${supabaseHost} wss://${supabaseHost} https://*.supabase.co wss://*.supabase.co https://fonts.googleapis.com https://maps.yeedoy.com https://cdn.jsdelivr.net`,
      "frame-src https://www.openstreetmap.org",
      "frame-ancestors 'none'",
      "base-uri 'self'",
      "form-action 'self'",
      "upgrade-insecure-requests",
    ].join('; ');

    // Embed pages allow framing from any origin (they are designed to be iframed)
    const EmbedCSP = ContentSecurityPolicy.replace("frame-ancestors 'none'", "frame-ancestors *");

    return [
      // Embed viewer: allow iframing from any origin
      {
        source: '/embed/:businessId*',
        headers: [
          { key: 'X-Frame-Options', value: 'ALLOWALL' },
          { key: 'Content-Security-Policy', value: EmbedCSP },
        ],
      },
      {
        source: '/:path*',
        headers: [
          {
            key: 'Strict-Transport-Security',
            value: 'max-age=31536000; includeSubDomains',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'X-Frame-Options',
            value: 'SAMEORIGIN',
          },
          {
            key: 'Content-Security-Policy',
            value: ContentSecurityPolicy,
          },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=(self), payment=()',
          },
        ],
      },
      {
        source: '/robots.txt',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=0, s-maxage=3600, stale-while-revalidate=86400',
          },
        ],
      },
      {
        source: '/sitemap.xml',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=0, s-maxage=3600, stale-while-revalidate=86400',
          },
        ],
      },
      {
        source: '/api/og',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=0, s-maxage=86400, stale-while-revalidate=604800',
          },
        ],
      },
    ];
  },
```

Yeni:

```js
  async headers() {
    // Content-Security-Policy artık proxy.ts'te per-request nonce ile
    // dinamik olarak üretiliyor (bkz. proxy.ts buildCsp). Burada sabit
    // olarak set edilmiyor.
    return [
      // Embed viewer: allow iframing from any origin
      {
        source: '/embed/:businessId*',
        headers: [
          { key: 'X-Frame-Options', value: 'ALLOWALL' },
        ],
      },
      {
        source: '/:path*',
        headers: [
          {
            key: 'Strict-Transport-Security',
            value: 'max-age=31536000; includeSubDomains',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'X-Frame-Options',
            value: 'SAMEORIGIN',
          },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=(self), payment=()',
          },
        ],
      },
      {
        source: '/robots.txt',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=0, s-maxage=3600, stale-while-revalidate=86400',
          },
        ],
      },
      {
        source: '/sitemap.xml',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=0, s-maxage=3600, stale-while-revalidate=86400',
          },
        ],
      },
      {
        source: '/api/og',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=0, s-maxage=86400, stale-while-revalidate=604800',
          },
        ],
      },
    ];
  },
```

(`supabaseHost`, `isDev`, `ContentSecurityPolicy`, `EmbedCSP` — bunların hepsi `buildCsp()` içinde `proxy.ts`'e taşındı, burada artık kullanılmıyor, kaldırıldılar.)

- [ ] **Step 2: Typecheck + lint çalıştır**

Run: `pnpm run typecheck && pnpm run lint`
Expected: 0 hata.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/next.config.mjs
git commit -m "refactor(web): statik CSP next.config.mjs'den kaldırıldı, proxy.ts'e taşındı"
```

---

## Task 3: `app/auth/panel-handoff/route.ts` — inline redirect script'ine nonce

**Files:**
- Modify: `uygulamalar/web/app/auth/panel-handoff/route.ts`
- Test: `uygulamalar/web/test/api/panel-redirect-html-nonce.test.ts` (yeni)

**Bağlam:** Bu route handler, ham HTML string'i üreten `renderRedirectHtml()` fonksiyonunu kullanıyor (React/JSX değil — `new NextResponse(html, {...})` ile dönülüyor). İçinde `<meta http-equiv="refresh">` ile birincil yönlendirme yapılıyor, `<script>window.location.replace(...)</script>` ise yedek/ikincil yönlendirme mekanizması. Bu script tipsiz (varsayılan JS tipi) olduğu için CSP `script-src`'de nonce olmadan bloklanacak. `autoRedirect: false` geçildiğinde (hata sayfası) script hiç render edilmiyor, o yüzden sadece başarı yolunda gerçekten devreye giriyor.

- [ ] **Step 1: Başarısız olacak testi yaz**

`uygulamalar/web/test/api/panel-redirect-html-nonce.test.ts` dosyasını oluştur:

```ts
import { describe, expect, it } from 'vitest';
import { renderRedirectHtml as renderPanelHandoffRedirectHtml } from '@/app/auth/panel-handoff/route';
import { renderRedirectHtml as renderPanelDevirRedirectHtml } from '@/app/kimlik/panel-devir/route';

describe('panel-handoff redirect HTML nonce', () => {
  it('auto-redirect sırasında inline script nonce içeriyor', () => {
    const html = renderPanelHandoffRedirectHtml({
      title: 'Redirecting',
      message: 'Redirecting now.',
      destination: '/karekod/abc',
      ctaLabel: 'Open',
      nonce: 'test-nonce-value',
    });
    expect(html).toContain('<script nonce="test-nonce-value">');
  });

  it('autoRedirect false ise inline script hiç render edilmiyor', () => {
    const html = renderPanelHandoffRedirectHtml({
      title: 'Failed',
      message: 'Could not restore session.',
      destination: '/giris',
      ctaLabel: 'Open login',
      nonce: 'test-nonce-value',
      autoRedirect: false,
    });
    expect(html).not.toContain('<script');
  });
});

describe('panel-devir redirect HTML nonce', () => {
  it('auto-redirect sırasında inline script nonce içeriyor', () => {
    const html = renderPanelDevirRedirectHtml({
      title: 'Yonlendiriliyor',
      message: 'Simdi yonlendiriliyorsunuz.',
      destination: '/karekod/abc',
      ctaLabel: 'Ac',
      nonce: 'test-nonce-value',
    });
    expect(html).toContain('<script nonce="test-nonce-value">');
  });

  it('autoRedirect false ise inline script hiç render edilmiyor', () => {
    const html = renderPanelDevirRedirectHtml({
      title: 'Basarisiz',
      message: 'Oturum geri yuklenemedi.',
      destination: '/giris',
      ctaLabel: 'Giris ac',
      nonce: 'test-nonce-value',
      autoRedirect: false,
    });
    expect(html).not.toContain('<script');
  });
});
```

- [ ] **Step 2: Testin şu an derleme hatasıyla başarısız olduğunu doğrula**

Run: `cd uygulamalar/web && npx vitest run test/api/panel-redirect-html-nonce.test.ts`
Expected: FAIL — `renderRedirectHtml` her iki route dosyasından da henüz export edilmiyor (`Module does not provide an export named 'renderRedirectHtml'` veya benzeri) ve `nonce` alanı henüz tipte yok.

- [ ] **Step 3: `app/auth/panel-handoff/route.ts`'i güncelle**

`renderRedirectHtml` fonksiyon imzasını değiştir (satır 191):

Mevcut:
```ts
function renderRedirectHtml(input: {
  title: string;
  message: string;
  destination: string;
  ctaLabel: string;
  autoRedirect?: boolean;
}) {
```

Yeni:
```ts
export function renderRedirectHtml(input: {
  title: string;
  message: string;
  destination: string;
  ctaLabel: string;
  nonce: string;
  autoRedirect?: boolean;
}) {
```

Script satırını değiştir (satır 282-286):

Mevcut:
```ts
      ${
        shouldRedirect
          ? `<script>window.location.replace(${JSON.stringify(input.destination)});</script>`
          : ''
      }
```

Yeni:
```ts
      ${
        shouldRedirect
          ? `<script nonce="${escapeHtml(input.nonce)}">window.location.replace(${JSON.stringify(input.destination)});</script>`
          : ''
      }
```

`createPanelHandoffSuccessResponse` içindeki çağrıyı güncelle (satır 120-125):

Mevcut:
```ts
  const html = renderRedirectHtml({
    title: 'Redirecting to QR Studio',
    message: 'Your owner session is ready. Redirecting to the QR Studio now.',
    destination: input.destination,
    ctaLabel: 'Open QR Studio',
  });
```

Yeni:
```ts
  const nonce = input.request.headers.get('x-nonce') ?? '';
  const html = renderRedirectHtml({
    title: 'Redirecting to QR Studio',
    message: 'Your owner session is ready. Redirecting to the QR Studio now.',
    destination: input.destination,
    ctaLabel: 'Open QR Studio',
    nonce,
  });
```

`createPanelHandoffErrorResponse` içindeki çağrıyı güncelle (satır 155-161):

Mevcut:
```ts
  const html = renderRedirectHtml({
    title: 'Owner session could not be restored',
    message: 'Your panel session could not be validated. Open the login page and continue to the same QR Studio route.',
    destination: loginUrl,
    ctaLabel: 'Open login',
    autoRedirect: false,
  });
```

Yeni:
```ts
  const nonce = input.request.headers.get('x-nonce') ?? '';
  const html = renderRedirectHtml({
    title: 'Owner session could not be restored',
    message: 'Your panel session could not be validated. Open the login page and continue to the same QR Studio route.',
    destination: loginUrl,
    ctaLabel: 'Open login',
    nonce,
    autoRedirect: false,
  });
```

- [ ] **Step 4: `app/kimlik/panel-devir/route.ts`'i aynı şekilde güncelle**

`renderRedirectHtml` fonksiyon imzasını değiştir (satır 191):

Mevcut:
```ts
function renderRedirectHtml(input: {
  title: string;
  message: string;
  destination: string;
  ctaLabel: string;
  autoRedirect?: boolean;
}) {
```

Yeni:
```ts
export function renderRedirectHtml(input: {
  title: string;
  message: string;
  destination: string;
  ctaLabel: string;
  nonce: string;
  autoRedirect?: boolean;
}) {
```

Script satırını değiştir (satır 282-286) — panel-handoff ile birebir aynı:

Mevcut:
```ts
      ${
        shouldRedirect
          ? `<script>window.location.replace(${JSON.stringify(input.destination)});</script>`
          : ''
      }
```

Yeni:
```ts
      ${
        shouldRedirect
          ? `<script nonce="${escapeHtml(input.nonce)}">window.location.replace(${JSON.stringify(input.destination)});</script>`
          : ''
      }
```

`createPanelHandoffSuccessResponse` içindeki çağrıyı güncelle (satır 120-125):

Mevcut:
```ts
  const html = renderRedirectHtml({
    title: 'Karekod tasarim kitine yonlendiriliyor',
    message: 'Sahip oturumunuz hazir. Simdi karekod tasarim kitine yonlendiriliyorsunuz.',
    destination: input.destination,
    ctaLabel: 'Karekod tasarim kitini ac',
  });
```

Yeni:
```ts
  const nonce = input.request.headers.get('x-nonce') ?? '';
  const html = renderRedirectHtml({
    title: 'Karekod tasarim kitine yonlendiriliyor',
    message: 'Sahip oturumunuz hazir. Simdi karekod tasarim kitine yonlendiriliyorsunuz.',
    destination: input.destination,
    ctaLabel: 'Karekod tasarim kitini ac',
    nonce,
  });
```

`createPanelHandoffErrorResponse` içindeki çağrıyı güncelle (satır 155-161):

Mevcut:
```ts
  const html = renderRedirectHtml({
    title: 'Sahip oturumu geri yuklenemedi',
    message: 'Panel oturumunuz dogrulanamadi. Giris sayfasini acip ayni karekod tasarim kiti yoluna devam edin.',
    destination: loginUrl,
    ctaLabel: 'Open login',
    autoRedirect: false,
  });
```

Yeni:
```ts
  const nonce = input.request.headers.get('x-nonce') ?? '';
  const html = renderRedirectHtml({
    title: 'Sahip oturumu geri yuklenemedi',
    message: 'Panel oturumunuz dogrulanamadi. Giris sayfasini acip ayni karekod tasarim kiti yoluna devam edin.',
    destination: loginUrl,
    ctaLabel: 'Open login',
    nonce,
    autoRedirect: false,
  });
```

- [ ] **Step 5: Testin şimdi geçtiğini doğrula**

Run: `cd uygulamalar/web && npx vitest run test/api/panel-redirect-html-nonce.test.ts`
Expected: PASS (4/4 test).

- [ ] **Step 6: Typecheck + lint çalıştır**

Run: `pnpm run typecheck && pnpm run lint`
Expected: 0 hata.

- [ ] **Step 7: Commit**

```bash
git add uygulamalar/web/app/auth/panel-handoff/route.ts uygulamalar/web/app/kimlik/panel-devir/route.ts uygulamalar/web/test/api/panel-redirect-html-nonce.test.ts
git commit -m "fix(web): panel-handoff/panel-devir inline redirect script'ine CSP nonce eklendi"
```

---

## Task 4: Lokal doğrulama (dev server + tarayıcı konsolu)

**Files:** Yok (yalnızca manuel/tarayıcı doğrulama — kod değişikliği içermiyor)

- [ ] **Step 1: Dev server'ı başlat**

Run: `cd uygulamalar/web && pnpm run dev` (arka planda/ayrı terminalde bırak)

- [ ] **Step 2: Ana sayfayı aç, CSP header'ını ve konsolu kontrol et**

`http://localhost:3000/` adresini tarayıcıda aç. DevTools → Network → ilk döküman isteğinin response header'larında `Content-Security-Policy` değerini kontrol et:
- `script-src` içinde `'nonce-...'` var, `'unsafe-inline'` YOK.
- Sayfayı yenile (Ctrl+R), nonce değerinin değiştiğini doğrula (her istekte farklı).
- DevTools Console'da CSP ihlali (`Refused to execute inline script...`) OLMADIĞINI doğrula.

- [ ] **Step 3: JSON-LD içeren bir işletme detay sayfasını aç**

`http://localhost:3000/isletme/<bilinen-bir-slug>` adresini aç (ya da `/m/<slug>`). Console'da CSP ihlali olmadığını doğrula. `view-source:` ile JSON-LD script tag'inin nonce'suz kaldığını (beklenen — Task'ın "Spec Revizyonu" notu gereği) ve yine de sorunsuz render edildiğini doğrula.

- [ ] **Step 4: Bir embed sayfasını aç**

`http://localhost:3000/embed/<bilinen-bir-business-id>` adresini aç. Response header'ında `Content-Security-Policy`'nin `frame-ancestors *` içerdiğini (embed varyantı) ve `script-src`'nin nonce içerdiğini doğrula.

- [ ] **Step 5: Playwright e2e suite'i çalıştır**

Run: `pnpm run test:e2e`
Expected: Mevcut suite regresyonsuz geçer.

---

## Task 5: Deploy sonrası doğrulama

**Files:** Yok

- [ ] **Step 1: Vercel'e deploy et, READY durumunu bekle**

(Kullanıcının onayıyla — bu adım git push + Vercel otomatik deploy tetikler, ya da `vercel --prod` — kullanıcıya sorulacak.)

- [ ] **Step 2: Canlı CSP header'ını curl ile doğrula**

Run: `curl -sI https://www.yeedoy.com/ | grep -i content-security-policy`
Expected: `script-src` içinde `'nonce-...'` var, `'unsafe-inline'` yok.

- [ ] **Step 3: SecurityHeaders.com'u yeniden tara**

`https://securityheaders.com/?q=https://www.yeedoy.com` — CSP bulgusunun artık geçtiğini, notun A+'e yükseldiğini doğrula.

- [ ] **Step 4: MDN HTTP Observatory'yi yeniden tara**

`https://developer.mozilla.org/en-US/observatory/analyze?host=www.yeedoy.com` — CSP script-src bulgusunun kapandığını, puanın arttığını doğrula.
```

---

## Self-Review (plan yazarı tarafından yapıldı)

**1. Spec kapsaması:** Onaylanan tasarım dokümanının 4 mimari maddesi:
1. `proxy.ts`'e nonce üretimi + dinamik CSP → Task 1 ✅
2. `next.config.mjs`'den statik CSP kaldırma → Task 2 ✅
3. 8 sayfadaki JSON-LD'ye nonce → **Spec Revizyonu** ile kapsam dışı bırakıldı (gerekçe yukarıda, JSON-LD CSP script-src'ye tabi değil) — bunun yerine gerçekten nonce gerektiren 2 route handler bulundu ve eklendi (Task 3) ✅
4. style-src değiştirilmedi → Task 1/2'de dokunulmadı ✅
Test planı (lokal doğrulama, typecheck/lint, e2e, deploy sonrası tarama) → Task 4 + Task 5 ✅

**2. Placeholder taraması:** Tüm adımlarda tam kod, tam dosya yolları, tam komutlar var. "TBD/uygun şekilde/benzer şekilde" kalıbı yok.

**3. Tip/isim tutarlılığı:** `renderRedirectHtml`'in `nonce: string` parametresi her iki dosyada ve testte aynı isimle kullanılıyor; `buildCsp(nonce, isEmbed)` imzası proxy.ts içinde tek yerde tanımlanıp tek yerde çağrılıyor; `x-nonce` header adı proxy.ts (yazan) ile route handler'lar (okuyan) arasında birebir eşleşiyor.
