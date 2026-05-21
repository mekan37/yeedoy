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

  const { data: sessionData, error } = await supabase.auth.exchangeCodeForSession(code);
  if (error) {
    return NextResponse.redirect(`${origin}/giris?error=oauth_failed`);
  }

  // Profil yoksa oluştur (e-posta kayıt veya OAuth)
  if (sessionData.user) {
    const user = sessionData.user;
    const { data: existing } = await (supabase as any)
      .from('user_profiles')
      .select('user_id')
      .eq('user_id', user.id)
      .maybeSingle() as { data: { user_id: string } | null };

    if (!existing) {
      // display_name: user metadata (e-posta kaydı) veya provider name (OAuth)
      const displayName =
        (user.user_metadata?.display_name as string | undefined) ||
        (user.user_metadata?.full_name as string | undefined) ||
        (user.user_metadata?.name as string | undefined) ||
        user.email?.split('@')[0] ||
        'Kullanıcı';

      await (supabase as any).from('user_profiles').insert({
        user_id: user.id,
        display_name: displayName.slice(0, 60),
      } as Record<string, unknown>);
    }
  }

  return response;
}
