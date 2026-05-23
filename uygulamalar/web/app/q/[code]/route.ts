import { NextResponse } from 'next/server';
import { resolveBrandTheme } from '@/src/lib/brand-theme';
import { logger } from '@/src/lib/logger';
import { buildMenuHref } from '@/src/lib/menu-links';
import { decodeBusinessCode } from '@/src/lib/short-code';

export const runtime = 'edge';

type RouteContext = {
  params: Promise<{ code: string }>;
};

export async function GET(request: Request, context: RouteContext) {
  const startedAt = Date.now();
  const { code } = await context.params;
  const businessId = decodeBusinessCode(code);

  if (!businessId) {
    return new NextResponse(null, { status: 404 });
  }

  const requestUrl = new URL(request.url);
  const lang = requestUrl.searchParams.get('lang') || 'tr';
  const theme = resolveBrandTheme(requestUrl.searchParams.get('theme'));
  const redirectTarget = buildMenuHref({
    businessId,
    lang,
    theme,
    src: 'qr',
  });

  const redirectMs = Date.now() - startedAt;
  const trackResponse = await fetch(new URL('/api/track', request.url), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      eventName: 'qr_scanned',
      businessId,
      menuId: null,
      source: 'qr_short_link',
      clientId: null,
      meta: {
        code,
        lang,
        theme,
        redirect_ms: redirectMs,
      },
    }),
  }).catch((error) => {
    logger.warn('Failed to invoke /api/track from short QR redirect', {
      businessId,
      code,
      error: error instanceof Error ? error.message : String(error),
    });
    return null;
  });

  if (trackResponse && !trackResponse.ok) {
    logger.warn('Short QR redirect tracking returned non-200', {
      businessId,
      code,
      status: trackResponse.status,
    });
  }

  const response = NextResponse.redirect(new URL(redirectTarget, request.url), 307);
  response.headers.set('Server-Timing', `redirect;dur=${Date.now() - startedAt}`);
  return response;
}
