import { NextResponse } from 'next/server';
import { cookies } from 'next/headers';
import { createServerClient } from '@supabase/ssr';
import { appConfig } from '@/src/lib/ayarlar';
import { sanitizeInternalRedirect } from '@/src/lib/guvenli-yonlendirme';
import { logger } from '@/src/lib/kayitci';
import type { Database } from '@/src/lib/taban/veri-tanimlari';

// user_metadata kullanıcının kendi updateUser() çağrısıyla değiştirebildiği,
// güvenilmeyen bir alan — beklenmeyen tipte (obje/array) veya aşırı uzun
// değerler insert'i sessizce patlatabilir ya da .slice() çağrısında route'u
// çökertebilir (500). Her alan burada string'e ve makul bir uzunluğa sabitlenir.
function sanitizeMetaString(value: unknown, maxLen: number): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  if (!trimmed) return null;
  return trimmed.slice(0, maxLen);
}

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
      // @supabase/ssr'ın varsayılan cookie ayarları secure bayrağı içermiyor —
      // bkz. src/lib/taban/sunucu.ts'deki aynı düzeltme.
      cookieOptions: { secure: process.env.NODE_ENV === 'production' },
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
      const meta = (user.user_metadata ?? {}) as Record<string, unknown>;

      // display_name: user metadata (e-posta kaydı) veya provider name (OAuth)
      const displayName =
        sanitizeMetaString(meta.display_name, 60) ||
        sanitizeMetaString(meta.full_name, 60) ||
        sanitizeMetaString(meta.name, 60) ||
        sanitizeMetaString(user.email?.split('@')[0], 60) ||
        'Kullanıcı';

      const profileRow: Record<string, unknown> = {
        user_id: user.id,
        display_name: displayName,
      };
      const city = sanitizeMetaString(meta.city, 80);
      const district = sanitizeMetaString(meta.district, 80);
      const phone = sanitizeMetaString(meta.phone, 20);
      if (city)     profileRow.city     = city;
      if (district) profileRow.district = district;
      if (phone)    profileRow.phone    = phone;

      const { error: insertErr } = await (supabase as any).from('user_profiles').insert(profileRow);
      if (insertErr) {
        logger.warn('auth/callback: user_profiles insert error', { code: insertErr.code, userId: user.id });
      }
    }
  }

  return response;
}
