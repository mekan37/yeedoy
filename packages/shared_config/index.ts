export type SharedEnv = {
  SUPABASE_URL: string;
  SUPABASE_ANON_KEY: string;
  SUPABASE_SERVICE_ROLE_KEY?: string;
  STORAGE_BUCKET_PUBLIC: string;
  BASE_URL_WEB_NEXT: string;
  BASE_URL_PANEL: string;
  DEV_TOOLS_ENABLED: string;
};

const REQUIRED_KEYS: Array<keyof SharedEnv> = [
  'SUPABASE_URL',
  'SUPABASE_ANON_KEY',
  'STORAGE_BUCKET_PUBLIC',
  'BASE_URL_WEB_NEXT',
  'BASE_URL_PANEL',
  'DEV_TOOLS_ENABLED',
];

export function validateSharedEnv(
  env: Partial<Record<keyof SharedEnv, string | undefined>>,
) {
  const missing = REQUIRED_KEYS.filter((key) => !(env[key] ?? '').trim());
  return {
    ok: missing.length === 0,
    missing,
  };
}
