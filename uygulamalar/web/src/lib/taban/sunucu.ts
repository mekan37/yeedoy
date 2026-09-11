import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
import { appConfig } from '@/src/lib/ayarlar';
import type { Database } from '@/src/lib/taban/veri-tanimlari';

export async function createSupabaseServerClient() {
  const cookieStore = await cookies();

  return createServerClient<Database>(
    appConfig.supabaseUrl(),
    appConfig.supabaseAnonKey(),
    {
      // @supabase/ssr'ın DEFAULT_COOKIE_OPTIONS'ı secure bayrağı içermiyor —
      // belirtilmezse oturum çerezleri Secure olmadan yazılır (production'da
      // bile). localhost geliştirme genelde HTTP üzerinden çalıştığı için
      // yalnızca production'da zorlanıyor.
      cookieOptions: { secure: process.env.NODE_ENV === 'production' },
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
          try {
            cookiesToSet.forEach(({ name, value, options }) => {
              cookieStore.set(name, value, options);
            });
          } catch {
            // Server components cannot always mutate cookies.
          }
        },
      },
    },
  );
}
