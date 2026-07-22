function requireEnv(name: string, value: string | undefined): string {
  const normalized = value?.trim();
  if (!normalized) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return normalized;
}

export const appConfig = {
  supabaseUrl: () => requireEnv('NEXT_PUBLIC_SUPABASE_URL', process.env.NEXT_PUBLIC_SUPABASE_URL),
  supabaseAnonKey: () => requireEnv('NEXT_PUBLIC_SUPABASE_ANON_KEY', process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY),
  siteUrl: () => process.env.NEXT_PUBLIC_SITE_URL?.trim() || 'http://localhost:3000',
  panelUrl: () => process.env.NEXT_PUBLIC_PANEL_URL?.trim() || null,
  serviceRoleKey: () => process.env.SUPABASE_SERVICE_ROLE_KEY?.trim() || null,
  revalidateSecret: () => process.env.REVALIDATE_SECRET?.trim() || null,
  emailFrom: () => process.env.EMAIL_FROM?.trim() || 'Yeedoy <bildirim@yeedoy.com>',
  resendApiKey: () => process.env.RESEND_API_KEY?.trim() || null,
};
