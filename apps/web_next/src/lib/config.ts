function requireEnv(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export const appConfig = {
  supabaseUrl: () => requireEnv('NEXT_PUBLIC_SUPABASE_URL'),
  supabaseAnonKey: () => requireEnv('NEXT_PUBLIC_SUPABASE_ANON_KEY'),
  siteUrl: () => process.env.NEXT_PUBLIC_SITE_URL?.trim() || 'http://localhost:3000',
  panelUrl: () => process.env.NEXT_PUBLIC_PANEL_URL?.trim() || null,
  serviceRoleKey: () => process.env.SUPABASE_SERVICE_ROLE_KEY?.trim() || null,
};
