import { createBrowserClient } from '@supabase/ssr';
import { appConfig } from '@/src/lib/ayarlar';
import type { Database } from '@/src/lib/taban/veri-tanimlari';

export function createSupabaseBrowserClient() {
  return createBrowserClient<Database>(
    appConfig.supabaseUrl(),
    appConfig.supabaseAnonKey(),
    // @supabase/ssr'ın varsayılan cookie ayarları secure bayrağı içermiyor —
    // bkz. src/lib/taban/sunucu.ts'deki aynı düzeltme. process.env.NODE_ENV
    // Next.js tarafından build-time'da inline edildiği için client'ta güvenle
    // okunabilir.
    { cookieOptions: { secure: process.env.NODE_ENV === 'production' } },
  );
}
