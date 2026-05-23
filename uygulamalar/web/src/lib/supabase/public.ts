import { createClient } from '@supabase/supabase-js';
import { appConfig } from '@/src/lib/config';
import type { Database } from '@/src/lib/supabase/database.types';

export function createSupabasePublicClient() {
  return createClient<Database>(appConfig.supabaseUrl(), appConfig.supabaseAnonKey(), {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}
