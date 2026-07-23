import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
import { appConfig } from '@/src/lib/ayarlar';
import type { Database } from '@/src/lib/supabase/database.types';

export async function createSupabaseServerClient() {
  const cookieStore = await cookies();

  return createServerClient<Database>(
    appConfig.supabaseUrl(),
    appConfig.supabaseAnonKey(),
    {
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
