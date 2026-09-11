import 'server-only';
import { createClient } from '@supabase/supabase-js';
import { appConfig } from '@/src/lib/ayarlar';
import type { Database } from '@/src/lib/taban/veri-tanimlari';

// SUPABASE_SERVICE_ROLE_KEY (RLS'i tamamen bypass eder) kullanır — bu modül
// yanlışlıkla bir Client Component'e import edilirse 'server-only' derleme
// zamanında hata verir, key'in tarayıcı bundle'ına sızmasını engeller.

export function createSupabaseServiceClient() {
  const serviceRoleKey = appConfig.serviceRoleKey();
  if (!serviceRoleKey) return null;

  return createClient<Database>(appConfig.supabaseUrl(), serviceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}
