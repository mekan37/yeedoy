import type { Metadata } from 'next';
import Link from 'next/link';
import { headers } from 'next/headers';
import { createClient } from '@supabase/supabase-js';
import { verifyUnsubscribeToken } from '@/src/lib/email/unsubscribe-token';
import { rateLimit } from '@/src/lib/oran-siniri';
import { logger } from '@/src/lib/kayitci';
import { appConfig } from '@/src/lib/ayarlar';

export const metadata: Metadata = {
  title: 'Abonelik İptali | Yeedoy',
  robots: { index: false, follow: false },
};

// ---------------------------------------------------------------------------
// Sayfa bileşenleri
// ---------------------------------------------------------------------------

function SuccessScreen({ isMkt }: { isMkt: boolean }) {
  return (
    <main className="min-h-screen bg-bg flex items-center justify-center px-4">
      <div className="mx-auto max-w-md text-center">
        <div className="mb-6 flex items-center justify-center">
          <div className="rounded-full bg-green-100 p-4">
            <svg className="h-8 w-8 text-green-600" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
            </svg>
          </div>
        </div>
        <h1 className="mb-3 text-2xl font-[900] text-textStrong">Abonelik İptal Edildi</h1>
        <p className="mb-2 text-sm leading-relaxed text-text">
          {isMkt
            ? 'Yeedoy pazarlama e-postalarından başarıyla çıktınız.'
            : 'Bu işletmenin e-posta kampanyalarından başarıyla çıktınız.'}
        </p>
        <p className="mb-8 text-sm leading-relaxed text-muted">
          Tercihlerinizi dilediğiniz zaman{' '}
          <Link href="/bildirim-ayarlari" className="text-primary hover:underline">
            bildirim ayarlarından
          </Link>{' '}
          değiştirebilirsiniz.
        </p>
        <Link
          href="/"
          className="inline-flex items-center gap-2 rounded-2xl bg-primary px-6 py-3 text-sm font-[800] text-white hover:opacity-90"
        >
          Ana Sayfaya Dön
        </Link>
      </div>
    </main>
  );
}

function AlreadyUnsubscribedScreen({ isMkt }: { isMkt: boolean }) {
  return (
    <main className="min-h-screen bg-bg flex items-center justify-center px-4">
      <div className="mx-auto max-w-md text-center">
        <div className="mb-6 flex items-center justify-center">
          <div className="rounded-full bg-slate-100 p-4">
            <svg className="h-8 w-8 text-slate-500" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
        </div>
        <h1 className="mb-3 text-2xl font-[900] text-textStrong">Zaten Abonelikten Çıktınız</h1>
        <p className="mb-8 text-sm leading-relaxed text-muted">
          {isMkt
            ? 'Yeedoy pazarlama e-postaları zaten kapalı.'
            : 'Bu işletmenin e-posta kampanyaları zaten kapalı.'}
        </p>
        <Link
          href="/"
          className="inline-flex items-center gap-2 rounded-2xl bg-primary px-6 py-3 text-sm font-[800] text-white hover:opacity-90"
        >
          Ana Sayfaya Dön
        </Link>
      </div>
    </main>
  );
}

function ExpiredScreen() {
  return (
    <main className="min-h-screen bg-bg flex items-center justify-center px-4">
      <div className="mx-auto max-w-md text-center">
        <div className="mb-6 flex items-center justify-center">
          <div className="rounded-full bg-amber-100 p-4">
            <svg className="h-8 w-8 text-amber-600" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
        </div>
        <h1 className="mb-3 text-2xl font-[900] text-textStrong">Bağlantı Süresi Doldu</h1>
        <p className="mb-2 text-sm leading-relaxed text-text">
          Bu iptal bağlantısının geçerlilik süresi dolmuş.
        </p>
        <p className="mb-8 text-sm leading-relaxed text-muted">
          Tercihlerinizi yönetmek için giriş yaparak{' '}
          <Link href="/bildirim-ayarlari" className="text-primary hover:underline">
            bildirim ayarları
          </Link>{' '}
          sayfasını kullanabilirsiniz.
        </p>
        <Link
          href="/giris"
          className="inline-flex items-center gap-2 rounded-2xl bg-primary px-6 py-3 text-sm font-[800] text-white hover:opacity-90"
        >
          Giriş Yap
        </Link>
      </div>
    </main>
  );
}

function InvalidScreen() {
  return (
    <main className="min-h-screen bg-bg flex items-center justify-center px-4">
      <div className="mx-auto max-w-md text-center">
        <div className="mb-6 flex items-center justify-center">
          <div className="rounded-full bg-red-100 p-4">
            <svg className="h-8 w-8 text-red-600" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
            </svg>
          </div>
        </div>
        <h1 className="mb-3 text-2xl font-[900] text-textStrong">Geçersiz Bağlantı</h1>
        <p className="mb-8 text-sm leading-relaxed text-muted">
          Bu abonelik iptal bağlantısı geçerli değil. Lütfen e-postanızdaki orijinal linki
          kullanın ya da{' '}
          <Link href="/bildirim-ayarlari" className="text-primary hover:underline">
            bildirim ayarları
          </Link>{' '}
          sayfasından tercihlerinizi yönetin.
        </p>
        <Link
          href="/"
          className="inline-flex items-center gap-2 rounded-2xl bg-primary px-6 py-3 text-sm font-[800] text-white hover:opacity-90"
        >
          Ana Sayfaya Dön
        </Link>
      </div>
    </main>
  );
}

function NoSecretScreen() {
  return (
    <main className="min-h-screen bg-bg flex items-center justify-center px-4">
      <div className="mx-auto max-w-md text-center">
        <h1 className="mb-3 text-2xl font-[900] text-textStrong">Hizmet Geçici Olarak Kullanılamıyor</h1>
        <p className="mb-8 text-sm leading-relaxed text-muted">
          Abonelik iptali şu an için işlenemiyor. Lütfen daha sonra tekrar deneyin veya{' '}
          <a href="mailto:destek@yeedoy.com" className="text-primary hover:underline">
            destek@yeedoy.com
          </a>{' '}
          adresine yazın.
        </p>
      </div>
    </main>
  );
}

// ---------------------------------------------------------------------------
// Veri işleme (server component içinde çalışır)
// ---------------------------------------------------------------------------

type ProcessResult =
  | { status: 'success'; isMkt: boolean }
  | { status: 'already_unsubscribed'; isMkt: boolean }
  | { status: 'expired' }
  | { status: 'invalid' }
  | { status: 'no_secret' }
  | { status: 'rate_limited' };

async function processUnsubscribe(token: string, ip: string): Promise<ProcessResult> {
  // HMAC secret yoksa konfigürasyon hatası
  if (!process.env.UNSUBSCRIBE_HMAC_SECRET?.trim()) {
    logger.warn('abonelik-iptal: UNSUBSCRIBE_HMAC_SECRET not configured');
    return { status: 'no_secret' };
  }

  // IP bazlı rate limit: 10 istek / dakika
  const rl = rateLimit(`unsub:${ip}`, 10, 60_000);
  if (!rl.ok) {
    logger.warn('abonelik-iptal: rate limit exceeded', { ip });
    return { status: 'rate_limited' };
  }

  // Token doğrulama
  let payload;
  try {
    payload = verifyUnsubscribeToken(token);
  } catch {
    return { status: 'invalid' };
  }

  if (!payload) {
    // verifyUnsubscribeToken null döndü — expired ya da invalid
    // Süre dolumu tespiti: token parçası ayrıştırılabiliyorsa ve exp < now ise expired
    const parts = token.split('.');
    if (parts.length === 5) {
      const exp = parseInt(parts[3], 10);
      if (!isNaN(exp) && Math.floor(Date.now() / 1000) > exp) {
        return { status: 'expired' };
      }
    }
    return { status: 'invalid' };
  }

  const serviceRoleKey = appConfig.serviceRoleKey();
  if (!serviceRoleKey) {
    logger.warn('abonelik-iptal: SUPABASE_SERVICE_ROLE_KEY not configured');
    return { status: 'no_secret' };
  }

  const supabase = createClient(appConfig.supabaseUrl(), serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const isMkt = payload.type === 'mkt';

  if (isMkt) {
    // Global pazarlama izni iptali — user_profiles tablosu
    const { data: existing, error: readErr } = await supabase
      .from('user_profiles')
      .select('marketing_email_opt_in')
      .eq('user_id', payload.userId)
      .single();

    if (readErr) {
      logger.warn('abonelik-iptal: user_profiles read error', { code: readErr.code });
      return { status: 'invalid' };
    }

    // Zaten kapalıysa idempotent başarı
    if (existing && (existing as Record<string, unknown>).marketing_email_opt_in === false) {
      return { status: 'already_unsubscribed', isMkt: true };
    }

    const { error: updateErr } = await supabase
      .from('user_profiles')
      .update({
        marketing_email_opt_in: false,
        marketing_email_opted_in_at: null,
        updated_at: new Date().toISOString(),
      } as Record<string, unknown>)
      .eq('user_id', payload.userId);

    if (updateErr) {
      logger.warn('abonelik-iptal: user_profiles update error', { code: updateErr.code });
      return { status: 'invalid' };
    }

    logger.info('abonelik-iptal: global marketing opt-out successful', { userId: payload.userId });
    return { status: 'success', isMkt: true };

  } else {
    // İşletme bazlı abonelik iptali — business_follows tablosu
    const businessId = payload.businessId!;

    const { data: existing, error: readErr } = await supabase
      .from('business_follows')
      .select('is_subscribed_email')
      .eq('user_id', payload.userId)
      .eq('business_id', businessId)
      .single();

    if (readErr && readErr.code !== 'PGRST116') {
      // PGRST116 = row not found (takip yok) — this is "already done" or invalid state
      logger.warn('abonelik-iptal: business_follows read error', { code: readErr.code });
      return { status: 'invalid' };
    }

    if (!existing) {
      // Takip kaydı yok — zaten abonelik yok
      return { status: 'already_unsubscribed', isMkt: false };
    }

    if ((existing as Record<string, unknown>).is_subscribed_email === false) {
      return { status: 'already_unsubscribed', isMkt: false };
    }

    const { error: updateErr } = await supabase
      .from('business_follows')
      .update({ is_subscribed_email: false } as Record<string, unknown>)
      .eq('user_id', payload.userId)
      .eq('business_id', businessId);

    if (updateErr) {
      logger.warn('abonelik-iptal: business_follows update error', { code: updateErr.code });
      return { status: 'invalid' };
    }

    logger.info('abonelik-iptal: business subscription opt-out successful', {
      userId: payload.userId,
    });
    return { status: 'success', isMkt: false };
  }
}

// ---------------------------------------------------------------------------
// Sayfa giriş noktası
// ---------------------------------------------------------------------------

export default async function AbonelikIptalPage({
  searchParams,
}: {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const resolvedParams = await searchParams;
  const token = typeof resolvedParams.token === 'string' ? resolvedParams.token : null;

  if (!token) {
    return <InvalidScreen />;
  }

  // IP tespiti (Next.js headers API)
  const headersList = await headers();
  const ip =
    headersList.get('x-forwarded-for')?.split(',')[0]?.trim() ||
    headersList.get('x-real-ip')?.trim() ||
    'unknown';

  const result = await processUnsubscribe(token, ip);

  switch (result.status) {
    case 'success':
      return <SuccessScreen isMkt={result.isMkt} />;
    case 'already_unsubscribed':
      return <AlreadyUnsubscribedScreen isMkt={result.isMkt} />;
    case 'expired':
      return <ExpiredScreen />;
    case 'no_secret':
      return <NoSecretScreen />;
    case 'rate_limited':
      return <InvalidScreen />;
    case 'invalid':
    default:
      return <InvalidScreen />;
  }
}
