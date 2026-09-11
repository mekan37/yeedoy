import { NextResponse } from 'next/server';
import { resolveBrandTheme } from '@/src/lib/marka-temasi';
import { logger } from '@/src/lib/kayitci';
import { buildMenuHref } from '@/src/lib/menu-baglantilari';
import { decodeBusinessCode } from '@/src/lib/kisa-kod';

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

  // En kritik dönüşüm noktası (masa QR kodu) izleme servisine bağımlı
  // kalmamalı — izleme yavaşlarsa/asılı kalırsa kullanıcı menüye ulaşmadan
  // süresiz beklemesin diye sınırlı bir zaman aşımı var.
  const redirectMs = Date.now() - startedAt;
  const trackResponse = await fetch(new URL('/sunucu/izleme', request.url), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      // Orijinal istemcinin IP/UA'sı forward edilmezse /sunucu/izleme bu iç
      // isteği 'unknown-ip' olarak görür — TÜM QR taramaları tek bir
      // rate-limit kovasını paylaşır (bkz. oran-siniri.ts getClientIp).
      'x-forwarded-for': request.headers.get('x-forwarded-for') ?? '',
      'x-real-ip': request.headers.get('x-real-ip') ?? '',
      'user-agent': request.headers.get('user-agent') ?? '',
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
    signal: AbortSignal.timeout(1500),
  }).catch((error) => {
    logger.warn('Failed to invoke /sunucu/izleme from short QR redirect', {
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

