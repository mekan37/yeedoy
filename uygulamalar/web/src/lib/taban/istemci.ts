import { createBrowserClient } from '@supabase/ssr';
import { appConfig } from '@/src/lib/ayarlar';
import type { Database } from '@/src/lib/taban/veri-tanimlari';

export function createSupabaseBrowserClient() {
  return createBrowserClient<Database>(
    appConfig.supabaseUrl(),
    appConfig.supabaseAnonKey(),
  );
}
