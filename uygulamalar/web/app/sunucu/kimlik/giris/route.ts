import { cookies } from 'next/headers';
import { NextResponse } from 'next/server';
import { createServerClient } from '@supabase/ssr';
import { z } from 'zod';
import { appConfig } from '@/src/lib/ayarlar';
import { sanitizeInternalRedirect } from '@/src/lib/guvenli-yonlendirme';
import { getRequestIdentity, rateLimit } from '@/src/lib/oran-siniri';
import type { Database } from '@/src/lib/taban/veri-tanimlari';
import { resolveRoleBasedRedirect } from '../rol-yonlendirme/route';

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
  redirectTo: z.string().optional(),
});

export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: request.headers.get('cf-connecting-ip') ?? request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`web-login:${identity}`, 8, 60_000);

  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const rawBody = await readLoginPayload(request);
  const parsed = loginSchema.safeParse(rawBody);
  const wantsHtmlRedirect = isHtmlFormRequest(request);

  if (!parsed.success) {
    if (wantsHtmlRedirect) {
      return redirectToLogin('invalid_payload', '/sahip/gosterge-panosu');
    }
    return NextResponse.json(
      { error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors },
      { status: 400 },
    );
  }

  const redirectTo = getLoginRedirect(parsed.data.redirectTo);
  const response = NextResponse.json({ ok: true, redirectTo });
  const cookieStore = await cookies();
  const supabase = createServerClient<Database>(appConfig.supabaseUrl(), appConfig.supabaseAnonKey(), {
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
          response.cookies.set(name, value, options as Parameters<typeof response.cookies.set>[2]);
        });
      },
    },
  });

  const { data, error } = await supabase.auth.signInWithPassword({
    email: parsed.data.email.trim(),
    password: parsed.data.password,
  });

  if (error || !data.session?.user) {
    if (wantsHtmlRedirect) {
      return redirectToLogin('auth_failed', redirectTo);
    }
    return NextResponse.json({ error: error?.message ?? 'auth_failed' }, { status: 401 });
  }

  const effectiveRedirect = parsed.data.redirectTo
    ? redirectTo
    : await resolveRoleBasedRedirect(supabase as any, data.session.user.id);

  if (wantsHtmlRedirect) {
    const redirectResponse = NextResponse.redirect(new URL(effectiveRedirect, appConfig.siteUrl()), 303);
    response.cookies.getAll().forEach((cookie) => {
      redirectResponse.cookies.set(cookie);
    });
    return redirectResponse;
  }

  const finalResponse = NextResponse.json({ ok: true, redirectTo: effectiveRedirect });
  response.cookies.getAll().forEach((cookie) => {
    finalResponse.cookies.set(cookie);
  });
  return finalResponse;
}

async function readLoginPayload(request: Request) {
  const contentType = request.headers.get('content-type') ?? '';

  if (contentType.includes('application/json')) {
    return request.json().catch(() => null);
  }

  if (contentType.includes('application/x-www-form-urlencoded') || contentType.includes('multipart/form-data')) {
    const formData = await request.formData().catch(() => null);
    if (!formData) return null;
    return {
      email: formData.get('email'),
      password: formData.get('password'),
      redirectTo: formData.get('redirectTo'),
    };
  }

  return null;
}

function isHtmlFormRequest(request: Request) {
  const contentType = request.headers.get('content-type') ?? '';
  return contentType.includes('application/x-www-form-urlencoded') || contentType.includes('multipart/form-data');
}

function redirectToLogin(error: string, redirectTo: string) {
  const url = new URL('/giris', appConfig.siteUrl());
  url.searchParams.set('redirect', redirectTo);
  url.searchParams.set('error', error);
  return NextResponse.redirect(url, 303);
}

function getLoginRedirect(input?: string | null) {
  const target = normalizePanelRedirect(sanitizeInternalRedirect(input, '/sahip/gosterge-panosu'));
  if (target === '/giris' || target.startsWith('/giris?')) {
    return '/sahip/gosterge-panosu';
  }
  return target;
}

function normalizePanelRedirect(target: string) {
  const [pathWithQuery, hash = ''] = target.split('#');
  const [path, query = ''] = pathWithQuery.split('?');
  const normalizedPath = path.toLocaleLowerCase('tr-TR');
  const nextPath = normalizedPath === '/sahip' ? '/sahip/gosterge-panosu' : normalizedPath;
  return `${nextPath}${query ? `?${query}` : ''}${hash ? `#${hash}` : ''}`;
}
