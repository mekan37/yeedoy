import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { OturumKapatButonu } from './oturum-kapat';
import { IkiFactorAyar } from './iki-faktor-ayar';

export const metadata: Metadata = { title: 'Hesap Güvenliği | Yeedoy', robots: { index: false, follow: false } };

export default async function SecurityPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  const { data: { session } } = await supabase.auth.getSession();

  // Check existing MFA factors
  let mfaEnabled = false;
  let mfaFactorId: string | null = null;
  try {
    const { data: mfaData } = await supabase.auth.mfa.listFactors();
    const totpFactor = mfaData?.totp?.find((f) => f.status === 'verified');
    if (totpFactor) {
      mfaEnabled = true;
      mfaFactorId = totpFactor.id;
    }
  } catch {}


  const email = user?.email ?? '';
  const provider = user?.app_metadata?.provider ?? 'email';
  const lastSignIn = user?.last_sign_in_at ? new Date(user.last_sign_in_at).toLocaleString('tr-TR') : null;
  const createdAt = user?.created_at ? new Date(user.created_at).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' }) : null;
  const accessToken = session?.access_token ?? null;

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-lg px-4 py-12">
        <Link href="/profil/settings" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary">← Ayarlara Dön</Link>
        <h1 className="mb-8 text-2xl font-[900] text-textStrong">Hesap Güvenliği</h1>

        <div className="flex flex-col gap-4">
          {/* Account info */}
          <div className="rounded-2xl border border-border bg-card p-6">
            <h2 className="mb-4 text-base font-[900] text-textStrong">Hesap Bilgileri</h2>
            <div className="flex flex-col gap-2 text-sm">
              <div className="flex justify-between">
                <span className="text-muted">E-posta</span>
                <span className="font-[700] text-textStrong">{email}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted">Giriş yöntemi</span>
                <span className="font-[700] text-textStrong capitalize">{provider === 'email' ? 'E-posta' : provider}</span>
              </div>
              {lastSignIn && (
                <div className="flex justify-between">
                  <span className="text-muted">Son giriş</span>
                  <span className="font-[700] text-textStrong">{lastSignIn}</span>
                </div>
              )}
              {createdAt && (
                <div className="flex justify-between">
                  <span className="text-muted">Üyelik tarihi</span>
                  <span className="font-[700] text-textStrong">{createdAt}</span>
                </div>
              )}
            </div>
          </div>

          {/* Password */}
          <div className="rounded-2xl border border-border bg-card p-6">
            <h2 className="mb-1 font-[900] text-textStrong">Şifre Değiştir</h2>
            <p className="mb-4 text-sm text-muted">E-posta adresinize şifre sıfırlama bağlantısı gönderilir.</p>
            <Link
              href="/sifremi-unuttum"
              className="inline-flex min-h-[40px] items-center rounded-xl border border-border bg-bg px-4 text-sm font-[700] text-textStrong hover:border-primary/30"
            >
              Şifre Sıfırlama E-postası Gönder
            </Link>
          </div>

          {/* Active session */}
          <div className="rounded-2xl border border-border bg-card p-6">
            <h2 className="mb-1 font-[900] text-textStrong">Aktif Oturum</h2>
            <p className="mb-4 text-sm text-muted">Şu anda bu cihazda oturum açık.</p>
            <div className="mb-4 flex items-center gap-3 rounded-xl border border-border bg-bg px-4 py-3">
              <div className="h-2.5 w-2.5 shrink-0 rounded-full bg-success" />
              <div className="min-w-0">
                <p className="text-sm font-[700] text-textStrong">Bu cihaz</p>
                {lastSignIn && <p className="text-xs text-muted">Giriş: {lastSignIn}</p>}
              </div>
              {accessToken && (
                <span className="ml-auto rounded-full bg-success/10 px-2 py-0.5 text-[10px] font-[900] text-success">Aktif</span>
              )}
            </div>
            {accessToken && (
              <OturumKapatButonu />
            )}
          </div>

          {/* C-6: 2FA TOTP */}
          <div className="rounded-2xl border border-border bg-card p-6">
            <h2 className="mb-1 font-[900] text-textStrong">İki Faktörlü Doğrulama (2FA)</h2>
            <p className="mb-4 text-sm text-muted">
              Google Authenticator veya Authy gibi bir uygulama ile hesabınızı ekstra güvenlik katmanıyla koruyun.
            </p>
            <IkiFactorAyar isEnabled={mfaEnabled} factorId={mfaFactorId} />
          </div>

          {/* Danger zone */}
          <div className="rounded-2xl border border-danger/20 bg-danger/[0.04] p-6">
            <h2 className="mb-1 font-[900] text-danger">Tehlikeli Bölge</h2>
            <p className="mb-4 text-sm text-muted">Bu işlemler geri alınamaz.</p>
            <Link
              href="/profil/settings"
              className="inline-flex min-h-[40px] items-center rounded-xl border border-danger/30 bg-card px-4 text-sm font-[700] text-danger hover:bg-danger/[0.08]"
            >
              Hesabı Sil
            </Link>
          </div>
        </div>
      </div>
    </main>
  );
}
