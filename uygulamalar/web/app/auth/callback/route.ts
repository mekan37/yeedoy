import { NextResponse } from 'next/server';
import { cookies } from 'next/headers';
import { createServerClient } from '@supabase/ssr';
import { appConfig } from '@/src/lib/ayarlar';
import { sanitizeInternalRedirect } from '@/src/lib/guvenli-yonlendirme';
import type { Database } from '@/src/lib/taban/veri-tanimlari';

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get('code');
  const redirect = searchParams.get('redirect');
  const next = sanitizeInternalRedirect(redirect ?? '/', '/');

  if (!code) {
    return NextResponse.redirect(`${origin}/giris?error=oauth_failed`);
  }

  const cookieStore = await cookies();
  const response = NextResponse.redirect(`${origin}${next}`);

  const supabase = createServerClient<Database>(
    appConfig.supabaseUrl(),
    appConfig.supabaseAnonKey(),
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(
          cookiesToSet: Array<{ name: string; value: string; options?: Record<string, unknown> }>,
        ) {
          cookiesToSet.forEach(({ name, value, options }) => {
            response.cookies.set(
              name,
              value,
              options as Parameters<typeof response.cookies.set>[2],
            );
          });
        },
      },
    },
  );

  const { error } = await supabase.auth.exchangeCodeForSession(code);
  if (error) {
    return NextResponse.redirect(`${origin}/giris?error=oauth_failed`);
  }

  return response;
}
