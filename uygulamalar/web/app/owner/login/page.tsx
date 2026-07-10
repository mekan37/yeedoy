import type { Metadata } from 'next';
import { sanitizeInternalRedirect } from '@/src/lib/safe-redirect';
import { OwnerLoginPage } from '@/src/ui/owner/owner-login-form';

export const metadata: Metadata = {
  title: 'İşletme Paneline Giriş | Yeedoy',
  robots: { index: false, follow: false },
};

type Props = {
  searchParams: Promise<{ redirect?: string }>;
};

export default async function OwnerLoginPageRoute({ searchParams }: Props) {
  const { redirect: redirectParam } = await searchParams;
  const redirectTo = sanitizeInternalRedirect(redirectParam, '/owner/dashboard');

  return <OwnerLoginPage redirectTo={redirectTo} />;
}
