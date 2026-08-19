import type { Metadata } from 'next';
import { GirisFormu } from '@/src/ui/bolumler/giris-formu';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { sanitizeInternalRedirect } from '@/src/lib/guvenli-yonlendirme';

export const metadata: Metadata = {
  title: 'Giris | Yeedoy Karekod Menu',
  robots: {
    index: false,
    follow: false,
  },
  alternates: {
    canonical: '/giris',
  },
};

type LoginPageProps = {
  searchParams: Promise<{ redirect?: string; tab?: string }>;
};

export default async function LoginPage({ searchParams }: LoginPageProps) {
  const { redirect: redirectParam, tab } = await searchParams;
  // null = no explicit redirect → server will resolve by role after login
  const redirectTo = redirectParam ? getExplicitRedirect(redirectParam) : null;
  const panelLoginUrl = '/isletme-giris';

  return (
    <PublicShell footer={false}>
      <GirisFormu
        redirectTo={redirectTo}
        panelLoginUrl={panelLoginUrl}
        initialTab={tab === 'kayit' ? 'kayit' : 'giris'}
      />
    </PublicShell>
  );
}

function getExplicitRedirect(input: string): string {
  const target = normalizePanelRedirect(sanitizeInternalRedirect(input, '/'));
  if (!target || target === '/giris' || target.startsWith('/giris?')) {
    return '/';
  }
  return target;
}

function normalizePanelRedirect(target: string) {
  const [pathWithQuery, hash = ''] = target.split('#');
  const [path, query = ''] = pathWithQuery.split('?');
  const normalizedPath = path.toLocaleLowerCase('tr-TR');
  const nextPath = normalizedPath === '/sahip' ? '/sahip/gosterge-panosu' : normalizedPath;
  return `${nextPath}${query ? `?${query}` : ''}${hash ? `#${hash}` : ''}`;
}
