import { createClient } from '@supabase/supabase-js';
import { appConfig } from '@/src/lib/ayarlar';
import type { Database } from '@/src/lib/taban/veri-tanimlari';

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
