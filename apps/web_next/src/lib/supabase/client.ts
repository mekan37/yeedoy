import { createBrowserClient } from '@supabase/ssr';
import { appConfig } from '@/src/lib/config';
import type { Database } from '@/src/lib/supabase/database.types';

export function createSupabaseBrowserClient() {
  return createBrowserClient<Database>(
    appConfig.supabaseUrl(),
    appConfig.supabaseAnonKey(),
  );
}
