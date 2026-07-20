import type { Metadata } from 'next';
import { LoginForm } from '@/src/ui/sections/login-form';
import { sanitizeInternalRedirect } from '@/src/lib/safe-redirect';
import { appConfig } from '@/src/lib/config';

export const metadata: Metadata = {
  title: 'Login | Yeedoy QR Menu',
  robots: {
    index: false,
    follow: false,
  },
  alternates: {
    canonical: '/login',
  },
};

type LoginPageProps = {
  searchParams: Promise<{ redirect?: string }>;
};

export default async function LoginPage({ searchParams }: LoginPageProps) {
  const { redirect: redirectParam } = await searchParams;
  const redirectTo = sanitizeInternalRedirect(redirectParam, '/');
  const panelBase = appConfig.panelUrl();
  const panelLoginUrl = panelBase
    ? `${panelBase.replace(/\/$/, '')}/isletme-giris?redirect=${encodeURIComponent('/sahip/isletmeler')}`
    : null;

  return (
    <main className="mx-auto flex min-h-screen w-full max-w-3xl items-center px-4 py-12 sm:px-6">
      <LoginForm redirectTo={redirectTo} panelLoginUrl={panelLoginUrl} />
    </main>
  );
}
